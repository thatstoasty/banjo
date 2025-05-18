import banjo.termios.c


# TTY when values.
@value
@register_passable("trivial")
struct WhenOption:
    """TTY when values."""

    var value: Int
    alias TCSANOW = Self(0)
    """Change attributes immediately."""
    alias TCSADRAIN = Self(1)
    """Change attributes after transmitting all queued output."""
    alias TCSAFLUSH = Self(2)
    """Change attributes after transmitting all queued output and discarding all queued input."""
    alias TCSASOFT = Self(16)
    """Change attributes without changing the terminal state."""


# TTY flow actions.
@value
@register_passable("trivial")
struct FlowOption:
    """TTY flow values."""

    var value: Int
    alias TCOOFF = Self(1)
    """Suspends output."""
    alias TCOON = Self(2)
    """Transmits a STOP character, which stops the terminal device from transmitting data to the system."""
    alias TCOFLUSH = Self(2)
    """Transmits a START character, which starts the terminal device transmitting data to the system."""
    alias TCIOFLUSH = Self(3)
    """Flushes both data received but not read, and data written but not transmitted."""


# TTY flow actions.
@value
@register_passable("trivial")
struct FlushOption:
    """TTY flow values."""

    var value: Int
    alias TCIFLUSH = Self(0)
    """Flushes data received, but not read."""
    alias TCOFLUSH = Self(1)
    """Flushes data written, but not transmitted."""
    alias TCIOFLUSH = Self(2)
    """Flushes both data received, but not read. And data written, but not transmitted."""


fn tcgetattr(file: FileDescriptor) raises -> c.Termios:
    """Return the tty attributes for file descriptor.
    This is a wrapper around `c.tcgetattr()`.

    Args:
        file: File descriptor.

    Returns:
        Termios struct.
    """
    var termios_p = c.Termios()
    var status = c.tcgetattr(file.value, Pointer(to=termios_p))
    if status != 0:
        raise Error("Failed c.tcgetattr. Status: ", status)

    return termios_p


fn tcsetattr(file: FileDescriptor, optional_actions: WhenOption, mut termios_p: c.Termios) raises -> None:
    """Set the tty attributes for file descriptor `file` from the attributes,
    which is a list like the one returned by c.tcgetattr(). The when argument determines when the attributes are changed:
    This is a wrapper around `c.tcsetattr()`.

    Args:
        file: File descriptor.
        optional_actions: When to change the attributes.
        termios_p: Pointer to Termios struct.

    #### Notes:
    * `WhenOption.TCSANOW`: Change attributes immediately.
    * `WhenOption.TCSADRAIN`: Change attributes after transmitting all queued output.
    * `WhenOption.TCSAFLUSH`: Change attributes after transmitting all queued output and discarding all queued input.
    """
    var status = c.tcsetattr(file.value, optional_actions.value, Pointer(to=termios_p))
    if status != 0:
        var errno = c.get_errno()
        if errno == c.EBADF:
            raise Error("[EBADF] Failed to set tty attributes. The `file` argument is not a valid file descriptor.")
        elif errno == c.ENOTTY:
            raise Error("[ENOTTY] Failed to set tty attributes. The file associated with `file` is not a terminal.")
        else:
            raise Error("[UNKNOWN] Failed to set tty attributes. ERRNO: ", errno)


fn tcsendbreak(file: FileDescriptor, duration: c.c_int) raises -> None:
    """Send a break on file descriptor `file`.
    A zero duration sends a break for 0.25 - 0.5 seconds; a nonzero duration has a system dependent meaning.

    Args:
        file: File descriptor.
        duration: Duration of break.
    """
    var status = c.tcsendbreak(file.value, duration)
    if status != 0:
        var errno = c.get_errno()
        if errno == c.EBADF:
            raise Error(
                "[EBADF] Failed to send break to file descriptor. The `file` argument is not a valid file descriptor."
            )
        elif errno == c.ENOTTY:
            raise Error(
                "[ENOTTY] Failed to send break to file descriptor. The file associated with `file` is not a terminal."
            )
        elif errno == c.EIO:
            raise Error(
                "[EIO] Failed to send break to file descriptor. The process group of the writing process is orphaned,"
                " and the writing process is not ignoring or blocking SIGTTOU."
            )
        else:
            raise Error("[UNKNOWN] Failed to send break to file descriptor. ERRNO: ", errno)


fn tcdrain(file: FileDescriptor) raises -> None:
    """Wait until all output written to the object referred to by `file` has been transmitted.

    Args:
        file: File descriptor.
    """
    var status = c.tcdrain(file.value)
    if status != 0:
        var errno = c.get_errno()
        if errno == c.EBADF:
            raise Error(
                "[EBADF] Failed to wait for output transmission. The `file` argument is not a valid file descriptor."
            )
        elif errno == c.EINTR:
            raise Error("[EINTR] Failed to wait for output transmission. The call was interrupted by a signal.")
        elif errno == c.ENOTTY:
            raise Error(
                "[ENOTTY] Failed to wait for output transmission. The file associated with `file` is not a terminal."
            )
        elif errno == c.EIO:
            raise Error(
                "[EIO] Failed to wait for output transmission. The process group of the writing process is orphaned,"
                " and the writing process is not ignoring or blocking SIGTTOU."
            )
        else:
            raise Error("[UNKNOWN] Failed to wait for output transmission. ERRNO: ", errno)


fn tcflush(file: FileDescriptor, queue_selector: FlushOption) raises -> None:
    """Discard queued data on file descriptor `file`.

    #### The queue selector specifies which queue:
    - `FlushOption.TCIFLUSH` for the input queue
    - `FlushOption.TCOFLUSH` for the output queue
    - `FlushOption.TCIOFLUSH` for both queues.

    Args:
        file: File descriptor.
        queue_selector: Queue selector.
    """
    var status = c.tcflush(file.value, queue_selector.value)
    if status != 0:
        var errno = c.get_errno()
        if errno == c.EBADF:
            raise Error("[EBADF] Failed to flush queued data. The `file` argument is not a valid file descriptor.")
        elif errno == c.EINVAL:
            raise Error("[EINVAL] Failed to flush queued data. The `queue_selector` argument is not a supported value.")
        elif errno == c.ENOTTY:
            raise Error("[ENOTTY] Failed to flush queued data. The file associated with `file` is not a terminal.")
        elif errno == c.EIO:
            raise Error(
                "[EIO] Failed to flush queued data. The process group of the writing process is orphaned, and the"
                " writing process is not ignoring or blocking SIGTTOU."
            )
        else:
            raise Error("[UNKNOWN] Failed to flush queued data. ERRNO: ", errno)


fn tcflow(file: FileDescriptor, action: FlowOption) raises -> None:
    """Suspend or resume input or output on file descriptor `file`.

    Args:
        file: File descriptor.
        action: Action.

    #### Notes:
    * `FlowOption.TCOOFF`: Suspends output.
    * `FlowOption.TCOON`: Restarts suspended output.
    * `FlowOption.TCIOFF`: Transmits a STOP character, which stops the terminal device from transmitting data to the system.
    * `FlowOption.TCION`: Transmits a START character, which starts the terminal device transmitting data to the system.
    """
    var status = c.tcflow(file.value, action.value)
    if status != 0:
        var errno = c.get_errno()
        if errno == c.EBADF:
            raise Error("[EBADF] Failed to suspend or resume I/O. The `file` argument is not a valid file descriptor.")
        elif errno == c.EINVAL:
            raise Error("[EINVAL] Failed to suspend or resume I/O. The `action` argument is not a supported value.")
        elif errno == c.ENOTTY:
            raise Error("[ENOTTY] Failed to suspend or resume I/O. The file associated with `file` is not a terminal.")
        elif errno == c.EIO:
            raise Error(
                "[EIO] Failed to suspend or resume I/O. The process group of the writing process is orphaned, and the"
                " writing process is not ignoring or blocking SIGTTOU."
            )
        else:
            raise Error("[UNKNOWN] Failed to suspend or resume I/O. ERRNO: ", errno)


# Not available from libc
# fn tc_getwinsize(file_descriptor: c.c_int) raises -> winsize:
#     """Return the window size of the terminal associated to file descriptor file_descriptor as a winsize object. The winsize object is a named tuple with four fields: ws_row, ws_col, ws_xpixel, and ws_ypixel.
#     """
#     var winsize_p = winsize()
#     var status = tcgetwinsize(file_descriptor, Pointer(to=winsize_p))
#     if status != 0:
#         raise Error("Failed tcgetwinsize." + String(status))

#     return winsize_p


# fn tc_setwinsize(file_descriptor: c.c_int, winsize: Int32) raises -> Int32:
#     var status = tcsetwinsize(file_descriptor, winsize)
#     if status != 0:
#         raise Error("Failed tcsetwinsize." + String(status))

#     return status
