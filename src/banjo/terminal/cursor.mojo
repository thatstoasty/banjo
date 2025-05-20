# import mist
from banjo.terminal.sgr import CSI, OSC, BEL, _write_sequence_to_stdout

# Cursor positioning.
alias ERASE_DISPLAY = CSI + "2J"
"""Clears the visible portion of the terminal `CSI + J + 2 = \\x1b[2J`."""
alias SAVE_CURSOR_POSITION = CSI + "s"
"""Saves the cursor position `CSI + s = \\x1b[s`."""
alias RESTORE_CURSOR_POSITION = CSI + "u"
"""Restores the cursor position `CSI + u = \\x1b[u`."""

# Explicit values for EraseLineSeq.
alias CLEAR_LINE_RIGHT = CSI + "0K"
"""Clears the line to the right of the cursor `CSI + 0 + K = \\x1b[0K`."""
alias CLEAR_LINE_LEFT = CSI + "1K"
"""Clears the line to the left of the cursor `CSI + 1 + K = \\x1b[1K`."""
alias CLEAR_LINE = CSI + "2K"
"""Clears the entire line `CSI + 2 + K = \\x1b[2K`."""

# Session
alias HIDE_CURSOR = CSI + "?25l"
"""Hide the cursor `CSI + ?25 + l = \\x1b[?25l`."""
alias SHOW_CURSOR = CSI + "?25h"
"""Show the cursor `CSI + ?25 + h = \\x1b[?25h`."""

# NOTE: Why UInt16? It's a best guess at how many lines a terminal can feasibly have.
# Are you going to have 65535 lines or columns in your terminal? Probably not.
# But if it proves to be an issue in the future, I can change it.


fn move_cursor_sequence(row: UInt16, column: UInt16) -> String:
    """Returns ANSI sequence, which if written to stdout, will move the cursor to a given position.

    Args:
        row: The row to move to.
        column: The column to move to.
    """
    return String(CSI, row, ";", column, "H")


fn move_cursor(row: UInt16, column: UInt16):
    """Moves the cursor to a given position.

    Args:
        row: The row to move to.
        column: The column to move to.
    """
    _write_sequence_to_stdout(CSI, row, ";", column, "H")


fn clear_screen():
    """Clears the visible portion of the terminal."""
    _write_sequence_to_stdout(ERASE_DISPLAY)
    move_cursor(1, 1)


fn hide_cursor():
    """TODO: Show and Hide cursor don't seem to work ATM. HideCursor hides the cursor."""
    _write_sequence_to_stdout(HIDE_CURSOR)


fn show_cursor():
    """Shows the cursor."""
    _write_sequence_to_stdout(SHOW_CURSOR)


fn save_cursor_position():
    """Saves the cursor position."""
    _write_sequence_to_stdout(SAVE_CURSOR_POSITION)


fn restore_cursor_position():
    """Restores a saved cursor position."""
    _write_sequence_to_stdout(RESTORE_CURSOR_POSITION)


fn cursor_up_sequence(n: UInt16) -> String:
    """Returns an ANSI Sequence, which if printed to stdout, will move the cursor up `n` number of lines.

    Args:
        n: The number of lines to move up.
    """
    return String(CSI, n, "A")


fn cursor_up(n: UInt16):
    """Moves the cursor up a given number of lines.

    Args:
        n: The number of lines to move up.
    """
    _write_sequence_to_stdout(CSI, n, "A")


fn cursor_down_sequence(n: UInt16) -> String:
    """Returns an ANSI Sequence, which if printed to stdout, will move the cursor down `n` number of lines.

    Args:
        n: The number of lines to move down.
    """
    return String(CSI, n, "B")


fn cursor_down(n: UInt16):
    """Moves the cursor down a given number of lines.

    Args:
        n: The number of lines to move down.
    """
    _write_sequence_to_stdout(CSI, n, "B")


fn cursor_forward_sequence(n: UInt16) -> String:
    """Returns an ANSI Sequence, which if printed to stdout, will move the cursor forward `n` number of cells.

    Args:
        n: The number of cells to move forward.
    """
    return String(CSI, n, "C")


fn cursor_forward(n: UInt16):
    """Moves the cursor forward a given number of cells.

    Args:
        n: The number of cells to move forward.
    """
    _write_sequence_to_stdout(CSI, n, "C")


fn cursor_back_sequence(n: UInt16) -> String:
    """Returns an ANSI Sequence, which if printed to stdout, will move the cursor backwards a given number of cells.

    Args:
        n: The number of cells to move back.
    """
    return String(CSI, n, "D")


fn cursor_back(n: UInt16) -> None:
    """Moves the cursor backwards a given number of cells.

    Args:
        n: The number of cells to move back.
    """
    _write_sequence_to_stdout(CSI, n, "D")


fn cursor_next_line_sequence(n: UInt16) -> String:
    """Returns an ANSI Sequence, which if printed to stdout, will move the cursor down a given number
    of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move down.
    """
    return String(CSI, n, "E")


fn cursor_next_line(n: UInt16) -> None:
    """Moves the cursor down a given number of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move down.
    """
    _write_sequence_to_stdout(CSI, n, "E")


fn cursor_prev_line_sequence(n: UInt16) -> String:
    """Returns an ANSI Sequence, which if printed to stdout, will move the cursor up a given number of lines
    and places it at the beginning of the line.

    Args:
        n: The number of lines to move back.
    """
    return String(CSI, n, "F")


fn cursor_prev_line(n: UInt16) -> None:
    """Moves the cursor up a given number of lines and places it at the beginning of the line.

    Args:
        n: The number of lines to move back.
    """
    _write_sequence_to_stdout(CSI, n, "F")


fn clear_line() -> None:
    """Clears the current line."""
    _write_sequence_to_stdout(CLEAR_LINE)


fn clear_line_left() -> None:
    """Clears the line to the left of the cursor."""
    _write_sequence_to_stdout(CLEAR_LINE_LEFT)


fn clear_line_right() -> None:
    """Clears the line to the right of the cursor."""
    _write_sequence_to_stdout(CLEAR_LINE_RIGHT)


fn clear_lines(n: UInt16) -> None:
    """Clears a given number of lines.

    Args:
        n: The number of lines to CLEAR.
    """
    var movement = (cursor_up_sequence(1) + CLEAR_LINE) * Int(n)
    _write_sequence_to_stdout(CLEAR_LINE + movement)


# fn set_cursor_color(color: mist.AnyColor) -> None:
#     """Sets the cursor color.

#     Args:
#         color: The color to set.
#     """
#     _write_sequence_to_stdout(OSC, "12;", color.sequence[True](), BEL)
