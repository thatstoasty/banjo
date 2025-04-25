import banjo.termios.c
from banjo.termios.terminal import tcgetattr, tcsetattr

# Indices for Termios list.
alias IFLAG = 0
alias OFLAG = 1
alias CFLAG = 2
alias LFLAG = 3
alias ISPEED = 4
alias OSPEED = 5
alias CC = 6


# TTY when values.
@value
@register_passable("trivial")
struct WhenOption:
    """TTY when values."""

    var value: Int
    alias TCSANOW = Self(0)
    alias TCSADRAIN = Self(1)
    alias TCSAFLUSH = Self(2)
    alias TCSASOFT = Self(16)


# TTY flow actions.
@value
@register_passable("trivial")
struct FlowOption:
    """TTY flow values."""

    var value: Int
    alias TCOOFF = Self(1)
    """restarts suspends output."""
    alias TCOON = Self(2)
    """transmits a STOP character, which stops the terminal device from transmitting data to the system."""
    alias TCOFLUSH = Self(2)
    """transmits a START character, which starts the terminal device transmitting data to the system."""
    alias TCIOFLUSH = Self(3)
    """flushes both data received but not read, and data written but not transmitted."""


# TTY flow actions.
@value
@register_passable("trivial")
struct FlushOption:
    """TTY flow values."""

    var value: Int
    alias TCIFLUSH = Self(0)
    """flushes data received but not read."""
    alias TCOFLUSH = Self(1)
    """flushes data written but not transmitted."""
    alias TCIOFLUSH = Self(2)
    """flushes both data received but not read, and data written but not transmitted."""


fn cfmakeraw(mut mode: c.Termios):
    """Make Termios mode raw.
    This is roughly equivalent to CPython's `cfmakeraw()`.

    - Turns off post-processing of output.
    - Disables parity generation and detection.
    - Sets character size to 8 bits.
    - Blocks until 1 byte is read.

    Raw mode sets up the TTY driver to pass every character to the program as it is typed.
    """
    # Clear all POSIX.1-2017 input mode flags.
    # See chapter 11 "General Terminal Interface"
    # of POSIX.1-2017 Base Definitions.
    mode.c_iflag &= ~(
        c.IGNBRK
        | c.BRKINT
        | c.IGNPAR
        | c.PARMRK
        | c.INPCK
        | c.ISTRIP
        | c.INLCR
        | c.IGNCR
        | c.ICRNL
        | c.IXON
        | c.IXANY
        | c.IXOFF
    )

    # Do not post-process output.
    mode.c_oflag &= ~c.OPOST

    # Disable parity generation and detection; clear character size mask;
    # let character size be 8 bits.
    mode.c_cflag &= ~(c.PARENB | c.CSIZE)
    mode.c_cflag |= c.CS8

    # Clear all POSIX.1-2017 local mode flags.
    mode.c_lflag &= ~(c.ECHO | c.ECHOE | c.ECHOK | c.ECHONL | c.ICANON | c.IEXTEN | c.ISIG | c.NOFLSH | c.TOSTOP)

    # POSIX.1-2017, 11.1.7 Non-Canonical Mode Input Processing,
    # Case B: MIN>0, TIME=0
    # A pending read shall block until MIN (here 1) bytes are received,
    # or a signal is received.
    mode.c_cc[c.VMIN] = 1
    mode.c_cc[c.VTIME] = 0


fn cfmakecbreak(mut mode: c.Termios):
    """Make Termios mode cbreak.
    This is roughly equivalent to CPython's `cfmakecbreak()`.

    - Turns off character echoing.
    - Disables canonical input.
    - Blocks until 1 byte is read.

    Args:
        mode: Termios instance to modify in place.
    """
    # Do not echo characters; disable canonical input.
    mode.c_lflag &= ~(c.ECHO | c.ICANON)

    # POSIX.1-2017, 11.1.7 Non-Canonical Mode Input Processing,
    # Case B: MIN>0, TIME=0
    # A pending read shall block until MIN (here 1) bytes are received,
    # or a signal is received.
    mode.c_cc[c.VMIN] = 1
    mode.c_cc[c.VTIME] = 0


fn set_raw(file_descriptor: c.c_int, when: WhenOption = WhenOption.TCSAFLUSH) raises -> c.Termios:
    """Set terminal to raw mode.

    Args:
        file_descriptor: File descriptor of the terminal.
        when: When to apply the changes. Default is TCSAFLUSH.

    Returns:
        The original terminal attributes, and an error if any.
    """
    var mode = tcgetattr(file_descriptor)
    var new = mode.copy()
    cfmakeraw(new)
    tcsetattr(file_descriptor, when, new)

    return mode


fn set_cbreak(file_descriptor: c.c_int, when: WhenOption = WhenOption.TCSAFLUSH) raises -> c.Termios:
    """Set terminal to cbreak mode.

    Args:
        file_descriptor: File descriptor of the terminal.
        when: When to apply the changes. Default is TCSAFLUSH.

    Returns:
        The original terminal attributes, and an error if any.
    """
    var mode = tcgetattr(file_descriptor)
    var new = mode.copy()
    cfmakecbreak(new)
    tcsetattr(file_descriptor, when, new)

    return mode
