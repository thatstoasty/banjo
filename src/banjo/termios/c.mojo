from utils import StaticTuple
from memory import Pointer, UnsafePointer
from sys import external_call, os_is_macos, os_is_windows
from sys.ffi import c_int
from time.time import _CTimeSpec

# C types
alias c_void = UInt8
alias cc_t = UInt8
alias NCCS = Int8
alias tcflag_t = UInt64
alias c_speed_t = UInt64


# control_flags values
alias CREAD = 2048 if os_is_macos() else 128
alias CLOCAL = 32768 if os_is_macos() else 2048
alias PARENB = 4096 if os_is_macos() else 256
alias CSIZE = 768 if os_is_macos() else 48

# local_flags values
alias ICANON = 256 if os_is_macos() else 2
alias ECHO = 8 if os_is_macos() else 1
alias ECHOE = 2 if os_is_macos() else 16
alias ECHOK = 4 if os_is_macos() else 32
alias ECHONL = 16 if os_is_macos() else 64
alias ISIG = 128 if os_is_macos() else 1
alias IEXTEN = 1024 if os_is_macos() else 32768
alias NOFLSH = 2147483648 if os_is_macos() else 128
alias TOSTOP = 4194304 if os_is_macos() else 256

# output_flags values
alias OPOST = 1

# input_flags values
alias INLCR = 64
alias IGNCR = 128
alias ICRNL = 256
alias IGNBRK = 1
"""Ignore BREAK condition on input.
If IGNBRK is set, a BREAK is ignored.  If it is not set
but BRKINT is set, then a BREAK causes the input and
output queues to be flushed, and if the terminal is the
controlling terminal of a foreground process group, it
will cause a SIGINT to be sent to this foreground process
group.  When neither IGNBRK nor BRKINT are set, a BREAK
reads as a null byte ('\\0'), except when PARMRK is set, in
which case it reads as the sequence \\377 \\0 \\0."""
alias BRKINT = 2
alias IGNPAR = 4
"""Ignore framing errors and parity errors.
If this bit is set, input bytes with parity or framing
errors are marked when passed to the program.  This bit is
meaningful only when INPCK is set and IGNPAR is not set.
The way erroneous bytes are marked is with two preceding
bytes, \\377 and \\0.  Thus, the program actually reads
three bytes for one erroneous byte received from the
terminal.  If a valid byte has the value \\377, and ISTRIP
(see below) is not set, the program might confuse it with
the prefix that marks a parity error.  Therefore, a valid
byte \\377 is passed to the program as two bytes, \\377
\\377, in this case."""

# If neither IGNPAR nor PARMRK is set, read a character with
# a parity error or framing error as \0.

alias PARMRK = 8
alias INPCK = 16  # Enable input parity checking.
alias ISTRIP = 32  # Strip off eighth bit.

# alias INLCR  Translate NL to CR on input.

# alias IGNCR  Ignore carriage return on input.

# alias ICRNL  Translate carriage return to newline on input (unless
#         IGNCR is set).

# alias IUCLC  (not in POSIX) Map uppercase characters to lowercase on
#         input.

alias IXON = 512 if os_is_macos() else 1024
"""Enable XON/XOFF flow control on output."""
alias IXANY = 2048
"""(XSI) Typing any character will restart stopped output. (The default is to allow just the START character to restart output.)"""
alias IXOFF = 1024 if os_is_macos() else 4096
"""Enable XON/XOFF flow control on input."""

# alias IMAXBEL
#         (not in POSIX) Ring bell when input queue is full.  Linux
#         does not implement this bit, and acts as if it is always
#         set.

# alias IUTF8 (since Linux 2.6.4)
#         (not in POSIX) Input is UTF8; this allows character-erase
#         to be correctly performed in cooked mode.


# Special Character indexes for control_characters
alias VEOF = 0
"""Signal End-Of-Input `Ctrl-D`"""
alias VEOL = 1
"""Signal End-Of-Line `Disabled`"""
alias VERASE = 3
"""Delete previous character `Backspace`"""
alias VINTR = 8
"""Generate SIGINT `Ctrl-C`"""
alias VKILL = 5
"""Erase current line `Ctrl-U`"""
alias VMIN = 16
"""The MIN value `1`"""
alias VQUIT = 9
"""Generate SIGQUIT `Ctrl-\\`"""
alias VSTART = 12
"""Resume output `Ctrl-Q`"""
alias VSTOP = 13
"""Suspend output `Ctrl-S`"""
alias VSUSP = 10
"""Suspend program `Ctrl-Z`"""
alias VTIME = 17
"""TIME value `0`"""


alias CS8 = 768


@value
@register_passable("trivial")
struct Termios(Movable, Stringable, Writable):
    """Termios libc."""

    var c_iflag: tcflag_t
    """Input mode flags."""
    var c_oflag: tcflag_t
    """Output mode flags."""
    var c_cflag: tcflag_t
    """Control mode flags."""
    var c_lflag: tcflag_t
    """Local mode flags."""
    var c_cc: StaticTuple[cc_t, 20]
    """Special control characters."""
    var c_ispeed: c_speed_t
    """Input baudrate."""
    var c_ospeed: c_speed_t
    """Output baudrate."""

    fn __init__(out self):
        self.c_cc = StaticTuple[cc_t, 20](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        self.c_cflag = 0
        self.c_lflag = 0
        self.c_iflag = 0
        self.c_oflag = 0
        self.c_ispeed = 0
        self.c_ospeed = 0

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes the contents of the buffer to the writer.

        Parameters:
            W: The type of writer to write the contents to.

        Args:
            writer: The writer to write the contents to.
        """
        writer.write(
            "Termios(",
            "c_iflag=",
            self.c_iflag,
            ", ",
            "c_oflag=",
            self.c_oflag,
            ", ",
            "c_cflag=",
            self.c_cflag,
            ", ",
            "c_lflag=",
            self.c_lflag,
            ", ",
            "c_ispeed=",
            self.c_ispeed,
            ", ",
            "c_ospeed=",
            self.c_ospeed,
            ", ",
            "c_cc=(",
        )

        @parameter
        for i in range(20):
            writer.write(self.c_cc[i], ", ")
        writer.write(")")

    fn __str__(self) -> String:
        return String.write(self)


fn tcgetattr(fd: c_int, termios_p: Pointer[Termios]) -> c_int:
    """Libc POSIX `tcgetattr` function.

    Get the parameters associated with the terminal referred to by the file descriptor `fd`.

    Args:
        fd: File descriptor.
        termios_p: Termios struct.

    #### C Function:
    ```c
    int tcgetattr(int fd, struct Termios *termios_p);
    ```

    #### Notes:
    Reference: https://man7.org/linux/man-pages/man3/tcgetattr.3.html
    """
    return external_call["tcgetattr", c_int](fd, termios_p)


fn tcsetattr(fd: c_int, optional_actions: c_int, termios_p: Pointer[Termios]) -> c_int:
    """Libc POSIX `tcsetattr` function.

    Set the parameters associated with the terminal referred to by the file descriptor `fd`.

    Args:
        fd: File descriptor.
        optional_actions: Optional actions.
        termios_p: Termios struct.

    #### C Function:
    ```c
    int tcsetattr(int fd, int optional_actions, const struct Termios *termios_p);
    ```

    #### Notes:
    Reference: https://man7.org/linux/man-pages/man3/tcsetattr.3.html
    """
    return external_call["tcsetattr", c_int](fd, optional_actions, termios_p)


fn tcsendbreak(fd: c_int, duration: c_int) -> c_int:
    """Libc POSIX `tcsendbreak` function.

    Send a break on the terminal referred to by the file descriptor `fd`.

    Args:
        fd: File descriptor.
        duration: Duration.

    #### C Function:
    ```c
    int tcsendbreak(int fd, int duration);
    ```

    #### Notes:
    Reference: https://man7.org/linux/man-pages/man3/tcsendbreak.3.html
    """
    return external_call["tcsendbreak", c_int, c_int, c_int](fd, duration)


fn tcdrain(fd: c_int) -> c_int:
    """Libc POSIX `tcdrain` function.

    Drain the output buffer of the terminal referred to by the file descriptor `fd`.

    Args:
        fd: File descriptor.

    #### C Function:
    ```c
    int tcdrain(int fd);
    ```

    #### Notes:
    Reference: https://man7.org/linux/man-pages/man3/tcdrain.3.html
    """
    return external_call["tcdrain", c_int, c_int](fd)


fn tcflush(fd: c_int, queue_selector: c_int) -> c_int:
    """Libc POSIX `tcflush` function.

    Flush the data transmitted or received on the terminal referred to by the file descriptor `fd`.

    Args:
        fd: File descriptor.
        queue_selector: Queue selector.

    #### C Function:
    ```c
    int tcflush(int fd, int queue_selector);
    ```

    #### Notes:
    Reference: https://man7.org/linux/man-pages/man3/tcflush.3.html
    """
    return external_call["tcflush", c_int, c_int, c_int](fd, queue_selector)


fn tcflow(fd: c_int, action: c_int) -> c_int:
    """Libc POSIX `tcflow` function.

    Suspend or resume transmission on the terminal referred to by the file descriptor `fd`.

    Args:
        fd: File descriptor.
        action: Action.

    #### C Function:
    ```c
    int tcflow(int fd, int action);
    ```

    #### Notes:
    Reference: https://man7.org/linux/man-pages/man3/tcflow.3.html
    """
    return external_call["tcflow", c_int, c_int, c_int](fd, action)


fn cfmakeraw(termios_p: Pointer[Termios]) -> c_void:
    """Libc POSIX `cfmakeraw` function.

    Set the terminal attributes to raw mode.

    Args:
        termios_p: Reference to a Termios struct.

    #### C Function:
    ```c
    void cfmakeraw(struct Termios *termios_p);
    ```

    #### Notes:
    Reference: https://man7.org/linux/man-pages/man3/cfmakeraw.3.html
    """
    return external_call["cfmakeraw", c_void](termios_p)


# @value
# @register_passable("trivial")
# struct winsize():
#     var ws_row: UInt8      # Number of rows, in characters */
#     var ws_col: UInt8      # Number of columns, in characters */
#     var ws_xpixel: UInt8   # Width, in pixels */
#     var ws_ypixel: UInt8   # Height, in pixels */

#     fn __init__(out self):
#         self.ws_row = 0
#         self.ws_col = 0
#         self.ws_xpixel = 0
#         self.ws_ypixel = 0


# fn tcgetwinsize(fd: c_int, winsize_p: UnsafePointer[winsize]) -> c_int:
#     """Libc POSIX `tcgetwinsize` function
#     Reference: https://man.netbsd.org/tcgetwinsize.3
#     Fn signature: int tcgetwinsize(int fd, struct winsize *gws).

#     Args:
#         fd: File descriptor.
#         winsize_p: Pointer to a winsize struct.
#     """
#     return external_call["tcgetwinsize", c_int, c_int, UnsafePointer[winsize]](fd, winsize_p)


# fn tcsetwinsize(fd: c_int, winsize_p: UnsafePointer[winsize]) -> c_int:
#     """Libc POSIX `tcgetwinsize` function
#     Reference: https://man.netbsd.org/tcsetwinsize.3
#     Fn signature: int tcsetwinsize(int fd, const struct winsize *sws).

#     Args:
#         fd: File descriptor.
#         winsize_p: Pointer to a winsize struct.
#     """
#     return external_call["tcsetwinsize", c_int, c_int, UnsafePointer[winsize]](fd, winsize_p)


fn read(fd: c_int, buf: UnsafePointer[c_void], size: UInt) -> c_int:
    """Libc POSIX `read` function.

    Read `size` bytes from file descriptor `fd` into the buffer `buf`.

    Args:
        fd: A File Descriptor.
        buf: A pointer to a buffer to store the read data.
        size: The number of bytes to read.

    Returns:
        The number of bytes read or -1 in case of failure.

    #### C Function:
    ```c
    ssize_t read(int fildes, void *buf, size_t nbyte);
    ```

    #### Notes:
    Reference: https://man7.org/linux/man-pages/man3/read.3p.html.
    """
    return external_call["read", Int, c_int, UnsafePointer[c_void], UInt](fd, buf, size)


fn get_errno() -> c_int:
    """Get a copy of the current value of the `errno` global variable for
    the current thread.

    Returns:
        A copy of the current value of `errno` for the current thread.
    """

    @parameter
    if os_is_windows():
        var errno = InlineArray[c_int, 1]()
        _ = external_call["_get_errno", c_void](errno.unsafe_ptr())
        return errno[0]
    else:
        alias loc = "__error" if os_is_macos() else "__errno_location"
        return external_call[loc, UnsafePointer[c_int]]()[]


# --- ( error.h Constants )-----------------------------------------------------
# TODO: These are probably platform specific, we should check the values on each linux and macos.
alias EPERM = 1
alias ENOENT = 2
alias ESRCH = 3
alias EINTR = 4
alias EIO = 5
alias ENXIO = 6
alias E2BIG = 7
alias ENOEXEC = 8
alias EBADF = 9
alias ECHILD = 10
alias EAGAIN = 11
alias ENOMEM = 12
alias EACCES = 13
alias EFAULT = 14
alias ENOTBLK = 15
alias EBUSY = 16
alias EEXIST = 17
alias EXDEV = 18
alias ENODEV = 19
alias ENOTDIR = 20
alias EISDIR = 21
alias EINVAL = 22
alias ENFILE = 23
alias EMFILE = 24
alias ENOTTY = 25
alias ETXTBSY = 26
alias EFBIG = 27
alias ENOSPC = 28
alias ESPIPE = 29
alias EROFS = 30
alias EMLINK = 31
alias EPIPE = 32
alias EDOM = 33
alias ERANGE = 34
alias EWOULDBLOCK = EAGAIN
alias EINPROGRESS = 36 if os_is_macos() else 115
alias EALREADY = 37 if os_is_macos() else 114
alias ENOTSOCK = 38 if os_is_macos() else 88
alias EDESTADDRREQ = 39 if os_is_macos() else 89
alias EMSGSIZE = 40 if os_is_macos() else 90
alias ENOPROTOOPT = 42 if os_is_macos() else 92
alias EAFNOSUPPORT = 47 if os_is_macos() else 97
alias EADDRINUSE = 48 if os_is_macos() else 98
alias EADDRNOTAVAIL = 49 if os_is_macos() else 99
alias ENETDOWN = 50 if os_is_macos() else 100
alias ENETUNREACH = 51 if os_is_macos() else 101
alias ECONNABORTED = 53 if os_is_macos() else 103
alias ECONNRESET = 54 if os_is_macos() else 104
alias ENOBUFS = 55 if os_is_macos() else 105
alias EISCONN = 56 if os_is_macos() else 106
alias ENOTCONN = 57 if os_is_macos() else 107
alias ETIMEDOUT = 60 if os_is_macos() else 110
alias ECONNREFUSED = 61 if os_is_macos() else 111
alias ELOOP = 62 if os_is_macos() else 40
alias ENAMETOOLONG = 63 if os_is_macos() else 36
alias EHOSTUNREACH = 65 if os_is_macos() else 113
alias EDQUOT = 69 if os_is_macos() else 122
alias ENOMSG = 91 if os_is_macos() else 42
alias EPROTO = 100 if os_is_macos() else 71
alias EOPNOTSUPP = 102 if os_is_macos() else 95
