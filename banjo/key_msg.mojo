from collections import InlineArray
from sys import stdin
from sys.ffi import c_int, c_size_t, external_call

import mist.termios.c
from banjo.key import SEQUENCES, Key, KeyType
from banjo.msg import BlurMsg, FocusMsg, Msg, NoMsg, UnknownInputByteMsg


@fieldwise_init
struct KeyMsg(Copyable, Movable, Stringable, Writable):
    """Contains information about a keypress. KeyMsgs are always sent to
    the program's update function. There are a couple general patterns you could
    use to check for keypresses.

    Note that `Key.text` will always contain at least one character, so you can
    always safely call `Key.text[0]`. In most cases `Key.text` will only contain
    one character, though certain input method editors (most notably Chinese
    IMEs) can input multiple runes at once."""

    var key: Key
    """The key that was pressed."""

    fn write_to[W: Writer, //](self, mut writer: W):
        """Formats the string representation of this type to the provided formatter.

        Parameters:
            W: The formatter to write to.

        Args:
            writer: The formatter to write to.
        """
        writer.write(self.key)

    fn __str__(self) -> String:
        """Returns a string representation of the KeyMsg.

        Returns:
            A string representation of the KeyMsg.
        """
        return String.write(self)

    fn __eq__(self, other: Self) -> Bool:
        """Checks if this KeyMsg is equal to another KeyMsg.

        Args:
            other: The KeyMsg to compare with.

        Returns:
            True if the KeyMsg is equal to the other, False otherwise.
        """
        return self.key == other.key

    fn __eq__(self, type: KeyType) -> Bool:
        """Checks if the KeyMsg's key type is equal to a given KeyType.

        Args:
            type: The KeyType to compare with.

        Returns:
            True if the KeyMsg's key type is equal to the given KeyType, False otherwise.
        """
        return self.key.type == type

    fn __ne__(self, other: Self) -> Bool:
        """Checks if this KeyMsg is not equal to another KeyMsg.

        Args:
            other: The KeyMsg to compare with.

        Returns:
            True if the KeyMsg is not equal to the other, False otherwise.
        """
        return self.key != other.key

    fn __ne__(self, type: KeyType) -> Bool:
        """Checks if the KeyMsg's key type is not equal to a given KeyType.

        Args:
            type: The KeyType to compare with.

        Returns:
            True if the KeyMsg's key type is not equal to the given KeyType, False otherwise.
        """
        return self.key.type != type


fn bytes_equal(lhs: Span[Byte], rhs: Span[Byte]) -> Bool:
    """Checks if two byte spans are equal.

    Args:
        lhs: The first byte span to compare.
        rhs: The second byte span to compare.

    Returns:
        True if the byte spans are equal, False otherwise.
    """
    if len(lhs) != len(rhs):
        return False
    for i in range(len(lhs)):
        if lhs[i] != rhs[i]:
            return False
    return True


fn detect_report_focus[origin: ImmutOrigin](input: Span[Byte, origin]) -> Tuple[Bool, Int, Msg]:
    """Detects focus and blur events in the input buffer.

    Parameters:
        origin: The origin of the input buffer, must be immutable.

    Args:
        input: The input buffer to detect focus and blur events in.

    Returns:
        A tuple containing a boolean indicating whether a focus or blur event
        was detected, the length of the input consumed, and a Msg containing
        the detected event. If no focus or blur event was detected, the boolean
        will be False, the length will be 0, and the Msg will be a `NoMsg`.
    """
    if bytes_equal(input, "\x1b[I".as_bytes()):
        return True, 3, Msg(FocusMsg())
    elif bytes_equal(input, "\x1b[O".as_bytes()):
        return True, 3, Msg(BlurMsg())
    return False, 0, Msg(NoMsg())


fn detect_bracketed_paste[origin: ImmutOrigin](input: Span[Byte, origin]) -> Tuple[Bool, Int, Msg]:
    """Detects an input pasted while bracketed
    paste mode was enabled.

    Note: this function is a no-op if bracketed paste was not enabled
    on the terminal, since in that case we'd never see this
    particular escape sequence.

    Parameters:
        origin: The origin of the input buffer, must be immutable.

    Args:
        input: The input buffer to detect bracketed paste in.

    Returns:
        A tuple containing a boolean indicating whether a bracketed paste
        was detected, the length of the input consumed, and a Msg containing
        the detected paste. If no bracketed paste was detected, the boolean
        will be False, the length will be 0, and the Msg will be a `NoMsg`.
    """

    # Detect the start sequence.
    comptime bp_start = "\x1b[200~"
    comptime bp_start_length = len(bp_start)

    # If the input is shorter than the start sequence, or if the
    # start sequence is not at the beginning of the input, then
    # we don't have a bracketed paste.
    if len(input) < bp_start_length or not bytes_equal(input[:bp_start_length], bp_start.as_bytes()):
        return False, 0, Msg(NoMsg())

    # Skip over the start sequence.
    var remaining_input = input[bp_start_length:]

    # If we saw the start sequence, then we must have an end sequence
    # as well. Find it.
    comptime bp_end = "\x1b[201~"
    var idx = StringSlice(unsafe_from_utf8=remaining_input).find(bp_end)
    if idx == -1:
        # We have encountered the end of the input buffer without seeing
        # the marker for the end of the bracketed paste.
        # Tell the outer loop we have done a short read and we want more.
        return True, 0, Msg(NoMsg())

    # The paste is everything in-between.
    var paste = remaining_input[:idx]

    # All there is in-between is runes, not to be interpreted further.
    var k = Key(type=KeyType.Runes, text=String(StringSlice(unsafe_from_utf8=paste)), paste=True)
    # while len(paste) > 0:
    # 	r, w = utf8.DecodeRune(paste)
    # 	if r != utf8.RuneError:
    # 		k.Runes = append(k.Runes, r)

    # 	paste = paste[w:]

    var input_len = bp_start_length + idx + len(bp_end)
    return True, input_len, Msg(KeyMsg(k^))


fn build_escape_sequences() -> Dict[String, Key]:
    """Builds a dictionary of escape sequences and their corresponding Key objects.

    The dictionary maps escape sequences (as strings) to Key objects, which
    represent the key type and any additional properties such as alt or text.

    Returns:
        A dictionary mapping escape sequences to Key objects.
    """
    var s = Dict[String, Key]()
    for pair in materialize[SEQUENCES]().items():
        var key = pair.value.copy()
        s[pair.key] = key.copy()
        if not key.alt:
            key.alt = True
            s["\x1b" + pair.key] = key^

    # start at KeyType.NUL.value + 1 (1) to skip NUL
    var i = KeyType.NUL.value + 1
    while i <= KeyType.DEL.value:
        if i == KeyType.ESC.value:
            i += 1
            continue

        var a = String()
        a.write_bytes(List[Byte](i))
        s[a] = Key(type=i)
        var b = String()
        b.write_bytes(List[Byte](ord("\x1b"), i))
        s[b] = Key(type=i, alt=True)
        if i == KeyType.US.value:
            i = KeyType.DEL.value - 1

        i += 1

    s[" "] = Key(type=KeyType.Space, text=" ")
    s["\x1b "] = Key(type=KeyType.Space, alt=True, text=" ")
    s["\x1b\x1b"] = Key(type=KeyType.Space, alt=True)
    return s^


comptime ESCAPE_SEQUENCES = build_escape_sequences()


fn build_sequence_lengths() -> List[Int]:
    """Builds a list of the lengths of the escape sequences in
    ESCAPE_SEQUENCES. This is used to speed up the detection of
    escape sequences. The lengths are sorted in descending order,
    so that we can do a longest prefix match over the input
    sequence.

    Returns:
        A list of the lengths of the escape sequences in
        ESCAPE_SEQUENCES, sorted in descending order.
    """
    comptime ext_length = len(ESCAPE_SEQUENCES)
    var sizes = List[Int](capacity=ext_length)
    for ref seq in materialize[ESCAPE_SEQUENCES]().keys():
        sizes.append(len(seq))

    var lsize = List[Int](length=len(sizes), fill=0)
    for size in sizes:
        lsize.append(size)

    sort(lsize)
    lsize.reverse()
    return lsize^


comptime SEQUENCE_LENGTHS = build_sequence_lengths()


# detect_sequence uses a longest prefix match over the input
# sequence and a hash map.
fn detect_sequence[origin: ImmutOrigin](input: Span[Byte, origin]) -> Tuple[Bool, Int, Msg]:
    """Detects an escape sequence in the input buffer.

    Uses a longest prefix match over the input sequence
    and a hash map to speed up the detection of escape
    sequences.

    Parameters:
        origin: The origin of the input buffer, must be immutable.

    Args:
        input: The input buffer to detect escape sequences in.

    Returns:
        A tuple containing a boolean indicating whether an escape
        sequence was found, the length of the escape sequence, and
        a Msg containing the escape sequence. If no escape sequence
        was found, the length will be 0 and the Msg will be a `NoMsg`.
    """
    for size in materialize[SEQUENCE_LENGTHS]():
        if size > len(input):
            continue

        var prefix = input[:size]
        try:
            key = materialize[ESCAPE_SEQUENCES]()[String(bytes=prefix)].copy()
            return True, size, Msg(KeyMsg(key^))
        except:
            continue

    # TODO: Implement this.
    # Is this an unknown CSI sequence?
    # var loc = unknown_csi_re.FindIndex(input)
    # if loc != None:
    #     return True, loc[1], Msg(UnknownCSISequenceMsg(input[:loc[1]]))

    return False, 0, Msg(NoMsg())


fn detect_msg[origin: ImmutOrigin](buf: Span[Byte, origin]) -> Tuple[Int, Msg]:
    """Detects a message in the input buffer.

    This function detects various types of messages, such as key presses,
    escape sequences, focus and blur events, and bracketed paste events.

    Parameters:
        origin: The origin of the input buffer, must be immutable.

    Args:
        buf: The input buffer to detect messages in.

    Returns:
        A tuple containing the length of the detected message and a Msg
        containing the detected message. If no message was detected, the length
        will be 0 and the Msg will be a `NoMsg`.
    """
    # Detect mouse events.
    # X10 mouse events have a length of 6 bytes
    # comptime mouseEventX10Len = 6
    # if len(b) >= mouseEventX10Len and b[0] == '\x1b' and b[1] == '[':
    # 	switch b[2]:
    # 	case 'M':
    # 		return mouseEventX10Len, MouseMsg(parseX10MouseEvent(b))
    # 	case '<':
    # 		if matchIndices = mouseSGRRegex.FindSubmatchIndex(b[3:]); matchIndices != None:
    # 			# SGR mouse events length is the length of the match plus the length of the escape sequence
    # 			mouseEventSGRLen = matchIndices[1] + 3 //nolint:mnd
    # 			return mouseEventSGRLen, MouseMsg(parseSGRMouseEvent(b))
    #
    #
    #

    # Detect focus events.
    found_rf, w, msg = detect_report_focus(buf)
    if found_rf:
        return w, msg^

    # Detect bracketed paste.
    found_bp, w, msg = detect_bracketed_paste(buf)
    if found_bp:
        return w, msg^

    # Detect escape sequence and control characters other than NUL,
    # possibly with an escape character in front to mark the Alt
    # modifier.
    found_seq, w, msg = detect_sequence(buf)
    if found_seq:
        return w, msg^

    # No non-NUL control character or escape sequence.
    # If we are seeing at least an escape character, remember it for later below.
    var alt = False
    var i = 0
    if buf[0] == ord("\x1b"):
        alt = True
        i += 2

    # Are we seeing a standalone NUL? This is not handled by detect_sequence().
    if i < len(buf) and buf[i] == 0:
        return i + 1, Msg(KeyMsg(Key(type=KeyType.NUL, alt=alt)))

    # Find the longest sequence of runes that are not control
    # characters from this point.
    # while i < len(buf):
    var remainder = buf[i:]
    var text_start = i
    for char in StringSlice(unsafe_from_utf8=remainder).codepoints():
        if char.to_u32() <= KeyType.US.value or char.to_u32() == KeyType.DEL.value or char.to_u32() == ord(" "):
            # Rune errors are handled below; control characters and spaces will
            # be handled by detect_sequence in the next call to detectOneMsg.
            break

        if alt:
            # We only support a single rune after an escape alt modifier.
            i += char.utf8_byte_length()
            break

        i += char.utf8_byte_length()
    # for char in StringSlice(unsafe_from_utf8=buf).chars():
    #     if char.to_u32() <= KeyType.US.value or char.to_u32() == KeyType.DEL.value or char.to_u32() == ord(' '):
    #         # Rune errors are handled below; control characters and spaces will
    #         # be handled by detect_sequence in the next call to detectOneMsg.
    #         break

    #     if alt:
    #         # We only support a single rune after an escape alt modifier.
    #         i += char.utf8_byte_length()
    #         break

    # if i >= len(buf) and can_have_more_data:
    #     # We have encountered the end of the input buffer. Alas, we can't
    #     # be sure whether the data in the remainder of the buffer is
    #     # complete (maybe there was a short read). Instead of sending anything
    #     # dumb to the message channel, do a short read. The outer loop will
    #     # handle this case by extending the buffer as necessary.
    #     return 0, Msg(NoMsg())

    # If we found at least one rune, we report the bunch of them as
    # a single KeyRunes or KeySpace event.
    if text_start < i:
        var k = Key(type=KeyType.Runes, text=String(StringSlice(unsafe_from_utf8=buf[text_start:i])), alt=alt)
        if len(buf[text_start:i]) == 1 and k.text[0] == " ":
            k.type = KeyType.Space

        return i, Msg(KeyMsg(k^))

    # We didn't find an escape sequence, nor a valid rune. Was this a
    # lone escape character at the end of the input?
    if alt and len(buf) == 1:
        return 1, Msg(KeyMsg(Key(type=KeyType.Escape)))

    # The character at the current position is neither an escape
    # sequence, a valid rune start or a sole escape character. Report
    # it as an invalid byte.
    return 1, Msg(UnknownInputByteMsg(buf[0]))


fn read(fd: c_int, buf: MutUnsafePointer[NoneType], size: c_size_t) -> c_int:
    """Libc POSIX `read` function.

    Read `size` bytes from file descriptor `fd` into the buffer `buf`.

    Args:
        fd: A File Descriptor.
        buf: A pointer to a buffer to store the read data.
        size: The number of bytes to read.

    Returns:
        The number of bytes read or -1 in case of failure.

    #### C Function:
    ```c
    ssize_t read(int fildes, void *buf, size_t nbyte);
    ```

    #### Notes:
    Reference: https://man7.org/linux/man-pages/man3/read.3p.html.
    """
    return external_call["read", c_int, type_of(fd), type_of(buf), type_of(size)](fd, buf, size)


fn read_events() -> Msg:
    """Reads a single event from stdin. Read is normally blocking, but the terminal
    is set to non-blocking mode, so this will return immediately if there is no
    data to read. If there is no data to read, this will return a NoMsg message.

    Returns:
        A Msg containing the event read from stdin. This will be a KeyMsg if
        a key was pressed, or a NoMsg if there was no data to read.
    """
    comptime COUNT_TO_READ = 32

    # We use a stack allocation to avoid heap allocations.
    # We don't need to free stack allocated pointers, I guess?
    # Freeing it works when its a heap allocated pointer, but not stack allocated.
    var buffer = InlineArray[Byte, COUNT_TO_READ](uninitialized=True)
    _ = read(stdin.value, buffer.unsafe_ptr().bitcast[NoneType](), COUNT_TO_READ)
    _, msg = detect_msg(Span(buffer).get_immutable())
    return msg^
