from collections import Dict
from .termios import read, STDIN


@value
struct KeyMsg:
    """Contains information about a keypress. KeyMsgs are always sent to
    the program's update function. There are a couple general patterns you could
    use to check for keypresses.

    ```go
    # Switch on the string representation of the key (shorter)
    switch msg := msg.(type) {
    case KeyMsg:
        switch msg.String() {
        case "enter":
        print("you pressed enter!")
                case "a":
        print("you pressed a!")
                }
    }

    # Switch on the key type (more foolproof)
    switch msg := msg.(type) {
    case KeyMsg:
        switch msg.Type {
        case KeyEnter:
            print("you pressed enter!")
                    case KeyRunes:
            switch string(msg.Runes) {
            case "a":
                print("you pressed a!")
            }
        }
    }
    ```

    Note that `Key.text` will always contain at least one character, so you can
    always safely call `Key.text[0]`. In most cases `Key.text` will only contain
    one character, though certain input method editors (most notably Chinese
    IMEs) can input multiple runes at once."""

    var key: Key


@value
@register_passable
struct KeyType(CollectionElement, Stringable, KeyElement):
    """Indicates the key pressed, such as `KeyEnter` or `KeyBreak` or `KeyCtrlC`.
    All other keys will be type `KeyRunes`. To get the rune value, check the Rune
    method on a `Key` struct, or use the `str(Key)` method.

    ```mojo
    from banjo.key import Key, KeyType

    var k = Key(KeyType.KeyRunes, text='a', alt=True)
    if k.type == KeyType.KeyRunes:
        print(k.text)
        # Output: a

        print(str(k))
        # Output: alt+a
    ```
    """

    var value: Int
    alias KeyNUL: KeyType = 0
    """null, \\0"""
    alias KeySOH: KeyType = 1
    """start of heading."""
    alias KeySTX: KeyType = 2
    """start of text."""
    alias KeyETX: KeyType = 3
    """break, ctrl+c."""
    alias KeyEOT: KeyType = 4
    """end of transmission."""
    alias KeyENQ: KeyType = 5
    """enquiry."""
    alias KeyACK: KeyType = 6
    """acknowledge."""
    alias KeyBEL: KeyType = 7
    """bell, \\a"""
    alias KeyBS: KeyType = 8
    """backspace."""
    alias KeyHT: KeyType = 9
    """horizontal tabulation, \\t."""
    alias KeyLF: KeyType = 10
    """line feed, \\n."""
    alias KeyVT: KeyType = 11
    """vertical tabulation, \\v."""
    alias KeyFF: KeyType = 12
    """form feed, \\f."""
    alias KeyCR: KeyType = 13
    """carriage return, \\r."""
    alias KeySO: KeyType = 14
    """shift out."""
    alias KeySI: KeyType = 15
    """shift in."""
    alias KeyDLE: KeyType = 16
    """data link escape."""
    alias KeyDC1: KeyType = 17
    """device control one."""
    alias KeyDC2: KeyType = 18
    """device control two."""
    alias KeyDC3: KeyType = 19
    """device control three."""
    alias KeyDC4: KeyType = 20
    """device control four."""
    alias KeyNAK: KeyType = 21
    """negative acknowledge."""
    alias KeySYN: KeyType = 22
    """synchronous idle."""
    alias KeyETB: KeyType = 23
    """end of transmission block."""
    alias KeyCAN: KeyType = 24
    """cancel."""
    alias KeyEM: KeyType = 25
    """end of medium."""
    alias KeySUB: KeyType = 26
    """substitution."""
    alias KeyESC: KeyType = 27
    """escape, \\e."""
    alias KeyFS: KeyType = 28
    """file separator."""
    alias KeyGS: KeyType = 29
    """group separator."""
    alias KeyRS: KeyType = 30
    """record separator."""
    alias KeyUS: KeyType = 31
    """unit separator."""
    alias KeyDEL: KeyType = 127
    """delete. on most systems this is mapped to backspace, I hear."""

    # Control key aliases.
    alias KeyNull: KeyType = Self.KeyNUL
    alias KeyBreak: KeyType = Self.KeyETX
    alias KeyEnter: KeyType = Self.KeyCR
    alias KeyBackspace: KeyType = Self.KeyDEL
    alias KeyTab: KeyType = Self.KeyHT
    alias KeyEsc: KeyType = Self.KeyESC
    alias KeyEscape: KeyType = Self.KeyESC
    alias KeyCtrlAt: KeyType = Self.KeyNUL  # ctrl+@
    alias KeyCtrlA: KeyType = Self.KeySOH
    alias KeyCtrlB: KeyType = Self.KeySTX
    alias KeyCtrlC: KeyType = Self.KeyETX
    alias KeyCtrlD: KeyType = Self.KeyEOT
    alias KeyCtrlE: KeyType = Self.KeyENQ
    alias KeyCtrlF: KeyType = Self.KeyACK
    alias KeyCtrlG: KeyType = Self.KeyBEL
    alias KeyCtrlH: KeyType = Self.KeyBS
    alias KeyCtrlI: KeyType = Self.KeyHT
    alias KeyCtrlJ: KeyType = Self.KeyLF
    alias KeyCtrlK: KeyType = Self.KeyVT
    alias KeyCtrlL: KeyType = Self.KeyFF
    alias KeyCtrlM: KeyType = Self.KeyCR
    alias KeyCtrlN: KeyType = Self.KeySO
    alias KeyCtrlO: KeyType = Self.KeySI
    alias KeyCtrlP: KeyType = Self.KeyDLE
    alias KeyCtrlQ: KeyType = Self.KeyDC1
    alias KeyCtrlR: KeyType = Self.KeyDC2
    alias KeyCtrlS: KeyType = Self.KeyDC3
    alias KeyCtrlT: KeyType = Self.KeyDC4
    alias KeyCtrlU: KeyType = Self.KeyNAK
    alias KeyCtrlV: KeyType = Self.KeySYN
    alias KeyCtrlW: KeyType = Self.KeyETB
    alias KeyCtrlX: KeyType = Self.KeyCAN
    alias KeyCtrlY: KeyType = Self.KeyEM
    alias KeyCtrlZ: KeyType = Self.KeySUB
    alias KeyCtrlOpenBracket: KeyType = Self.KeyESC  # ctrl+[
    alias KeyCtrlBackslash: KeyType = Self.KeyFS  # ctrl+\
    alias KeyCtrlCloseBracket: KeyType = Self.KeyGS  # ctrl+]
    alias KeyCtrlCaret: KeyType = Self.KeyRS  # ctrl+^
    alias KeyCtrlUnderscore: KeyType = Self.KeyUS  # ctrl+_
    alias KeyCtrlQuestionMark: KeyType = Self.KeyDEL  # ctrl+?

    # Other keys.
    alias KeyRunes: KeyType = -1
    alias KeyUp: KeyType = -2
    alias KeyDown: KeyType = -3
    alias KeyRight: KeyType = -4
    alias KeyLeft: KeyType = -5
    alias KeyShiftTab: KeyType = -6
    alias KeyHome: KeyType = -7
    alias KeyEnd: KeyType = -8
    alias KeyPgUp: KeyType = -9
    alias KeyPgDown: KeyType = -10
    alias KeyCtrlPgUp: KeyType = -11
    alias KeyCtrlPgDown: KeyType = -12
    alias KeyDelete: KeyType = -13
    alias KeyInsert: KeyType = -14
    alias KeySpace: KeyType = -15
    alias KeyCtrlUp: KeyType = -16
    alias KeyCtrlDown: KeyType = -17
    alias KeyCtrlRight: KeyType = -18
    alias KeyCtrlLeft: KeyType = -19
    alias KeyCtrlHome: KeyType = -20
    alias KeyCtrlEnd: KeyType = -21
    alias KeyShiftUp: KeyType = -22
    alias KeyShiftDown: KeyType = -23
    alias KeyShiftRight: KeyType = -24
    alias KeyShiftLeft: KeyType = -25
    alias KeyShiftHome: KeyType = -26
    alias KeyShiftEnd: KeyType = -27
    alias KeyCtrlShiftUp: KeyType = -28
    alias KeyCtrlShiftDown: KeyType = -29
    alias KeyCtrlShiftLeft: KeyType = -30
    alias KeyCtrlShiftRight: KeyType = -31
    alias KeyCtrlShiftHome: KeyType = -32
    alias KeyCtrlShiftEnd: KeyType = -33
    alias KeyF1: KeyType = -34
    alias KeyF2: KeyType = -35
    alias KeyF3: KeyType = -36
    alias KeyF4: KeyType = -37
    alias KeyF5: KeyType = -38
    alias KeyF6: KeyType = -39
    alias KeyF7: KeyType = -40
    alias KeyF8: KeyType = -41
    alias KeyF9: KeyType = -42
    alias KeyF10: KeyType = -43
    alias KeyF11: KeyType = -44
    alias KeyF12: KeyType = -45
    alias KeyF13: KeyType = -46
    alias KeyF14: KeyType = -47
    alias KeyF15: KeyType = -48
    alias KeyF16: KeyType = -49
    alias KeyF17: KeyType = -50
    alias KeyF18: KeyType = -51
    alias KeyF19: KeyType = -52
    alias KeyF20: KeyType = -53

    @implicit
    fn __init__(out self, value: Int):
        self.value = value

    fn __str__(self) -> String:
        return key_names.get(self.value, "")

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
        writer.write(self.value)


@value
struct Key(CollectionElement, Stringable):
    """Key contains information about a keypress."""

    var type: KeyType
    var text: String
    var alt: Bool
    var paste: Bool

    fn __init__(out self, type: KeyType, *, text: String = "", alt: Bool = False, paste: Bool = False):
        self.type = type
        self.text = text
        self.alt = alt
        self.paste = paste

    fn __str__(self) -> String:
        var sequence = sequences.get(self.text)
        if sequence:
            return key_names.get(sequence.value().type, "")

        var builder = String()
        if self.alt:
            builder.write("alt+")

        if self.type == KeyType.KeyRunes:
            if self.paste:
                builder.write("[")
            builder.write(self.text)
            if self.paste:
                builder.write("]")
            return builder
        else:
            builder.write(str(self.type))
            return builder


fn read_events() -> Key:
    var buffer = List[UInt8](capacity=10)
    var bytes_read = read(STDIN, buffer.unsafe_ptr(), 10)
    buffer.size += int(bytes_read)
    buffer.append(0)
    return Key(KeyType.KeyRunes, text=String(buffer^))


# Control keys. We could do this with an iota, but the values are very
# specific, so we set the values explicitly to avoid any confusion.
#
# See also:
# https://en.wikipedia.org/wiki/C0_and_C1_control_codes


fn build_key_names() -> Dict[KeyType, String]:
    """Mappings for control keys and other special keys to friendly consts."""
    var keys = Dict[KeyType, String]()
    keys[KeyType.KeyNUL] = "ctrl+@"
    keys[KeyType.KeySOH] = "ctrl+a"
    keys[KeyType.KeySTX] = "ctrl+b"
    keys[KeyType.KeyETX] = "ctrl+c"
    keys[KeyType.KeyEOT] = "ctrl+d"
    keys[KeyType.KeyENQ] = "ctrl+e"
    keys[KeyType.KeyACK] = "ctrl+f"
    keys[KeyType.KeyBEL] = "ctrl+g"
    keys[KeyType.KeyBS] = "ctrl+h"
    keys[KeyType.KeyHT] = "tab"
    keys[KeyType.KeyLF] = "ctrl+j"
    keys[KeyType.KeyVT] = "ctrl+k"
    keys[KeyType.KeyFF] = "ctrl+l"
    keys[KeyType.KeyCR] = "enter"
    keys[KeyType.KeySO] = "ctrl+n"
    keys[KeyType.KeySI] = "ctrl+o"
    keys[KeyType.KeyDLE] = "ctrl+p"
    keys[KeyType.KeyDC1] = "ctrl+q"
    keys[KeyType.KeyDC2] = "ctrl+r"
    keys[KeyType.KeyDC3] = "ctrl+s"
    keys[KeyType.KeyDC4] = "ctrl+t"
    keys[KeyType.KeyNAK] = "ctrl+u"
    keys[KeyType.KeySYN] = "ctrl+v"
    keys[KeyType.KeyETB] = "ctrl+w"
    keys[KeyType.KeyCAN] = "ctrl+x"
    keys[KeyType.KeyEM] = "ctrl+y"
    keys[KeyType.KeySUB] = "ctrl+z"
    keys[KeyType.KeyESC] = "esc"
    keys[KeyType.KeyFS] = "ctrl+\\"
    keys[KeyType.KeyGS] = "ctrl+]"
    keys[KeyType.KeyRS] = "ctrl+^"
    keys[KeyType.KeyUS] = "ctrl+_"
    keys[KeyType.KeyDEL] = "backspace"
    keys[KeyType.KeyRunes] = "runes"
    keys[KeyType.KeyUp] = "up"
    keys[KeyType.KeyDown] = "down"
    keys[KeyType.KeyRight] = "right"
    keys[KeyType.KeySpace] = " "
    keys[KeyType.KeyLeft] = "left"
    keys[KeyType.KeyShiftTab] = "shift+tab"
    keys[KeyType.KeyHome] = "home"
    keys[KeyType.KeyEnd] = "end"
    keys[KeyType.KeyCtrlHome] = "ctrl+home"
    keys[KeyType.KeyCtrlEnd] = "ctrl+end"
    keys[KeyType.KeyShiftHome] = "shift+home"
    keys[KeyType.KeyShiftEnd] = "shift+end"
    keys[KeyType.KeyCtrlShiftHome] = "ctrl+shift+home"
    keys[KeyType.KeyCtrlShiftEnd] = "ctrl+shift+end"
    keys[KeyType.KeyPgUp] = "pgup"
    keys[KeyType.KeyPgDown] = "pgdown"
    keys[KeyType.KeyCtrlPgUp] = "ctrl+pgup"
    keys[KeyType.KeyCtrlPgDown] = "ctrl+pgdown"
    keys[KeyType.KeyDelete] = "delete"
    keys[KeyType.KeyInsert] = "insert"
    keys[KeyType.KeyCtrlUp] = "ctrl+up"
    keys[KeyType.KeyCtrlDown] = "ctrl+down"
    keys[KeyType.KeyCtrlRight] = "ctrl+right"
    keys[KeyType.KeyCtrlLeft] = "ctrl+left"
    keys[KeyType.KeyShiftUp] = "shift+up"
    keys[KeyType.KeyShiftDown] = "shift+down"
    keys[KeyType.KeyShiftRight] = "shift+right"
    keys[KeyType.KeyShiftLeft] = "shift+left"
    keys[KeyType.KeyCtrlShiftUp] = "ctrl+shift+up"
    keys[KeyType.KeyCtrlShiftDown] = "ctrl+shift+down"
    keys[KeyType.KeyCtrlShiftLeft] = "ctrl+shift+left"
    keys[KeyType.KeyCtrlShiftRight] = "ctrl+shift+right"
    keys[KeyType.KeyF1] = "f1"
    keys[KeyType.KeyF2] = "f2"
    keys[KeyType.KeyF3] = "f3"
    keys[KeyType.KeyF4] = "f4"
    keys[KeyType.KeyF5] = "f5"
    keys[KeyType.KeyF6] = "f6"
    keys[KeyType.KeyF7] = "f7"
    keys[KeyType.KeyF8] = "f8"
    keys[KeyType.KeyF9] = "f9"
    keys[KeyType.KeyF10] = "f10"
    keys[KeyType.KeyF11] = "f11"
    keys[KeyType.KeyF12] = "f12"
    keys[KeyType.KeyF13] = "f13"
    keys[KeyType.KeyF14] = "f14"
    keys[KeyType.KeyF15] = "f15"
    keys[KeyType.KeyF16] = "f16"
    keys[KeyType.KeyF17] = "f17"
    keys[KeyType.KeyF18] = "f18"
    keys[KeyType.KeyF19] = "f19"
    keys[KeyType.KeyF20] = "f20"
    return keys


var key_names = build_key_names()


fn build_sequences() -> Dict[String, Key]:
    var keys = Dict[String, Key]()

    # Arrow keys
    keys["\x1b[A"] = Key(KeyType.KeyUp)
    keys["\x1b[B"] = Key(KeyType.KeyDown)
    keys["\x1b[C"] = Key(KeyType.KeyRight)
    keys["\x1b[D"] = Key(KeyType.KeyLeft)
    keys["\x1b[1;2A"] = Key(KeyType.KeyShiftUp)
    keys["\x1b[1;2B"] = Key(KeyType.KeyShiftDown)
    keys["\x1b[1;2C"] = Key(KeyType.KeyShiftRight)
    keys["\x1b[1;2D"] = Key(KeyType.KeyShiftLeft)
    keys["\x1b[OA"] = Key(KeyType.KeyShiftUp)
    keys["\x1b[OB"] = Key(KeyType.KeyShiftDown)
    keys["\x1b[OC"] = Key(KeyType.KeyShiftRight)
    keys["\x1b[OD"] = Key(KeyType.KeyShiftLeft)
    keys["\x1b[a"] = Key(KeyType.KeyShiftUp)
    keys["\x1b[b"] = Key(KeyType.KeyShiftDown)
    keys["\x1b[c"] = Key(KeyType.KeyShiftRight)
    keys["\x1b[d"] = Key(KeyType.KeyShiftLeft)
    keys["\x1b[1;3A"] = Key(KeyType.KeyUp, alt=True)
    keys["\x1b[1;3B"] = Key(KeyType.KeyDown, alt=True)
    keys["\x1b[1;3C"] = Key(KeyType.KeyRight, alt=True)
    keys["\x1b[1;3D"] = Key(KeyType.KeyLeft, alt=True)
    keys["\x1b[1;4A"] = Key(KeyType.KeyShiftUp, alt=True)
    keys["\x1b[1;4B"] = Key(KeyType.KeyShiftDown, alt=True)
    keys["\x1b[1;4C"] = Key(KeyType.KeyShiftRight, alt=True)
    keys["\x1b[1;4D"] = Key(KeyType.KeyShiftLeft, alt=True)
    keys["\x1b[1;5A"] = Key(KeyType.KeyCtrlUp)
    keys["\x1b[1;5B"] = Key(KeyType.KeyCtrlDown)
    keys["\x1b[1;5C"] = Key(KeyType.KeyCtrlRight)
    keys["\x1b[1;5D"] = Key(KeyType.KeyCtrlLeft)
    keys["\x1b[Oa"] = Key(KeyType.KeyCtrlUp, alt=True)
    keys["\x1b[Ob"] = Key(KeyType.KeyCtrlDown, alt=True)
    keys["\x1b[Oc"] = Key(KeyType.KeyCtrlRight, alt=True)
    keys["\x1b[Od"] = Key(KeyType.KeyCtrlLeft, alt=True)
    keys["\x1b[1;6A"] = Key(KeyType.KeyCtrlShiftUp)
    keys["\x1b[1;6B"] = Key(KeyType.KeyCtrlShiftDown)
    keys["\x1b[1;6C"] = Key(KeyType.KeyCtrlShiftRight)
    keys["\x1b[1;6D"] = Key(KeyType.KeyCtrlShiftLeft)
    keys["\x1b[1;7A"] = Key(KeyType.KeyCtrlUp, alt=True)
    keys["\x1b[1;7B"] = Key(KeyType.KeyCtrlDown, alt=True)
    keys["\x1b[1;7C"] = Key(KeyType.KeyCtrlRight, alt=True)
    keys["\x1b[1;7D"] = Key(KeyType.KeyCtrlLeft, alt=True)
    keys["\x1b[1;8A"] = Key(KeyType.KeyCtrlShiftUp, alt=True)
    keys["\x1b[1;8B"] = Key(KeyType.KeyCtrlShiftDown, alt=True)
    keys["\x1b[1;8C"] = Key(KeyType.KeyCtrlShiftRight, alt=True)
    keys["\x1b[1;8D"] = Key(KeyType.KeyCtrlShiftLeft, alt=True)

    # Misc. keys
    keys["\x1b[Z"] = Key(KeyType.KeyShiftTab)
    keys["\x1b[2~"] = Key(KeyType.KeyInsert)
    keys["\x1b[3~"] = Key(KeyType.KeyDelete)
    keys["\x1b[5~"] = Key(KeyType.KeyPgUp)
    keys["\x1b[6~"] = Key(KeyType.KeyPgDown)
    keys["\x1b[1~"] = Key(KeyType.KeyHome)
    keys["\x1b[H"] = Key(KeyType.KeyHome)
    keys["\x1b[1;3H"] = Key(KeyType.KeyHome, alt=True)
    keys["\x1b[1;5H"] = Key(KeyType.KeyCtrlHome)
    keys["\x1b[1;7H"] = Key(KeyType.KeyCtrlHome, alt=True)
    keys["\x1b[1;2H"] = Key(KeyType.KeyShiftHome)
    keys["\x1b[1;4H"] = Key(KeyType.KeyShiftHome, alt=True)
    keys["\x1b[1;6H"] = Key(KeyType.KeyCtrlShiftHome)
    keys["\x1b[1;8H"] = Key(KeyType.KeyCtrlShiftHome, alt=True)
    keys["\x1b[4~"] = Key(KeyType.KeyEnd)
    keys["\x1b[F"] = Key(KeyType.KeyEnd)
    keys["\x1b[1;3F"] = Key(KeyType.KeyEnd, alt=True)
    keys["\x1b[1;5F"] = Key(KeyType.KeyCtrlEnd)
    keys["\x1b[1;7F"] = Key(KeyType.KeyCtrlEnd, alt=True)
    keys["\x1b[1;2F"] = Key(KeyType.KeyShiftEnd)
    keys["\x1b[1;4F"] = Key(KeyType.KeyShiftEnd, alt=True)
    keys["\x1b[1;6F"] = Key(KeyType.KeyCtrlShiftEnd)
    keys["\x1b[1;8F"] = Key(KeyType.KeyCtrlShiftEnd, alt=True)
    keys["\x1b[7~"] = Key(KeyType.KeyHome)
    keys["\x1b[7^"] = Key(KeyType.KeyCtrlHome)
    keys["\x1b[7$"] = Key(KeyType.KeyShiftHome)
    keys["\x1b[7@"] = Key(KeyType.KeyCtrlShiftHome)
    keys["\x1b[8~"] = Key(KeyType.KeyEnd)
    keys["\x1b[8^"] = Key(KeyType.KeyCtrlEnd)
    keys["\x1b[8$"] = Key(KeyType.KeyShiftEnd)
    keys["\x1b[8@"] = Key(KeyType.KeyCtrlShiftEnd)
    keys["\x1b[2;3~"] = Key(KeyType.KeyInsert, alt=True)
    keys["\x1b[3;3~"] = Key(KeyType.KeyDelete, alt=True)
    keys["\x1b[5;3~"] = Key(KeyType.KeyPgUp, alt=True)
    keys["\x1b[6;3~"] = Key(KeyType.KeyPgDown, alt=True)
    keys["\x1b[1;5A"] = Key(KeyType.KeyCtrlUp)
    keys["\x1b[1;5B"] = Key(KeyType.KeyCtrlDown)
    keys["\x1b[1;5C"] = Key(KeyType.KeyCtrlRight)
    keys["\x1b[1;5D"] = Key(KeyType.KeyCtrlLeft)
    keys["\x1b[1;6A"] = Key(KeyType.KeyCtrlShiftUp)
    keys["\x1b[1;6B"] = Key(KeyType.KeyCtrlShiftDown)
    keys["\x1b[1;6C"] = Key(KeyType.KeyCtrlShiftRight)
    keys["\x1b[1;6D"] = Key(KeyType.KeyCtrlShiftLeft)
    keys["\x1b[1;7A"] = Key(KeyType.KeyCtrlUp, alt=True)
    keys["\x1b[1;7B"] = Key(KeyType.KeyCtrlDown, alt=True)
    keys["\x1b[1;7C"] = Key(KeyType.KeyCtrlRight, alt=True)
    keys["\x1b[1;7D"] = Key(KeyType.KeyCtrlLeft, alt=True)
    keys["\x1b[1;8A"] = Key(KeyType.KeyCtrlShiftUp, alt=True)
    keys["\x1b[1;8B"] = Key(KeyType.KeyCtrlShiftDown, alt=True)
    keys["\x1b[1;8C"] = Key(KeyType.KeyCtrlShiftRight, alt=True)
    keys["\x1b[1;8D"] = Key(KeyType.KeyCtrlShiftLeft, alt=True)
    keys["\x1b[Z"] = Key(KeyType.KeyShiftTab)
    keys["\x1b[2~"] = Key(KeyType.KeyInsert)
    keys["\x1b[3;2~"] = Key(KeyType.KeyInsert, alt=True)
    keys["\x1b[3~"] = Key(KeyType.KeyDelete)
    keys["\x1b[3;3~"] = Key(KeyType.KeyDelete, alt=True)
    keys["\x1b[5~"] = Key(KeyType.KeyPgUp)
    keys["\x1b[5;3~"] = Key(KeyType.KeyPgUp, alt=True)
    keys["\x1b[5;5~"] = Key(KeyType.KeyCtrlPgUp)
    keys["\x1b[5^"] = Key(KeyType.KeyCtrlPgUp)
    keys["\x1b[5;7~"] = Key(KeyType.KeyCtrlPgUp, alt=True)
    keys["\x1b[6~"] = Key(KeyType.KeyPgDown)
    keys["\x1b[6;3~"] = Key(KeyType.KeyPgDown, alt=True)
    keys["\x1b[6;5~"] = Key(KeyType.KeyCtrlPgDown)
    keys["\x1b[6^"] = Key(KeyType.KeyCtrlPgDown)
    keys["\x1b[6;7~"] = Key(KeyType.KeyCtrlPgDown, alt=True)
    keys["\x1b[1~"] = Key(KeyType.KeyHome)
    keys["\x1b[H"] = Key(KeyType.KeyHome)
    keys["\x1b[1;3H"] = Key(KeyType.KeyHome, alt=True)
    keys["\x1b[1;5H"] = Key(KeyType.KeyCtrlHome)
    keys["\x1b[1;7H"] = Key(KeyType.KeyCtrlHome, alt=True)
    keys["\x1b[1;2H"] = Key(KeyType.KeyShiftHome)
    keys["\x1b[1;4H"] = Key(KeyType.KeyShiftHome, alt=True)
    keys["\x1b[1;6H"] = Key(KeyType.KeyCtrlShiftHome)
    keys["\x1b[1;8H"] = Key(KeyType.KeyCtrlShiftHome, alt=True)
    keys["\x1b[4~"] = Key(KeyType.KeyEnd)
    keys["\x1b[F"] = Key(KeyType.KeyEnd)
    keys["\x1b[1;3F"] = Key(KeyType.KeyEnd, alt=True)
    keys["\x1b[1;5F"] = Key(KeyType.KeyCtrlEnd)
    keys["\x1b[1;7F"] = Key(KeyType.KeyCtrlEnd, alt=True)
    keys["\x1b[1;2F"] = Key(KeyType.KeyShiftEnd)
    keys["\x1b[1;4F"] = Key(KeyType.KeyShiftEnd, alt=True)
    keys["\x1b[1;6F"] = Key(KeyType.KeyCtrlShiftEnd)
    keys["\x1b[1;8F"] = Key(KeyType.KeyCtrlShiftEnd, alt=True)
    keys["\x1b[7~"] = Key(KeyType.KeyHome)
    keys["\x1b[7^"] = Key(KeyType.KeyCtrlHome)
    keys["\x1b[7$"] = Key(KeyType.KeyShiftHome)
    keys["\x1b[7@"] = Key(KeyType.KeyCtrlShiftHome)
    keys["\x1b[8~"] = Key(KeyType.KeyEnd)
    keys["\x1b[8^"] = Key(KeyType.KeyCtrlEnd)
    keys["\x1b[8$"] = Key(KeyType.KeyShiftEnd)
    keys["\x1b[8@"] = Key(KeyType.KeyCtrlShiftEnd)

    # Function keys, Linux console
    keys["\x1b[[A"] = Key(KeyType.KeyF1)  # linux console
    keys["\x1b[[B"] = Key(KeyType.KeyF2)  # linux console
    keys["\x1b[[C"] = Key(KeyType.KeyF3)  # linux console
    keys["\x1b[[D"] = Key(KeyType.KeyF4)  # linux console
    keys["\x1b[[E"] = Key(KeyType.KeyF5)  # linux console

    # Function keys, X11
    keys["\x1bOP"] = Key(KeyType.KeyF1)  # vt100, xterm
    keys["\x1bOQ"] = Key(KeyType.KeyF2)  # vt100, xterm
    keys["\x1bOR"] = Key(KeyType.KeyF3)  # vt100, xterm
    keys["\x1bOS"] = Key(KeyType.KeyF4)  # vt100, xterm

    keys["\x1b[1;3P"] = Key(KeyType.KeyF1, alt=True)  # vt100, xterm
    keys["\x1b[1;3Q"] = Key(KeyType.KeyF2, alt=True)  # vt100, xterm
    keys["\x1b[1;3R"] = Key(KeyType.KeyF3, alt=True)  # vt100, xterm
    keys["\x1b[1;3S"] = Key(KeyType.KeyF4, alt=True)  # vt100, xterm

    keys["\x1b[11~"] = Key(KeyType.KeyF1)  # urxvt
    keys["\x1b[12~"] = Key(KeyType.KeyF2)  # urxvt
    keys["\x1b[13~"] = Key(KeyType.KeyF3)  # urxvt
    keys["\x1b[14~"] = Key(KeyType.KeyF4)  # urxvt

    keys["\x1b[15~"] = Key(KeyType.KeyF5)  # vt100, xterm, also urxvt

    keys["\x1b[15;3~"] = Key(KeyType.KeyF5, alt=True)  # vt100, xterm, also urxvt

    keys["\x1b[17~"] = Key(KeyType.KeyF6)  # vt100, xterm, also urxvt
    keys["\x1b[18~"] = Key(KeyType.KeyF7)  # vt100, xterm, also urxvt
    keys["\x1b[19~"] = Key(KeyType.KeyF8)  # vt100, xterm, also urxvt
    keys["\x1b[20~"] = Key(KeyType.KeyF9)  # vt100, xterm, also urxvt
    keys["\x1b[21~"] = Key(KeyType.KeyF10)  # vt100, xterm, also urxvt

    keys["\x1b[17;3~"] = Key(KeyType.KeyF6, alt=True)  # vt100, xterm
    keys["\x1b[18;3~"] = Key(KeyType.KeyF7, alt=True)  # vt100, xterm
    keys["\x1b[19;3~"] = Key(KeyType.KeyF8, alt=True)  # vt100, xterm
    keys["\x1b[20;3~"] = Key(KeyType.KeyF9, alt=True)  # vt100, xterm
    keys["\x1b[21;3~"] = Key(KeyType.KeyF10, alt=True)  # vt100, xterm

    keys["\x1b[23~"] = Key(KeyType.KeyF11)  # vt100, xterm, also urxvt
    keys["\x1b[24~"] = Key(KeyType.KeyF12)  # vt100, xterm, also urxvt

    keys["\x1b[23;3~"] = Key(KeyType.KeyF11, alt=True)  # vt100, xterm
    keys["\x1b[24;3~"] = Key(KeyType.KeyF12, alt=True)  # vt100, xterm

    keys["\x1b[1;2P"] = Key(KeyType.KeyF13)
    keys["\x1b[1;2Q"] = Key(KeyType.KeyF14)

    keys["\x1b[25~"] = Key(KeyType.KeyF13)  # vt100, xterm, also urxvt
    keys["\x1b[26~"] = Key(KeyType.KeyF14)  # vt100, xterm, also urxvt

    keys["\x1b[25;3~"] = Key(KeyType.KeyF13, alt=True)  # vt100, xterm
    keys["\x1b[26;3~"] = Key(KeyType.KeyF14, alt=True)  # vt100, xterm

    keys["\x1b[1;2R"] = Key(KeyType.KeyF15)
    keys["\x1b[1;2S"] = Key(KeyType.KeyF16)

    keys["\x1b[28~"] = Key(KeyType.KeyF15)  # vt100, xterm, also urxvt
    keys["\x1b[29~"] = Key(KeyType.KeyF16)  # vt100, xterm, also urxvt

    keys["\x1b[28;3~"] = Key(KeyType.KeyF15, alt=True)  # vt100, xterm
    keys["\x1b[29;3~"] = Key(KeyType.KeyF16, alt=True)  # vt100, xterm

    keys["\x1b[15;2~"] = Key(KeyType.KeyF17)
    keys["\x1b[17;2~"] = Key(KeyType.KeyF18)
    keys["\x1b[18;2~"] = Key(KeyType.KeyF19)
    keys["\x1b[19;2~"] = Key(KeyType.KeyF20)

    keys["\x1b[31~"] = Key(KeyType.KeyF17)
    keys["\x1b[32~"] = Key(KeyType.KeyF18)
    keys["\x1b[33~"] = Key(KeyType.KeyF19)
    keys["\x1b[34~"] = Key(KeyType.KeyF20)

    # Powershell sequences.
    keys["\x1bOA"] = Key(KeyType.KeyUp, alt=False)
    keys["\x1bOB"] = Key(KeyType.KeyDown, alt=False)
    keys["\x1bOC"] = Key(KeyType.KeyRight, alt=False)
    keys["\x1bOD"] = Key(KeyType.KeyLeft, alt=False)
    return keys


var sequences = build_sequences()
"""sequence mappings."""
