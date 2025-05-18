from collections import Dict
from sys.ffi import os_is_windows


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
struct Key(Movable, Copyable, ExplicitlyCopyable, Stringable, Writable):
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


fn build_key_names() -> Dict[KeyType, String]:
    """Mappings for control keys and other special keys to human friendly string representations.

    Returns:
        A dictionary mapping control keys and other special keys to human friendly string representations.
    """
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
"""Mappings for control keys and other special keys to human friendly string representations."""


fn build_sequences() -> Dict[String, Key]:
    """Mappings for escape sequences to key presses.

    Control keys.

    Returns:
        A dictionary mapping escape sequences to `Key` objects.

    #### Notes:
    - https://en.wikipedia.org/wiki/C0_and_C1_control_codes
    """
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
"""Mappings for escape sequences to key presses."""
