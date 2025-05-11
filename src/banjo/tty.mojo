from banjo.termios import Termios, tcgetattr, tcsetattr, set_raw, set_cbreak, WhenOption
from sys import stdin


# TTY State modes
@value
struct Mode:
    var value: String
    alias RAW = Self("RAW")
    alias CBREAK = Self("CBREAK")

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value

    fn __str__(self) -> String:
        return self.value


@value
@register_passable("trivial")
struct TTY[mode: Mode = Mode.RAW]():
    var fd: FileDescriptor
    """File descriptor for the terminal."""
    var original_state: Termios
    """Original state of the terminal."""

    fn __init__(out self) raises:
        self.fd = stdin
        self.original_state = tcgetattr(self.fd)

        @parameter
        if mode == Mode.RAW:
            _ = set_raw(self.fd)
        elif mode == Mode.CBREAK:
            _ = set_cbreak(self.fd)

    fn restore_original_state(mut self) raises:
        tcsetattr(self.fd, WhenOption.TCSADRAIN, self.original_state)

    fn __enter__(self) -> Self:
        return self

    fn __exit__(mut self) raises:
        self.restore_original_state()
