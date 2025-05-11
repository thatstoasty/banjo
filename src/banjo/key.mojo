from sys.ffi import os_is_windows


@value
@register_passable("trivial")
struct KeyType(Copyable, KeyElement, Movable, Stringable):
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
    """The integer value representing the key type."""
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
        """Constructs a new `KeyType` instance.

        Args:
            value: The integer value representing the key type.
        """
        self.value = value

    fn __str__(self) -> String:
        """Returns a string representation of the key type.

        Returns:
            A string representation of the key type, such as "ctrl+c" or "alt+a".
        """
        return KEY_NAMES.get(self.value, "")

    fn __eq__(self, other: KeyType) -> Bool:
        """Checks if this key type is equal to another key type.

        Args:
            other: The other key type to compare with.

        Returns:
            True if the key types are equal, False otherwise.
        """
        return self.value == other.value

    fn __ne__(self, other: KeyType) -> Bool:
        """Checks if this key type is not equal to another key type.

        Args:
            other: The other key type to compare with.

        Returns:
            True if the key types are not equal, False otherwise.
        """
        return self.value != other.value

    fn __hash__(self) -> UInt:
        """Returns a hash of the key type.

        Returns:
            A hash of the key type.
        """
        return hash(self.value)

    fn write_to[W: Writer, //](self, mut writer: W):
        """Formats the string representation of this type to the provided formatter.

        Parameters:
            W: The formatter to write to.

        Args:
            writer: The formatter to write to.
        """
        writer.write("KeyType(value=", self.value, ")")


struct Key(Copyable, ExplicitlyCopyable, Movable, Stringable, Writable):
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
        """Constructs a new `Key` instance.

        Args:
            type: The type of key pressed.
            text: The raw text of the key pressed.
            alt: Whether the alt key was pressed.
            paste: Whether the paste key was pressed.
        """
        self.type = type
        self.text = text
        self.alt = alt
        self.paste = paste

    fn __eq__(self, other: Self) -> Bool:
        """Checks if this key is equal to another key.

        Args:
            other: The other key to compare with.

        Returns:
            True if the keys are equal, False otherwise.
        """
        return (
            self.type == other.type and self.text == other.text and self.alt == other.alt and self.paste == other.paste
        )

    fn __ne__(self, other: Self) -> Bool:
        """Checks if this key is not equal to another key.

        Args:
            other: The other key to compare with.

        Returns:
            True if the keys are not equal, False otherwise.
        """
        return self.type != other.type or self.text != other.text or self.alt != other.alt or self.paste != other.paste

    fn write_to[W: Writer, //](self, mut writer: W):
        """Formats the string representation of this type to the provided formatter.

        Parameters:
            W: The formatter to write to.

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
        """Returns a string representation of the key.

        Returns:
            A string representation of the key, such as "ctrl+c" or "alt+a".
        """
        return String.write(self)


alias KEY_NAMES: Dict[KeyType, String] = {
    KeyType.NUL: "ctrl+@",
    KeyType.SOH: "ctrl+a",
    KeyType.STX: "ctrl+b",
    KeyType.ETX: "ctrl+c",
    KeyType.EOT: "ctrl+d",
    KeyType.ENQ: "ctrl+e",
    KeyType.ACK: "ctrl+f",
    KeyType.BEL: "ctrl+g",
    KeyType.BS: "ctrl+h",
    KeyType.HT: "tab",
    KeyType.LF: "ctrl+j",
    KeyType.VT: "ctrl+k",
    KeyType.FF: "ctrl+l",
    KeyType.CR: "enter",
    KeyType.SO: "ctrl+n",
    KeyType.SI: "ctrl+o",
    KeyType.DLE: "ctrl+p",
    KeyType.DC1: "ctrl+q",
    KeyType.DC2: "ctrl+r",
    KeyType.DC3: "ctrl+s",
    KeyType.DC4: "ctrl+t",
    KeyType.NAK: "ctrl+u",
    KeyType.SYN: "ctrl+v",
    KeyType.ETB: "ctrl+w",
    KeyType.CAN: "ctrl+x",
    KeyType.EM: "ctrl+y",
    KeyType.SUB: "ctrl+z",
    KeyType.ESC: "esc",
    KeyType.FS: "ctrl+\\",
    KeyType.GS: "ctrl+]",
    KeyType.RS: "ctrl+^",
    KeyType.US: "ctrl+_",
    KeyType.DEL: "backspace",
    KeyType.Runes: "runes",
    KeyType.Up: "up",
    KeyType.Down: "down",
    KeyType.Right: "right",
    KeyType.Space: " ",
    KeyType.Left: "left",
    KeyType.ShiftTab: "shift+tab",
    KeyType.Home: "home",
    KeyType.End: "end",
    KeyType.CtrlHome: "ctrl+home",
    KeyType.CtrlEnd: "ctrl+end",
    KeyType.ShiftHome: "shift+home",
    KeyType.ShiftEnd: "shift+end",
    KeyType.CtrlShiftHome: "ctrl+shift+home",
    KeyType.CtrlShiftEnd: "ctrl+shift+end",
    KeyType.PgUp: "pgup",
    KeyType.PgDown: "pgdown",
    KeyType.CtrlPgUp: "ctrl+pgup",
    KeyType.CtrlPgDown: "ctrl+pgdown",
    KeyType.Delete: "delete",
    KeyType.Insert: "insert",
    KeyType.CtrlUp: "ctrl+up",
    KeyType.CtrlDown: "ctrl+down",
    KeyType.CtrlRight: "ctrl+right",
    KeyType.CtrlLeft: "ctrl+left",
    KeyType.ShiftUp: "shift+up",
    KeyType.ShiftDown: "shift+down",
    KeyType.ShiftRight: "shift+right",
    KeyType.ShiftLeft: "shift+left",
    KeyType.CtrlShiftUp: "ctrl+shift+up",
    KeyType.CtrlShiftDown: "ctrl+shift+down",
    KeyType.CtrlShiftLeft: "ctrl+shift+left",
    KeyType.CtrlShiftRight: "ctrl+shift+right",
    KeyType.F1: "f1",
    KeyType.F2: "f2",
    KeyType.F3: "f3",
    KeyType.F4: "f4",
    KeyType.F5: "f5",
    KeyType.F6: "f6",
    KeyType.F7: "f7",
    KeyType.F8: "f8",
    KeyType.F9: "f9",
    KeyType.F10: "f10",
    KeyType.F11: "f11",
    KeyType.F12: "f12",
    KeyType.F13: "f13",
    KeyType.F14: "f14",
    KeyType.F15: "f15",
    KeyType.F16: "f16",
    KeyType.F17: "f17",
    KeyType.F18: "f18",
    KeyType.F19: "f19",
    KeyType.F20: "f20",
}
"""Mappings for control keys and other special keys to human friendly string representations."""


alias SEQUENCES: Dict[String, Key] = {
    "\x1b[A": Key(KeyType.Up),
    "\x1b[B": Key(KeyType.Down),
    "\x1b[C": Key(KeyType.Right),
    "\x1b[D": Key(KeyType.Left),
    "\x1b[1;2A": Key(KeyType.ShiftUp),
    "\x1b[1;2B": Key(KeyType.ShiftDown),
    "\x1b[1;2C": Key(KeyType.ShiftRight),
    "\x1b[1;2D": Key(KeyType.ShiftLeft),
    "\x1b[OA": Key(KeyType.ShiftUp),
    "\x1b[OB": Key(KeyType.ShiftDown),
    "\x1b[OC": Key(KeyType.ShiftRight),
    "\x1b[OD": Key(KeyType.ShiftLeft),
    "\x1b[a": Key(KeyType.ShiftUp),
    "\x1b[b": Key(KeyType.ShiftDown),
    "\x1b[c": Key(KeyType.ShiftRight),
    "\x1b[d": Key(KeyType.ShiftLeft),
    "\x1b[1;3A": Key(KeyType.Up, alt=True),
    "\x1b[1;3B": Key(KeyType.Down, alt=True),
    "\x1b[1;3C": Key(KeyType.Right, alt=True),
    "\x1b[1;3D": Key(KeyType.Left, alt=True),
    "\x1b[1;4A": Key(KeyType.ShiftUp, alt=True),
    "\x1b[1;4B": Key(KeyType.ShiftDown, alt=True),
    "\x1b[1;4C": Key(KeyType.ShiftRight, alt=True),
    "\x1b[1;4D": Key(KeyType.ShiftLeft, alt=True),
    "\x1b[1;5A": Key(KeyType.CtrlUp),
    "\x1b[1;5B": Key(KeyType.CtrlDown),
    "\x1b[1;5C": Key(KeyType.CtrlRight),
    "\x1b[1;5D": Key(KeyType.CtrlLeft),
    "\x1b[Oa": Key(KeyType.CtrlUp, alt=True),
    "\x1b[Ob": Key(KeyType.CtrlDown, alt=True),
    "\x1b[Oc": Key(KeyType.CtrlRight, alt=True),
    "\x1b[Od": Key(KeyType.CtrlLeft, alt=True),
    "\x1b[1;6A": Key(KeyType.CtrlShiftUp),
    "\x1b[1;6B": Key(KeyType.CtrlShiftDown),
    "\x1b[1;6C": Key(KeyType.CtrlShiftRight),
    "\x1b[1;6D": Key(KeyType.CtrlShiftLeft),
    "\x1b[1;7A": Key(KeyType.CtrlUp, alt=True),
    "\x1b[1;7B": Key(KeyType.CtrlDown, alt=True),
    "\x1b[1;7C": Key(KeyType.CtrlRight, alt=True),
    "\x1b[1;7D": Key(KeyType.CtrlLeft, alt=True),
    "\x1b[1;8A": Key(KeyType.CtrlShiftUp, alt=True),
    "\x1b[1;8B": Key(KeyType.CtrlShiftDown, alt=True),
    "\x1b[1;8C": Key(KeyType.CtrlShiftRight, alt=True),
    "\x1b[1;8D": Key(KeyType.CtrlShiftLeft, alt=True),
    # Misc. keys
    "\x1b[Z": Key(KeyType.ShiftTab),
    "\x1b[2~": Key(KeyType.Insert),
    "\x1b[3~": Key(KeyType.Delete),
    "\x1b[5~": Key(KeyType.PgUp),
    "\x1b[6~": Key(KeyType.PgDown),
    "\x1b[1~": Key(KeyType.Home),
    "\x1b[H": Key(KeyType.Home),
    "\x1b[1;3H": Key(KeyType.Home, alt=True),
    "\x1b[1;5H": Key(KeyType.CtrlHome),
    "\x1b[1;7H": Key(KeyType.CtrlHome, alt=True),
    "\x1b[1;2H": Key(KeyType.ShiftHome),
    "\x1b[1;4H": Key(KeyType.ShiftHome, alt=True),
    "\x1b[1;6H": Key(KeyType.CtrlShiftHome),
    "\x1b[1;8H": Key(KeyType.CtrlShiftHome, alt=True),
    "\x1b[4~": Key(KeyType.End),
    "\x1b[F": Key(KeyType.End),
    "\x1b[1;3F": Key(KeyType.End, alt=True),
    "\x1b[1;5F": Key(KeyType.CtrlEnd),
    "\x1b[1;7F": Key(KeyType.CtrlEnd, alt=True),
    "\x1b[1;2F": Key(KeyType.ShiftEnd),
    "\x1b[1;4F": Key(KeyType.ShiftEnd, alt=True),
    "\x1b[1;6F": Key(KeyType.CtrlShiftEnd),
    "\x1b[1;8F": Key(KeyType.CtrlShiftEnd, alt=True),
    "\x1b[7~": Key(KeyType.Home),
    "\x1b[7^": Key(KeyType.CtrlHome),
    "\x1b[7$": Key(KeyType.ShiftHome),
    "\x1b[7@": Key(KeyType.CtrlShiftHome),
    "\x1b[8~": Key(KeyType.End),
    "\x1b[8^": Key(KeyType.CtrlEnd),
    "\x1b[8$": Key(KeyType.ShiftEnd),
    "\x1b[8@": Key(KeyType.CtrlShiftEnd),
    "\x1b[2;3~": Key(KeyType.Insert, alt=True),
    "\x1b[3;3~": Key(KeyType.Delete, alt=True),
    "\x1b[5;3~": Key(KeyType.PgUp, alt=True),
    "\x1b[6;3~": Key(KeyType.PgDown, alt=True),
    "\x1b[1;5A": Key(KeyType.CtrlUp),
    "\x1b[1;5B": Key(KeyType.CtrlDown),
    "\x1b[1;5C": Key(KeyType.CtrlRight),
    "\x1b[1;5D": Key(KeyType.CtrlLeft),
    "\x1b[1;6A": Key(KeyType.CtrlShiftUp),
    "\x1b[1;6B": Key(KeyType.CtrlShiftDown),
    "\x1b[1;6C": Key(KeyType.CtrlShiftRight),
    "\x1b[1;6D": Key(KeyType.CtrlShiftLeft),
    "\x1b[1;7A": Key(KeyType.CtrlUp, alt=True),
    "\x1b[1;7B": Key(KeyType.CtrlDown, alt=True),
    "\x1b[1;7C": Key(KeyType.CtrlRight, alt=True),
    "\x1b[1;7D": Key(KeyType.CtrlLeft, alt=True),
    "\x1b[1;8A": Key(KeyType.CtrlShiftUp, alt=True),
    "\x1b[1;8B": Key(KeyType.CtrlShiftDown, alt=True),
    "\x1b[1;8C": Key(KeyType.CtrlShiftRight, alt=True),
    "\x1b[1;8D": Key(KeyType.CtrlShiftLeft, alt=True),
    "\x1b[Z": Key(KeyType.ShiftTab),
    "\x1b[2~": Key(KeyType.Insert),
    "\x1b[3;2~": Key(KeyType.Insert, alt=True),
    "\x1b[3~": Key(KeyType.Delete),
    "\x1b[3;3~": Key(KeyType.Delete, alt=True),
    "\x1b[5~": Key(KeyType.PgUp),
    "\x1b[5;3~": Key(KeyType.PgUp, alt=True),
    "\x1b[5;5~": Key(KeyType.CtrlPgUp),
    "\x1b[5^": Key(KeyType.CtrlPgUp),
    "\x1b[5;7~": Key(KeyType.CtrlPgUp, alt=True),
    "\x1b[6~": Key(KeyType.PgDown),
    "\x1b[6;3~": Key(KeyType.PgDown, alt=True),
    "\x1b[6;5~": Key(KeyType.CtrlPgDown),
    "\x1b[6^": Key(KeyType.CtrlPgDown),
    "\x1b[6;7~": Key(KeyType.CtrlPgDown, alt=True),
    "\x1b[1~": Key(KeyType.Home),
    "\x1b[H": Key(KeyType.Home),
    "\x1b[1;3H": Key(KeyType.Home, alt=True),
    "\x1b[1;5H": Key(KeyType.CtrlHome),
    "\x1b[1;7H": Key(KeyType.CtrlHome, alt=True),
    "\x1b[1;2H": Key(KeyType.ShiftHome),
    "\x1b[1;4H": Key(KeyType.ShiftHome, alt=True),
    "\x1b[1;6H": Key(KeyType.CtrlShiftHome),
    "\x1b[1;8H": Key(KeyType.CtrlShiftHome, alt=True),
    "\x1b[4~": Key(KeyType.End),
    "\x1b[F": Key(KeyType.End),
    "\x1b[1;3F": Key(KeyType.End, alt=True),
    "\x1b[1;5F": Key(KeyType.CtrlEnd),
    "\x1b[1;7F": Key(KeyType.CtrlEnd, alt=True),
    "\x1b[1;2F": Key(KeyType.ShiftEnd),
    "\x1b[1;4F": Key(KeyType.ShiftEnd, alt=True),
    "\x1b[1;6F": Key(KeyType.CtrlShiftEnd),
    "\x1b[1;8F": Key(KeyType.CtrlShiftEnd, alt=True),
    "\x1b[7~": Key(KeyType.Home),
    "\x1b[7^": Key(KeyType.CtrlHome),
    "\x1b[7$": Key(KeyType.ShiftHome),
    "\x1b[7@": Key(KeyType.CtrlShiftHome),
    "\x1b[8~": Key(KeyType.End),
    "\x1b[8^": Key(KeyType.CtrlEnd),
    "\x1b[8$": Key(KeyType.ShiftEnd),
    "\x1b[8@": Key(KeyType.CtrlShiftEnd),
    # Function keys, Linux console
    "\x1b[[A": Key(KeyType.F1),  # linux console
    "\x1b[[B": Key(KeyType.F2),  # linux console
    "\x1b[[C": Key(KeyType.F3),  # linux console
    "\x1b[[D": Key(KeyType.F4),  # linux console
    "\x1b[[E": Key(KeyType.F5),  # linux console
    # Function keys, X11
    "\x1bOP": Key(KeyType.F1),  # vt100, xterm
    "\x1bOQ": Key(KeyType.F2),  # vt100, xterm
    "\x1bOR": Key(KeyType.F3),  # vt100, xterm
    "\x1bOS": Key(KeyType.F4),  # vt100, xterm
    "\x1b[1;3P": Key(KeyType.F1, alt=True),  # vt100, xterm
    "\x1b[1;3Q": Key(KeyType.F2, alt=True),  # vt100, xterm
    "\x1b[1;3R": Key(KeyType.F3, alt=True),  # vt100, xterm
    "\x1b[1;3S": Key(KeyType.F4, alt=True),  # vt100, xterm
    "\x1b[11~": Key(KeyType.F1),  # urxvt
    "\x1b[12~": Key(KeyType.F2),  # urxvt
    "\x1b[13~": Key(KeyType.F3),  # urxvt
    "\x1b[14~": Key(KeyType.F4),  # urxvt
    "\x1b[15~": Key(KeyType.F5),  # vt100, xterm, also urxvt
    "\x1b[15;3~": Key(KeyType.F5, alt=True),  # vt100, xterm, also urxvt
    "\x1b[17~": Key(KeyType.F6),  # vt100, xterm, also urxvt
    "\x1b[18~": Key(KeyType.F7),  # vt100, xterm, also urxvt
    "\x1b[19~": Key(KeyType.F8),  # vt100, xterm, also urxvt
    "\x1b[20~": Key(KeyType.F9),  # vt100, xterm, also urxvt
    "\x1b[21~": Key(KeyType.F10),  # vt100, xterm, also urxvt
    "\x1b[17;3~": Key(KeyType.F6, alt=True),  # vt100, xterm
    "\x1b[18;3~": Key(KeyType.F7, alt=True),  # vt100, xterm
    "\x1b[19;3~": Key(KeyType.F8, alt=True),  # vt100, xterm
    "\x1b[20;3~": Key(KeyType.F9, alt=True),  # vt100, xterm
    "\x1b[21;3~": Key(KeyType.F10, alt=True),  # vt100, xterm
    "\x1b[23~": Key(KeyType.F11),  # vt100, xterm, also urxvt
    "\x1b[24~": Key(KeyType.F12),  # vt100, xterm, also urxvt
    "\x1b[23;3~": Key(KeyType.F11, alt=True),  # vt100, xterm
    "\x1b[24;3~": Key(KeyType.F12, alt=True),  # vt100, xterm
    "\x1b[1;2P": Key(KeyType.F13),
    "\x1b[1;2Q": Key(KeyType.F14),
    "\x1b[25~": Key(KeyType.F13),  # vt100, xterm, also urxvt
    "\x1b[26~": Key(KeyType.F14),  # vt100, xterm, also urxvt
    "\x1b[25;3~": Key(KeyType.F13, alt=True),  # vt100, xterm
    "\x1b[26;3~": Key(KeyType.F14, alt=True),  # vt100, xterm
    "\x1b[1;2R": Key(KeyType.F15),
    "\x1b[1;2S": Key(KeyType.F16),
    "\x1b[28~": Key(KeyType.F15),  # vt100, xterm, also urxvt
    "\x1b[29~": Key(KeyType.F16),  # vt100, xterm, also urxvt
    "\x1b[28;3~": Key(KeyType.F15, alt=True),  # vt100, xterm
    "\x1b[29;3~": Key(KeyType.F16, alt=True),  # vt100, xterm
    "\x1b[15;2~": Key(KeyType.F17),
    "\x1b[17;2~": Key(KeyType.F18),
    "\x1b[18;2~": Key(KeyType.F19),
    "\x1b[19;2~": Key(KeyType.F20),
    "\x1b[31~": Key(KeyType.F17),
    "\x1b[32~": Key(KeyType.F18),
    "\x1b[33~": Key(KeyType.F19),
    "\x1b[34~": Key(KeyType.F20),
    # Powershell sequences.
    "\x1bOA": Key(KeyType.Up, alt=False),
    "\x1bOB": Key(KeyType.Down, alt=False),
    "\x1bOC": Key(KeyType.Right, alt=False),
    "\x1bOD": Key(KeyType.Left, alt=False),
}
"""Mappings for escape sequences to key presses."""
