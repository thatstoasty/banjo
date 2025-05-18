from banjo.termios import Termios, tcgetattr, tcsetattr, set_raw, set_cbreak, WhenOption
from banjo.termios.c import LocalFlag
from banjo.terminal.cursor import (
    move_cursor,
    clear_screen,
    hide_cursor,
    show_cursor,
    save_cursor_position,
    restore_cursor_position,
    cursor_up,
    cursor_down,
    cursor_forward,
    cursor_back,
    clear_lines,
    set_cursor_color,
)
from banjo.terminal.screen import (
    reset_terminal,
    set_foreground_color,
    set_background_color,
    restore_screen,
    save_screen,
    alt_screen,
    exit_alt_screen,
    change_scrolling_region,
    set_window_title,
)
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
struct Direction:
    """Direction values for cursor movement."""

    var value: UInt8
    alias UP = Self(0)
    alias DOWN = Self(1)
    alias LEFT = Self(2)
    alias RIGHT = Self(3)
    alias UP_LEFT = Self(4)
    alias UP_RIGHT = Self(5)
    alias DOWN_LEFT = Self(6)
    alias DOWN_RIGHT = Self(7)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value

    fn __str__(self) -> String:
        return String(self.value)


@value
@register_passable("trivial")
struct TTY[mode: Mode = Mode.RAW]():
    """A context manager for terminal state."""

    var fd: FileDescriptor
    """File descriptor for the terminal."""
    var original_state: Termios
    """Original state of the terminal."""
    var state: Termios
    """Current state of the terminal."""

    var cursor_hidden: Bool
    """Flag indicating if the cursor is hidden."""

    fn __init__(out self) raises:
        self.fd = stdin
        self.original_state = tcgetattr(self.fd)
        self.state = self.original_state
        self.cursor_hidden = False

        @parameter
        if mode == Mode.RAW:
            self.state = set_raw(self.fd)
        elif mode == Mode.CBREAK:
            self.state = set_cbreak(self.fd)

    fn restore_original_state(mut self, when: WhenOption = WhenOption.TCSADRAIN) raises:
        """Restore the original terminal state."""
        tcsetattr(self.fd, when, self.original_state)

    fn __enter__(self) -> Self:
        """Enter the context manager and set the terminal to the desired mode."""
        return self

    fn __exit__(mut self) raises:
        """Restore the original terminal state."""
        self.restore_original_state()

    fn set_attribute(mut self, optional_actions: WhenOption) raises:
        """Set the terminal attributes."""
        tcsetattr(self.fd, optional_actions, self.state)

    fn disable_echo(mut self) raises:
        self.state.c_lflag &= ~LocalFlag.ECHO.value
        self.set_attribute(WhenOption.TCSADRAIN)

    fn enable_echo(mut self) raises:
        self.state.c_lflag |= LocalFlag.ECHO.value
        self.set_attribute(WhenOption.TCSADRAIN)

    fn enable_canonical_mode(mut self) raises:
        self.state.c_lflag |= LocalFlag.ICANON.value
        self.set_attribute(WhenOption.TCSADRAIN)

    fn disable_canonical_mode(mut self) raises:
        self.state.c_lflag &= ~LocalFlag.ICANON.value
        self.set_attribute(WhenOption.TCSADRAIN)

    fn move_cursor(self, x: UInt16, y: UInt16) -> None:
        """Move the cursor to the specified position."""
        move_cursor(x, y)

    fn clear(self) -> None:
        """Clear the terminal."""
        clear_screen()

    fn hide_cursor(mut self) -> None:
        """Hide the cursor."""
        hide_cursor()
        self.cursor_hidden = True

    fn show_cursor(mut self) -> None:
        """Show the cursor."""
        show_cursor()
        self.cursor_hidden = False

    fn move_cursor[direction: Direction](self, n: UInt16) -> None:
        """Move the cursor in the specified direction."""

        @parameter
        if direction == Direction.UP:
            cursor_up(n)
        elif direction == Direction.DOWN:
            cursor_down(n)
        elif direction == Direction.LEFT:
            cursor_forward(n)
        elif direction == Direction.RIGHT:
            cursor_back(n)
        elif direction == Direction.UP_LEFT:
            cursor_up(n)
            cursor_back(n)
        elif direction == Direction.UP_RIGHT:
            cursor_up(n)
            cursor_forward(n)
        elif direction == Direction.DOWN_LEFT:
            cursor_down(n)
            cursor_back(n)
        elif direction == Direction.DOWN_RIGHT:
            cursor_down(n)
            cursor_forward(n)

    fn set_cursor_color(self, color: mist.AnyColor) -> None:
        """Set the cursor color."""
        set_cursor_color(color)

    fn save_cursor_position(self) -> None:
        """Save the current cursor position."""
        save_cursor_position()

    fn restore_cursor_position(self) -> None:
        """Restore the saved cursor position."""
        restore_cursor_position()

    fn clear_lines(self, n: UInt16) -> None:
        """Clear the specified number of lines."""
        clear_lines(n)

    fn set_foreground_color(self, color: mist.AnyColor) -> None:
        """Set the foreground color."""
        set_foreground_color(color)

    fn set_background_color(self, color: mist.AnyColor) -> None:
        """Set the background color."""
        set_background_color(color)

    fn restore_screen(self) -> None:
        """Restore the screen to its previous state."""
        restore_screen()

    fn save_screen(self) -> None:
        """Save the current screen state."""
        save_screen()

    fn alt_screen(self) -> None:
        """Switch to the alternate screen buffer."""
        alt_screen()

    fn exit_alt_screen(self) -> None:
        """Exit the alternate screen buffer."""
        exit_alt_screen()

    fn change_scrolling_region(self, top: UInt16, bottom: UInt16) -> None:
        """Change the scrolling region of the terminal."""
        change_scrolling_region(top, bottom)

    fn set_window_title(self, title: StringSlice) -> None:
        """Set the terminal window title."""
        set_window_title(title)
