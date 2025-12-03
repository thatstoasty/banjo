from hashlib import Hasher
from sys.ffi import CompilationTarget


@register_passable("trivial")
struct KeyType(ImplicitlyCopyable, KeyElement, Stringable, Writable):
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
    comptime NUL: KeyType = 0
    """null, \\0"""
    comptime SOH: KeyType = 1
    """start of heading."""
    comptime STX: KeyType = 2
    """start of text."""
    comptime ETX: KeyType = 3
    """break, ctrl+c."""
    comptime EOT: KeyType = 4
    """end of transmission."""
    comptime ENQ: KeyType = 5
    """enquiry."""
    comptime ACK: KeyType = 6
    """acknowledge."""
    comptime BEL: KeyType = 7
    """bell, \\a"""
    comptime BS: KeyType = 8
    """backspace."""
    comptime HT: KeyType = 9
    """horizontal tabulation, \\t."""
    comptime LF: KeyType = 10
    """line feed, \\n."""
    comptime VT: KeyType = 11
    """vertical tabulation, \\v."""
    comptime FF: KeyType = 12
    """form feed, \\f."""
    comptime CR: KeyType = 13
    """carriage return, \\r."""
    comptime SO: KeyType = 14
    """shift out."""
    comptime SI: KeyType = 15
    """shift in."""
    comptime DLE: KeyType = 16
    """data link escape."""
    comptime DC1: KeyType = 17
    """device control one."""
    comptime DC2: KeyType = 18
    """device control two."""
    comptime DC3: KeyType = 19
    """device control three."""
    comptime DC4: KeyType = 20
    """device control four."""
    comptime NAK: KeyType = 21
    """negative acknowledge."""
    comptime SYN: KeyType = 22
    """synchronous idle."""
    comptime ETB: KeyType = 23
    """end of transmission block."""
    comptime CAN: KeyType = 24
    """cancel."""
    comptime EM: KeyType = 25
    """end of medium."""
    comptime SUB: KeyType = 26
    """substitution."""
    comptime ESC: KeyType = 27
    """escape, \\e."""
    comptime FS: KeyType = 28
    """file separator."""
    comptime GS: KeyType = 29
    """group separator."""
    comptime RS: KeyType = 30
    """record separator."""
    comptime US: KeyType = 31
    """unit separator."""
    comptime DEL: KeyType = 127
    """delete. on most systems this is mapped to backspace, I hear."""

    # Control key aliases.
    comptime Null: KeyType = Self.NUL
    comptime Break: KeyType = Self.ETX
    comptime Enter: KeyType = Self.LF
    comptime Backspace: KeyType = Self.DEL
    comptime Tab: KeyType = Self.HT
    comptime Esc: KeyType = Self.ESC
    comptime Escape: KeyType = Self.ESC
    comptime CtrlAt: KeyType = Self.NUL  # ctrl+@
    comptime CtrlA: KeyType = Self.SOH
    comptime CtrlB: KeyType = Self.STX
    comptime CtrlC: KeyType = Self.ETX
    comptime CtrlD: KeyType = Self.EOT
    comptime CtrlE: KeyType = Self.ENQ
    comptime CtrlF: KeyType = Self.ACK
    comptime CtrlG: KeyType = Self.BEL
    comptime CtrlH: KeyType = Self.BS
    comptime CtrlI: KeyType = Self.HT
    comptime CtrlJ: KeyType = Self.LF
    comptime CtrlK: KeyType = Self.VT
    comptime CtrlL: KeyType = Self.FF
    comptime CtrlM: KeyType = Self.CR
    comptime CtrlN: KeyType = Self.SO
    comptime CtrlO: KeyType = Self.SI
    comptime CtrlP: KeyType = Self.DLE
    comptime CtrlQ: KeyType = Self.DC1
    comptime CtrlR: KeyType = Self.DC2
    comptime CtrlS: KeyType = Self.DC3
    comptime CtrlT: KeyType = Self.DC4
    comptime CtrlU: KeyType = Self.NAK
    comptime CtrlV: KeyType = Self.SYN
    comptime CtrlW: KeyType = Self.ETB
    comptime CtrlX: KeyType = Self.CAN
    comptime CtrlY: KeyType = Self.EM
    comptime CtrlZ: KeyType = Self.SUB
    comptime CtrlOpenBracket: KeyType = Self.ESC  # ctrl+[
    comptime CtrlBackslash: KeyType = Self.FS  # ctrl+\
    comptime CtrlCloseBracket: KeyType = Self.GS  # ctrl+]
    comptime CtrlCaret: KeyType = Self.RS  # ctrl+^
    comptime CtrlUnderscore: KeyType = Self.US  # ctrl+_
    comptime CtrlQuestionMark: KeyType = Self.DEL  # ctrl+?

    # Other keys.
    comptime Runes: KeyType = -1
    comptime Up: KeyType = -2
    comptime Down: KeyType = -3
    comptime Right: KeyType = -4
    comptime Left: KeyType = -5
    comptime ShiftTab: KeyType = -6
    comptime Home: KeyType = -7
    comptime End: KeyType = -8
    comptime PgUp: KeyType = -9
    comptime PgDown: KeyType = -10
    comptime CtrlPgUp: KeyType = -11
    comptime CtrlPgDown: KeyType = -12
    comptime Delete: KeyType = -13
    comptime Insert: KeyType = -14
    comptime Space: KeyType = -15
    comptime CtrlUp: KeyType = -16
    comptime CtrlDown: KeyType = -17
    comptime CtrlRight: KeyType = -18
    comptime CtrlLeft: KeyType = -19
    comptime CtrlHome: KeyType = -20
    comptime CtrlEnd: KeyType = -21
    comptime ShiftUp: KeyType = -22
    comptime ShiftDown: KeyType = -23
    comptime ShiftRight: KeyType = -24
    comptime ShiftLeft: KeyType = -25
    comptime ShiftHome: KeyType = -26
    comptime ShiftEnd: KeyType = -27
    comptime CtrlShiftUp: KeyType = -28
    comptime CtrlShiftDown: KeyType = -29
    comptime CtrlShiftLeft: KeyType = -30
    comptime CtrlShiftRight: KeyType = -31
    comptime CtrlShiftHome: KeyType = -32
    comptime CtrlShiftEnd: KeyType = -33
    comptime F1: KeyType = -34
    comptime F2: KeyType = -35
    comptime F3: KeyType = -36
    comptime F4: KeyType = -37
    comptime F5: KeyType = -38
    comptime F6: KeyType = -39
    comptime F7: KeyType = -40
    comptime F8: KeyType = -41
    comptime F9: KeyType = -42
    comptime F10: KeyType = -43
    comptime F11: KeyType = -44
    comptime F12: KeyType = -45
    comptime F13: KeyType = -46
    comptime F14: KeyType = -47
    comptime F15: KeyType = -48
    comptime F16: KeyType = -49
    comptime F17: KeyType = -50
    comptime F18: KeyType = -51
    comptime F19: KeyType = -52
    comptime F20: KeyType = -53

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
        return materialize[KEY_NAMES]().get(self.value, "")

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

    fn write_to[W: Writer, //](self, mut writer: W):
        """Formats the string representation of this type to the provided formatter.

        Parameters:
            W: The formatter to write to.

        Args:
            writer: The formatter to write to.
        """
        writer.write("KeyType(value=", self.value, ")")

    fn __hash__[H: Hasher, //](self, mut hasher: H):
        """Hashes the key type.

        Parameters:
            H: The type of the hasher to use.

        Args:
            hasher: The hasher to use.
        """
        hasher.update(self.value)


struct Key(Copyable, EqualityComparable, Movable, Stringable, Writable):
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

    fn write_to[W: Writer, //](self, mut writer: W):
        """Formats the string representation of this type to the provided formatter.

        Parameters:
            W: The formatter to write to.

        Args:
            writer: The formatter to write to.
        """
        var key_names = materialize[KEY_NAMES]()
        if self.type == KeyType.Runes:
            if self.alt:
                writer.write("alt+")
            if self.paste:
                writer.write("[")
            writer.write(self.text)
            if self.paste:
                writer.write("]")
            return

        var key_name = key_names.get(self.type)
        if key_name:
            writer.write(key_name.value())
            return

        var sequences = materialize[SEQUENCES]()
        var sequence = sequences.get(self.text)
        if sequence:
            writer.write(key_names.get(sequence.value().type, ""))
            return

    fn __str__(self) -> String:
        """Returns a string representation of the key.

        Returns:
            A string representation of the key, such as "ctrl+c" or "alt+a".
        """
        return String.write(self)


comptime KEY_NAMES: Dict[KeyType, StaticString] = {
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


comptime SEQUENCES: Dict[String, Key] = {
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
