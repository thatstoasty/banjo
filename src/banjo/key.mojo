from collections import Dict, Optional
from collections.string import StringSlice
from memory import Span
from banjo.termios import read, STDIN
from banjo.msg import Msg, FocusMsg, BlurMsg, UnknownInputByteMsg, NoMsg
from sys.ffi import os_is_windows


@value
struct KeyMsg(CollectionElement, ExplicitlyCopyable, Stringable, Writable):
    """Contains information about a keypress. KeyMsgs are always sent to
    the program's update function. There are a couple general patterns you could
    use to check for keypresses.

    Note that `Key.text` will always contain at least one character, so you can
    always safely call `Key.text[0]`. In most cases `Key.text` will only contain
    one character, though certain input method editors (most notably Chinese
    IMEs) can input multiple runes at once."""

    var key: Key

    fn write_to[W: Writer, //](self, mut writer: W):
        """Formats the string representation of this type to the provided formatter.

        Args:
            writer: The formatter to write to.
        """
        writer.write(self.key)

    fn __str__(self) -> String:
        return String.write(self)

    fn __eq__(self, other: Self) -> Bool:
        return self.key == other.key

    fn __eq__(self, type: KeyType) -> Bool:
        return self.key.type == type

    fn __ne__(self, other: Self) -> Bool:
        return self.key != other.key

    fn __ne__(self, type: KeyType) -> Bool:
        return self.key.type != type


@value
@register_passable("trivial")
struct KeyType(CollectionElement, Stringable, KeyElement):
    """Indicates the key pressed, such as `KeyEnter` or `KeyBreak` or `KeyCtrlC`.
    All other keys will be type `KeyRunes`. To get the rune value, check the Rune
    method on a `Key` struct, or use the `String(Key)` method.

    ```mojo
    from banjo.key import Key, KeyType

    var k = Key(KeyType.Runes, text='a', alt=True)
    if k.type == KeyType.Runes:
        print(k.text)
        # Output: a

        print(String(k))
        # Output: alt+a
    ```
    """

    var value: Int
    alias NUL: KeyType = 0
    """null, \\0"""
    alias SOH: KeyType = 1
    """start of heading."""
    alias STX: KeyType = 2
    """start of text."""
    alias ETX: KeyType = 3
    """break, ctrl+c."""
    alias EOT: KeyType = 4
    """end of transmission."""
    alias ENQ: KeyType = 5
    """enquiry."""
    alias ACK: KeyType = 6
    """acknowledge."""
    alias BEL: KeyType = 7
    """bell, \\a"""
    alias BS: KeyType = 8
    """backspace."""
    alias HT: KeyType = 9
    """horizontal tabulation, \\t."""
    alias LF: KeyType = 10
    """line feed, \\n."""
    alias VT: KeyType = 11
    """vertical tabulation, \\v."""
    alias FF: KeyType = 12
    """form feed, \\f."""
    alias CR: KeyType = 13
    """carriage return, \\r."""
    alias SO: KeyType = 14
    """shift out."""
    alias SI: KeyType = 15
    """shift in."""
    alias DLE: KeyType = 16
    """data link escape."""
    alias DC1: KeyType = 17
    """device control one."""
    alias DC2: KeyType = 18
    """device control two."""
    alias DC3: KeyType = 19
    """device control three."""
    alias DC4: KeyType = 20
    """device control four."""
    alias NAK: KeyType = 21
    """negative acknowledge."""
    alias SYN: KeyType = 22
    """synchronous idle."""
    alias ETB: KeyType = 23
    """end of transmission block."""
    alias CAN: KeyType = 24
    """cancel."""
    alias EM: KeyType = 25
    """end of medium."""
    alias SUB: KeyType = 26
    """substitution."""
    alias ESC: KeyType = 27
    """escape, \\e."""
    alias FS: KeyType = 28
    """file separator."""
    alias GS: KeyType = 29
    """group separator."""
    alias RS: KeyType = 30
    """record separator."""
    alias US: KeyType = 31
    """unit separator."""
    alias DEL: KeyType = 127
    """delete. on most systems this is mapped to backspace, I hear."""

    # Control key aliases.
    alias Null: KeyType = Self.NUL
    alias Break: KeyType = Self.ETX
    alias Enter: KeyType = Self.CR if os_is_windows() else Self.LF
    alias Backspace: KeyType = Self.DEL
    alias Tab: KeyType = Self.HT
    alias Esc: KeyType = Self.ESC
    alias Escape: KeyType = Self.ESC
    alias CtrlAt: KeyType = Self.NUL  # ctrl+@
    alias CtrlA: KeyType = Self.SOH
    alias CtrlB: KeyType = Self.STX
    alias CtrlC: KeyType = Self.ETX
    alias CtrlD: KeyType = Self.EOT
    alias CtrlE: KeyType = Self.ENQ
    alias CtrlF: KeyType = Self.ACK
    alias CtrlG: KeyType = Self.BEL
    alias CtrlH: KeyType = Self.BS
    alias CtrlI: KeyType = Self.HT
    alias CtrlJ: KeyType = Self.LF
    alias CtrlK: KeyType = Self.VT
    alias CtrlL: KeyType = Self.FF
    alias CtrlM: KeyType = Self.CR
    alias CtrlN: KeyType = Self.SO
    alias CtrlO: KeyType = Self.SI
    alias CtrlP: KeyType = Self.DLE
    alias CtrlQ: KeyType = Self.DC1
    alias CtrlR: KeyType = Self.DC2
    alias CtrlS: KeyType = Self.DC3
    alias CtrlT: KeyType = Self.DC4
    alias CtrlU: KeyType = Self.NAK
    alias CtrlV: KeyType = Self.SYN
    alias CtrlW: KeyType = Self.ETB
    alias CtrlX: KeyType = Self.CAN
    alias CtrlY: KeyType = Self.EM
    alias CtrlZ: KeyType = Self.SUB
    alias CtrlOpenBracket: KeyType = Self.ESC  # ctrl+[
    alias CtrlBackslash: KeyType = Self.FS  # ctrl+\
    alias CtrlCloseBracket: KeyType = Self.GS  # ctrl+]
    alias CtrlCaret: KeyType = Self.RS  # ctrl+^
    alias CtrlUnderscore: KeyType = Self.US  # ctrl+_
    alias CtrlQuestionMark: KeyType = Self.DEL  # ctrl+?

    # Other keys.
    alias Runes: KeyType = -1
    alias Up: KeyType = -2
    alias Down: KeyType = -3
    alias Right: KeyType = -4
    alias Left: KeyType = -5
    alias ShiftTab: KeyType = -6
    alias Home: KeyType = -7
    alias End: KeyType = -8
    alias PgUp: KeyType = -9
    alias PgDown: KeyType = -10
    alias CtrlPgUp: KeyType = -11
    alias CtrlPgDown: KeyType = -12
    alias Delete: KeyType = -13
    alias Insert: KeyType = -14
    alias Space: KeyType = -15
    alias CtrlUp: KeyType = -16
    alias CtrlDown: KeyType = -17
    alias CtrlRight: KeyType = -18
    alias CtrlLeft: KeyType = -19
    alias CtrlHome: KeyType = -20
    alias CtrlEnd: KeyType = -21
    alias ShiftUp: KeyType = -22
    alias ShiftDown: KeyType = -23
    alias ShiftRight: KeyType = -24
    alias ShiftLeft: KeyType = -25
    alias ShiftHome: KeyType = -26
    alias ShiftEnd: KeyType = -27
    alias CtrlShiftUp: KeyType = -28
    alias CtrlShiftDown: KeyType = -29
    alias CtrlShiftLeft: KeyType = -30
    alias CtrlShiftRight: KeyType = -31
    alias CtrlShiftHome: KeyType = -32
    alias CtrlShiftEnd: KeyType = -33
    alias F1: KeyType = -34
    alias F2: KeyType = -35
    alias F3: KeyType = -36
    alias F4: KeyType = -37
    alias F5: KeyType = -38
    alias F6: KeyType = -39
    alias F7: KeyType = -40
    alias F8: KeyType = -41
    alias F9: KeyType = -42
    alias F10: KeyType = -43
    alias F11: KeyType = -44
    alias F12: KeyType = -45
    alias F13: KeyType = -46
    alias F14: KeyType = -47
    alias F15: KeyType = -48
    alias F16: KeyType = -49
    alias F17: KeyType = -50
    alias F18: KeyType = -51
    alias F19: KeyType = -52
    alias F20: KeyType = -53

    @implicit
    fn __init__(out self, value: Int):
        self.value = value

    fn __str__(self) -> String:
        return KEY_NAMES.get(self.value, "")

    fn __eq__(self, other: KeyType) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: KeyType) -> Bool:
        return self.value != other.value

    fn __hash__(self) -> UInt:
        return hash(self.value)

    fn write_to[W: Writer, //](self, mut writer: W):
        """Formats the string representation of this type to the provided formatter.

        Args:
            writer: The formatter to write to.
        """
        writer.write("KeyType(value=", self.value, ")")


@value
struct Key(CollectionElement, ExplicitlyCopyable, Stringable, Writable):
    """Key contains information about a keypress."""

    var type: KeyType
    """The type of key pressed."""
    var text: String
    """The raw text of the key pressed."""
    var alt: Bool
    """Whether the alt key was pressed."""
    var paste: Bool
    """Whether the paste key was pressed."""

    fn __init__(out self, type: KeyType, *, text: String = "", alt: Bool = False, paste: Bool = False):
        self.type = type
        self.text = text
        self.alt = alt
        self.paste = paste

    fn __eq__(self, other: Self) -> Bool:
        return (
            self.type == other.type and self.text == other.text and self.alt == other.alt and self.paste == other.paste
        )

    fn __ne__(self, other: Self) -> Bool:
        return self.type != other.type or self.text != other.text or self.alt != other.alt or self.paste != other.paste

    fn write_to[W: Writer, //](self, mut writer: W):
        """Formats the string representation of this type to the provided formatter.

        Args:
            writer: The formatter to write to.
        """
        if self.type == KeyType.Runes:
            if self.alt:
                writer.write("alt+")
            if self.paste:
                writer.write("[")
            writer.write(self.text)
            if self.paste:
                writer.write("]")
            return

        var key_name = KEY_NAMES.get(self.type)
        if key_name:
            writer.write(key_name.value())
            return

        var sequence = SEQUENCES.get(self.text)
        if sequence:
            writer.write(KEY_NAMES.get(sequence.value().type, ""))
            return

    fn __str__(self) -> String:
        return String.write(self)


fn bytes_equal(lhs: Span[Byte], rhs: Span[Byte]) -> Bool:
    if len(lhs) != len(rhs):
        return False
    for i in range(len(lhs)):
        if lhs[i] != rhs[i]:
            return False
    return True


fn detect_report_focus(input: Span[Byte]) -> (Bool, Int, Msg):
    if bytes_equal(input, "\x1b[I".as_bytes()):
        return True, 3, Msg(FocusMsg())
    elif bytes_equal(input, "\x1b[O".as_bytes()):
        return True, 3, Msg(BlurMsg())
    return False, 0, Msg(NoMsg())


fn detect_bracketed_paste(input: Span[Byte]) -> (Bool, Int, Msg):
    """Detects an input pasted while bracketed
    paste mode was enabled.

    Note: this function is a no-op if bracketed paste was not enabled
    on the terminal, since in that case we'd never see this
    particular escape sequence."""

    # Detect the start sequence.
    alias bp_start = "\x1b[200~"
    if len(input) < len(bp_start) or not bytes_equal(input[: len(bp_start)], bp_start.as_bytes()):
        return False, 0, Msg(NoMsg())

    # Skip over the start sequence.
    var remaining_input = input[len(bp_start) :]

    # If we saw the start sequence, then we must have an end sequence
    # as well. Find it.
    alias bp_end = "\x1b[201~"
    var idx = StringSlice(unsafe_from_utf8=remaining_input).find(bp_end.as_string_slice())
    var input_len = len(bp_start) + idx + len(bp_end)
    if idx == -1:
        # We have encountered the end of the input buffer without seeing
        # the marker for the end of the bracketed paste.
        # Tell the outer loop we have done a short read and we want more.
        return True, 0, Msg(NoMsg())

    # The paste is everything in-between.
    var paste = input[:idx]

    # All there is in-between is runes, not to be interpreted further.
    var k = Key(type=KeyType.Runes, text=String(StringSlice(unsafe_from_utf8=paste)), paste=True)
    # while len(paste) > 0:
    # 	r, w = utf8.DecodeRune(paste)
    # 	if r != utf8.RuneError:
    # 		k.Runes = append(k.Runes, r)

    # 	paste = paste[w:]

    return True, input_len, Msg(KeyMsg(k))


fn build_ext_sequences() -> Dict[String, Key]:
    var s = Dict[String, Key]()
    for pair in SEQUENCES.items():
        var key = pair[].value
        s[pair[].key] = key
        if not key.alt:
            key.alt = True
            s["\x1b" + pair[].key] = key

    var i = KeyType.NUL.value + 1
    while i <= KeyType.DEL.value:
        if i == KeyType.ESC.value:
            i += 1
            continue

        s[String(buffer=List[Byte](Byte(i), 0))] = Key(type=i)
        s[String(buffer=List[Byte](ord("\x1b"), Byte(i), 0))] = Key(type=i, alt=True)
        if i == KeyType.US.value:
            i = KeyType.DEL.value - 1

        i += 1

    s[" "] = Key(type=KeyType.Space, text=" ")
    s["\x1b "] = Key(type=KeyType.Space, alt=True, text=" ")
    s["\x1b\x1b"] = Key(type=KeyType.Space, alt=True)
    return s


alias EXT_SEQUENCES = build_ext_sequences()


fn build_seq_lengths() -> List[Int]:
    # var EXT_SEQUENCES = build_ext_sequences()
    alias ext_length = len(EXT_SEQUENCES)
    var sizes = List[Int](capacity=ext_length)
    for seq in EXT_SEQUENCES.keys():
        sizes.append(len(seq[]))

    var lsize = List[Int](capacity=len(sizes))
    lsize.resize(len(sizes), 0)
    for size in sizes:
        lsize.append(size[])

    sort(lsize)
    lsize.reverse()
    # sort.Slice(lsizes, fn(i, j int) bool: return lsizes[i] > lsizes[j] })
    return lsize


# alias SEQ_LENGTHS = build_seq_lengths()


# detect_sequence uses a longest prefix match over the input
# sequence and a hash map.
fn detect_sequence(input: Span[Byte]) -> (Bool, Int, Msg):
    """Detects an escape sequence in the input buffer."""
    var SEQ_LENGTHS = build_seq_lengths()
    var EXT_SEQUENCES = build_ext_sequences()
    for size in SEQ_LENGTHS:
        if size[] > len(input):
            continue

        var prefix = input[: size[]]
        try:
            key = EXT_SEQUENCES[String(StringSlice(unsafe_from_utf8=prefix))]
            return True, size[], Msg(KeyMsg(key))
        except:
            continue

    # TODO: Implement this.
    # Is this an unknown CSI sequence?
    # var loc = unknown_csi_re.FindIndex(input)
    # if loc != None:
    #     return True, loc[1], Msg(UnknownCSISequenceMsg(input[:loc[1]]))

    return False, 0, Msg(NoMsg())


fn detect_msg(buf: Span[Byte]) -> (Int, Msg):
    # Detect mouse events.
    # X10 mouse events have a length of 6 bytes
    # alias mouseEventX10Len = 6
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
        return w, msg

    # Detect bracketed paste.
    found_bp, w, msg = detect_bracketed_paste(buf)
    if found_bp:
        return w, msg

    # Detect escape sequence and control characters other than NUL,
    # possibly with an escape character in front to mark the Alt
    # modifier.
    found_seq, w, msg = detect_sequence(buf)
    if found_seq:
        return w, msg

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
    for char in StringSlice(unsafe_from_utf8=remainder).chars():
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

        return i, Msg(KeyMsg(k))

    # We didn't find an escape sequence, nor a valid rune. Was this a
    # lone escape character at the end of the input?
    if alt and len(buf) == 1:
        return 1, Msg(KeyMsg(Key(type=KeyType.Escape)))

    # The character at the current position is neither an escape
    # sequence, a valid rune start or a sole escape character. Report
    # it as an invalid byte.
    return 1, Msg(UnknownInputByteMsg(buf[0]))


fn read_events() -> Msg:
    var buffer = List[Byte](capacity=256)
    var bytes_read = read(STDIN, buffer.unsafe_ptr(), 256)
    buffer.size += Int(bytes_read)
    buffer.append(0)
    _, msg = detect_msg(buffer)
    return msg
    # return Key(KeyType.Runes, text=String(buffer=buffer^))


# Control keys. We could do this with an iota, but the values are very
# specific, so we set the values explicitly to avoid any confusion.
#
# See also:
# https://en.wikipedia.org/wiki/C0_and_C1_control_codes


fn build_key_names() -> Dict[KeyType, String]:
    """Mappings for control keys and other special keys to friendly consts."""
    var keys = Dict[KeyType, String]()
    keys[KeyType.NUL] = "ctrl+@"
    keys[KeyType.SOH] = "ctrl+a"
    keys[KeyType.STX] = "ctrl+b"
    keys[KeyType.ETX] = "ctrl+c"
    keys[KeyType.EOT] = "ctrl+d"
    keys[KeyType.ENQ] = "ctrl+e"
    keys[KeyType.ACK] = "ctrl+f"
    keys[KeyType.BEL] = "ctrl+g"
    keys[KeyType.BS] = "ctrl+h"
    keys[KeyType.HT] = "tab"
    keys[KeyType.LF] = "ctrl+j"
    keys[KeyType.VT] = "ctrl+k"
    keys[KeyType.FF] = "ctrl+l"
    keys[KeyType.CR] = "enter"
    keys[KeyType.SO] = "ctrl+n"
    keys[KeyType.SI] = "ctrl+o"
    keys[KeyType.DLE] = "ctrl+p"
    keys[KeyType.DC1] = "ctrl+q"
    keys[KeyType.DC2] = "ctrl+r"
    keys[KeyType.DC3] = "ctrl+s"
    keys[KeyType.DC4] = "ctrl+t"
    keys[KeyType.NAK] = "ctrl+u"
    keys[KeyType.SYN] = "ctrl+v"
    keys[KeyType.ETB] = "ctrl+w"
    keys[KeyType.CAN] = "ctrl+x"
    keys[KeyType.EM] = "ctrl+y"
    keys[KeyType.SUB] = "ctrl+z"
    keys[KeyType.ESC] = "esc"
    keys[KeyType.FS] = "ctrl+\\"
    keys[KeyType.GS] = "ctrl+]"
    keys[KeyType.RS] = "ctrl+^"
    keys[KeyType.US] = "ctrl+_"
    keys[KeyType.DEL] = "backspace"
    keys[KeyType.Runes] = "runes"
    keys[KeyType.Up] = "up"
    keys[KeyType.Down] = "down"
    keys[KeyType.Right] = "right"
    keys[KeyType.Space] = " "
    keys[KeyType.Left] = "left"
    keys[KeyType.ShiftTab] = "shift+tab"
    keys[KeyType.Home] = "home"
    keys[KeyType.End] = "end"
    keys[KeyType.CtrlHome] = "ctrl+home"
    keys[KeyType.CtrlEnd] = "ctrl+end"
    keys[KeyType.ShiftHome] = "shift+home"
    keys[KeyType.ShiftEnd] = "shift+end"
    keys[KeyType.CtrlShiftHome] = "ctrl+shift+home"
    keys[KeyType.CtrlShiftEnd] = "ctrl+shift+end"
    keys[KeyType.PgUp] = "pgup"
    keys[KeyType.PgDown] = "pgdown"
    keys[KeyType.CtrlPgUp] = "ctrl+pgup"
    keys[KeyType.CtrlPgDown] = "ctrl+pgdown"
    keys[KeyType.Delete] = "delete"
    keys[KeyType.Insert] = "insert"
    keys[KeyType.CtrlUp] = "ctrl+up"
    keys[KeyType.CtrlDown] = "ctrl+down"
    keys[KeyType.CtrlRight] = "ctrl+right"
    keys[KeyType.CtrlLeft] = "ctrl+left"
    keys[KeyType.ShiftUp] = "shift+up"
    keys[KeyType.ShiftDown] = "shift+down"
    keys[KeyType.ShiftRight] = "shift+right"
    keys[KeyType.ShiftLeft] = "shift+left"
    keys[KeyType.CtrlShiftUp] = "ctrl+shift+up"
    keys[KeyType.CtrlShiftDown] = "ctrl+shift+down"
    keys[KeyType.CtrlShiftLeft] = "ctrl+shift+left"
    keys[KeyType.CtrlShiftRight] = "ctrl+shift+right"
    keys[KeyType.F1] = "f1"
    keys[KeyType.F2] = "f2"
    keys[KeyType.F3] = "f3"
    keys[KeyType.F4] = "f4"
    keys[KeyType.F5] = "f5"
    keys[KeyType.F6] = "f6"
    keys[KeyType.F7] = "f7"
    keys[KeyType.F8] = "f8"
    keys[KeyType.F9] = "f9"
    keys[KeyType.F10] = "f10"
    keys[KeyType.F11] = "f11"
    keys[KeyType.F12] = "f12"
    keys[KeyType.F13] = "f13"
    keys[KeyType.F14] = "f14"
    keys[KeyType.F15] = "f15"
    keys[KeyType.F16] = "f16"
    keys[KeyType.F17] = "f17"
    keys[KeyType.F18] = "f18"
    keys[KeyType.F19] = "f19"
    keys[KeyType.F20] = "f20"
    return keys^


alias KEY_NAMES = build_key_names()


fn build_sequences() -> Dict[String, Key]:
    var keys = Dict[String, Key]()

    # Arrow keys
    keys["\x1b[A"] = Key(KeyType.Up)
    keys["\x1b[B"] = Key(KeyType.Down)
    keys["\x1b[C"] = Key(KeyType.Right)
    keys["\x1b[D"] = Key(KeyType.Left)
    keys["\x1b[1;2A"] = Key(KeyType.ShiftUp)
    keys["\x1b[1;2B"] = Key(KeyType.ShiftDown)
    keys["\x1b[1;2C"] = Key(KeyType.ShiftRight)
    keys["\x1b[1;2D"] = Key(KeyType.ShiftLeft)
    keys["\x1b[OA"] = Key(KeyType.ShiftUp)
    keys["\x1b[OB"] = Key(KeyType.ShiftDown)
    keys["\x1b[OC"] = Key(KeyType.ShiftRight)
    keys["\x1b[OD"] = Key(KeyType.ShiftLeft)
    keys["\x1b[a"] = Key(KeyType.ShiftUp)
    keys["\x1b[b"] = Key(KeyType.ShiftDown)
    keys["\x1b[c"] = Key(KeyType.ShiftRight)
    keys["\x1b[d"] = Key(KeyType.ShiftLeft)
    keys["\x1b[1;3A"] = Key(KeyType.Up, alt=True)
    keys["\x1b[1;3B"] = Key(KeyType.Down, alt=True)
    keys["\x1b[1;3C"] = Key(KeyType.Right, alt=True)
    keys["\x1b[1;3D"] = Key(KeyType.Left, alt=True)
    keys["\x1b[1;4A"] = Key(KeyType.ShiftUp, alt=True)
    keys["\x1b[1;4B"] = Key(KeyType.ShiftDown, alt=True)
    keys["\x1b[1;4C"] = Key(KeyType.ShiftRight, alt=True)
    keys["\x1b[1;4D"] = Key(KeyType.ShiftLeft, alt=True)
    keys["\x1b[1;5A"] = Key(KeyType.CtrlUp)
    keys["\x1b[1;5B"] = Key(KeyType.CtrlDown)
    keys["\x1b[1;5C"] = Key(KeyType.CtrlRight)
    keys["\x1b[1;5D"] = Key(KeyType.CtrlLeft)
    keys["\x1b[Oa"] = Key(KeyType.CtrlUp, alt=True)
    keys["\x1b[Ob"] = Key(KeyType.CtrlDown, alt=True)
    keys["\x1b[Oc"] = Key(KeyType.CtrlRight, alt=True)
    keys["\x1b[Od"] = Key(KeyType.CtrlLeft, alt=True)
    keys["\x1b[1;6A"] = Key(KeyType.CtrlShiftUp)
    keys["\x1b[1;6B"] = Key(KeyType.CtrlShiftDown)
    keys["\x1b[1;6C"] = Key(KeyType.CtrlShiftRight)
    keys["\x1b[1;6D"] = Key(KeyType.CtrlShiftLeft)
    keys["\x1b[1;7A"] = Key(KeyType.CtrlUp, alt=True)
    keys["\x1b[1;7B"] = Key(KeyType.CtrlDown, alt=True)
    keys["\x1b[1;7C"] = Key(KeyType.CtrlRight, alt=True)
    keys["\x1b[1;7D"] = Key(KeyType.CtrlLeft, alt=True)
    keys["\x1b[1;8A"] = Key(KeyType.CtrlShiftUp, alt=True)
    keys["\x1b[1;8B"] = Key(KeyType.CtrlShiftDown, alt=True)
    keys["\x1b[1;8C"] = Key(KeyType.CtrlShiftRight, alt=True)
    keys["\x1b[1;8D"] = Key(KeyType.CtrlShiftLeft, alt=True)

    # Misc. keys
    keys["\x1b[Z"] = Key(KeyType.ShiftTab)
    keys["\x1b[2~"] = Key(KeyType.Insert)
    keys["\x1b[3~"] = Key(KeyType.Delete)
    keys["\x1b[5~"] = Key(KeyType.PgUp)
    keys["\x1b[6~"] = Key(KeyType.PgDown)
    keys["\x1b[1~"] = Key(KeyType.Home)
    keys["\x1b[H"] = Key(KeyType.Home)
    keys["\x1b[1;3H"] = Key(KeyType.Home, alt=True)
    keys["\x1b[1;5H"] = Key(KeyType.CtrlHome)
    keys["\x1b[1;7H"] = Key(KeyType.CtrlHome, alt=True)
    keys["\x1b[1;2H"] = Key(KeyType.ShiftHome)
    keys["\x1b[1;4H"] = Key(KeyType.ShiftHome, alt=True)
    keys["\x1b[1;6H"] = Key(KeyType.CtrlShiftHome)
    keys["\x1b[1;8H"] = Key(KeyType.CtrlShiftHome, alt=True)
    keys["\x1b[4~"] = Key(KeyType.End)
    keys["\x1b[F"] = Key(KeyType.End)
    keys["\x1b[1;3F"] = Key(KeyType.End, alt=True)
    keys["\x1b[1;5F"] = Key(KeyType.CtrlEnd)
    keys["\x1b[1;7F"] = Key(KeyType.CtrlEnd, alt=True)
    keys["\x1b[1;2F"] = Key(KeyType.ShiftEnd)
    keys["\x1b[1;4F"] = Key(KeyType.ShiftEnd, alt=True)
    keys["\x1b[1;6F"] = Key(KeyType.CtrlShiftEnd)
    keys["\x1b[1;8F"] = Key(KeyType.CtrlShiftEnd, alt=True)
    keys["\x1b[7~"] = Key(KeyType.Home)
    keys["\x1b[7^"] = Key(KeyType.CtrlHome)
    keys["\x1b[7$"] = Key(KeyType.ShiftHome)
    keys["\x1b[7@"] = Key(KeyType.CtrlShiftHome)
    keys["\x1b[8~"] = Key(KeyType.End)
    keys["\x1b[8^"] = Key(KeyType.CtrlEnd)
    keys["\x1b[8$"] = Key(KeyType.ShiftEnd)
    keys["\x1b[8@"] = Key(KeyType.CtrlShiftEnd)
    keys["\x1b[2;3~"] = Key(KeyType.Insert, alt=True)
    keys["\x1b[3;3~"] = Key(KeyType.Delete, alt=True)
    keys["\x1b[5;3~"] = Key(KeyType.PgUp, alt=True)
    keys["\x1b[6;3~"] = Key(KeyType.PgDown, alt=True)
    keys["\x1b[1;5A"] = Key(KeyType.CtrlUp)
    keys["\x1b[1;5B"] = Key(KeyType.CtrlDown)
    keys["\x1b[1;5C"] = Key(KeyType.CtrlRight)
    keys["\x1b[1;5D"] = Key(KeyType.CtrlLeft)
    keys["\x1b[1;6A"] = Key(KeyType.CtrlShiftUp)
    keys["\x1b[1;6B"] = Key(KeyType.CtrlShiftDown)
    keys["\x1b[1;6C"] = Key(KeyType.CtrlShiftRight)
    keys["\x1b[1;6D"] = Key(KeyType.CtrlShiftLeft)
    keys["\x1b[1;7A"] = Key(KeyType.CtrlUp, alt=True)
    keys["\x1b[1;7B"] = Key(KeyType.CtrlDown, alt=True)
    keys["\x1b[1;7C"] = Key(KeyType.CtrlRight, alt=True)
    keys["\x1b[1;7D"] = Key(KeyType.CtrlLeft, alt=True)
    keys["\x1b[1;8A"] = Key(KeyType.CtrlShiftUp, alt=True)
    keys["\x1b[1;8B"] = Key(KeyType.CtrlShiftDown, alt=True)
    keys["\x1b[1;8C"] = Key(KeyType.CtrlShiftRight, alt=True)
    keys["\x1b[1;8D"] = Key(KeyType.CtrlShiftLeft, alt=True)
    keys["\x1b[Z"] = Key(KeyType.ShiftTab)
    keys["\x1b[2~"] = Key(KeyType.Insert)
    keys["\x1b[3;2~"] = Key(KeyType.Insert, alt=True)
    keys["\x1b[3~"] = Key(KeyType.Delete)
    keys["\x1b[3;3~"] = Key(KeyType.Delete, alt=True)
    keys["\x1b[5~"] = Key(KeyType.PgUp)
    keys["\x1b[5;3~"] = Key(KeyType.PgUp, alt=True)
    keys["\x1b[5;5~"] = Key(KeyType.CtrlPgUp)
    keys["\x1b[5^"] = Key(KeyType.CtrlPgUp)
    keys["\x1b[5;7~"] = Key(KeyType.CtrlPgUp, alt=True)
    keys["\x1b[6~"] = Key(KeyType.PgDown)
    keys["\x1b[6;3~"] = Key(KeyType.PgDown, alt=True)
    keys["\x1b[6;5~"] = Key(KeyType.CtrlPgDown)
    keys["\x1b[6^"] = Key(KeyType.CtrlPgDown)
    keys["\x1b[6;7~"] = Key(KeyType.CtrlPgDown, alt=True)
    keys["\x1b[1~"] = Key(KeyType.Home)
    keys["\x1b[H"] = Key(KeyType.Home)
    keys["\x1b[1;3H"] = Key(KeyType.Home, alt=True)
    keys["\x1b[1;5H"] = Key(KeyType.CtrlHome)
    keys["\x1b[1;7H"] = Key(KeyType.CtrlHome, alt=True)
    keys["\x1b[1;2H"] = Key(KeyType.ShiftHome)
    keys["\x1b[1;4H"] = Key(KeyType.ShiftHome, alt=True)
    keys["\x1b[1;6H"] = Key(KeyType.CtrlShiftHome)
    keys["\x1b[1;8H"] = Key(KeyType.CtrlShiftHome, alt=True)
    keys["\x1b[4~"] = Key(KeyType.End)
    keys["\x1b[F"] = Key(KeyType.End)
    keys["\x1b[1;3F"] = Key(KeyType.End, alt=True)
    keys["\x1b[1;5F"] = Key(KeyType.CtrlEnd)
    keys["\x1b[1;7F"] = Key(KeyType.CtrlEnd, alt=True)
    keys["\x1b[1;2F"] = Key(KeyType.ShiftEnd)
    keys["\x1b[1;4F"] = Key(KeyType.ShiftEnd, alt=True)
    keys["\x1b[1;6F"] = Key(KeyType.CtrlShiftEnd)
    keys["\x1b[1;8F"] = Key(KeyType.CtrlShiftEnd, alt=True)
    keys["\x1b[7~"] = Key(KeyType.Home)
    keys["\x1b[7^"] = Key(KeyType.CtrlHome)
    keys["\x1b[7$"] = Key(KeyType.ShiftHome)
    keys["\x1b[7@"] = Key(KeyType.CtrlShiftHome)
    keys["\x1b[8~"] = Key(KeyType.End)
    keys["\x1b[8^"] = Key(KeyType.CtrlEnd)
    keys["\x1b[8$"] = Key(KeyType.ShiftEnd)
    keys["\x1b[8@"] = Key(KeyType.CtrlShiftEnd)

    # Function keys, Linux console
    keys["\x1b[[A"] = Key(KeyType.F1)  # linux console
    keys["\x1b[[B"] = Key(KeyType.F2)  # linux console
    keys["\x1b[[C"] = Key(KeyType.F3)  # linux console
    keys["\x1b[[D"] = Key(KeyType.F4)  # linux console
    keys["\x1b[[E"] = Key(KeyType.F5)  # linux console

    # Function keys, X11
    keys["\x1bOP"] = Key(KeyType.F1)  # vt100, xterm
    keys["\x1bOQ"] = Key(KeyType.F2)  # vt100, xterm
    keys["\x1bOR"] = Key(KeyType.F3)  # vt100, xterm
    keys["\x1bOS"] = Key(KeyType.F4)  # vt100, xterm

    keys["\x1b[1;3P"] = Key(KeyType.F1, alt=True)  # vt100, xterm
    keys["\x1b[1;3Q"] = Key(KeyType.F2, alt=True)  # vt100, xterm
    keys["\x1b[1;3R"] = Key(KeyType.F3, alt=True)  # vt100, xterm
    keys["\x1b[1;3S"] = Key(KeyType.F4, alt=True)  # vt100, xterm

    keys["\x1b[11~"] = Key(KeyType.F1)  # urxvt
    keys["\x1b[12~"] = Key(KeyType.F2)  # urxvt
    keys["\x1b[13~"] = Key(KeyType.F3)  # urxvt
    keys["\x1b[14~"] = Key(KeyType.F4)  # urxvt

    keys["\x1b[15~"] = Key(KeyType.F5)  # vt100, xterm, also urxvt

    keys["\x1b[15;3~"] = Key(KeyType.F5, alt=True)  # vt100, xterm, also urxvt

    keys["\x1b[17~"] = Key(KeyType.F6)  # vt100, xterm, also urxvt
    keys["\x1b[18~"] = Key(KeyType.F7)  # vt100, xterm, also urxvt
    keys["\x1b[19~"] = Key(KeyType.F8)  # vt100, xterm, also urxvt
    keys["\x1b[20~"] = Key(KeyType.F9)  # vt100, xterm, also urxvt
    keys["\x1b[21~"] = Key(KeyType.F10)  # vt100, xterm, also urxvt

    keys["\x1b[17;3~"] = Key(KeyType.F6, alt=True)  # vt100, xterm
    keys["\x1b[18;3~"] = Key(KeyType.F7, alt=True)  # vt100, xterm
    keys["\x1b[19;3~"] = Key(KeyType.F8, alt=True)  # vt100, xterm
    keys["\x1b[20;3~"] = Key(KeyType.F9, alt=True)  # vt100, xterm
    keys["\x1b[21;3~"] = Key(KeyType.F10, alt=True)  # vt100, xterm

    keys["\x1b[23~"] = Key(KeyType.F11)  # vt100, xterm, also urxvt
    keys["\x1b[24~"] = Key(KeyType.F12)  # vt100, xterm, also urxvt

    keys["\x1b[23;3~"] = Key(KeyType.F11, alt=True)  # vt100, xterm
    keys["\x1b[24;3~"] = Key(KeyType.F12, alt=True)  # vt100, xterm

    keys["\x1b[1;2P"] = Key(KeyType.F13)
    keys["\x1b[1;2Q"] = Key(KeyType.F14)

    keys["\x1b[25~"] = Key(KeyType.F13)  # vt100, xterm, also urxvt
    keys["\x1b[26~"] = Key(KeyType.F14)  # vt100, xterm, also urxvt

    keys["\x1b[25;3~"] = Key(KeyType.F13, alt=True)  # vt100, xterm
    keys["\x1b[26;3~"] = Key(KeyType.F14, alt=True)  # vt100, xterm

    keys["\x1b[1;2R"] = Key(KeyType.F15)
    keys["\x1b[1;2S"] = Key(KeyType.F16)

    keys["\x1b[28~"] = Key(KeyType.F15)  # vt100, xterm, also urxvt
    keys["\x1b[29~"] = Key(KeyType.F16)  # vt100, xterm, also urxvt

    keys["\x1b[28;3~"] = Key(KeyType.F15, alt=True)  # vt100, xterm
    keys["\x1b[29;3~"] = Key(KeyType.F16, alt=True)  # vt100, xterm

    keys["\x1b[15;2~"] = Key(KeyType.F17)
    keys["\x1b[17;2~"] = Key(KeyType.F18)
    keys["\x1b[18;2~"] = Key(KeyType.F19)
    keys["\x1b[19;2~"] = Key(KeyType.F20)

    keys["\x1b[31~"] = Key(KeyType.F17)
    keys["\x1b[32~"] = Key(KeyType.F18)
    keys["\x1b[33~"] = Key(KeyType.F19)
    keys["\x1b[34~"] = Key(KeyType.F20)

    # Powershell sequences.
    keys["\x1bOA"] = Key(KeyType.Up, alt=False)
    keys["\x1bOB"] = Key(KeyType.Down, alt=False)
    keys["\x1bOC"] = Key(KeyType.Right, alt=False)
    keys["\x1bOD"] = Key(KeyType.Left, alt=False)
    return keys


alias SEQUENCES = build_sequences()
"""sequence mappings."""
