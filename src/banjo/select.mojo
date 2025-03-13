from utils import StaticTuple
from collections import InlineArray
from memory import UnsafePointer
from .termios.c import c_void, c_int, STDIN
from sys.ffi import external_call, os_is_windows, os_is_macos
from collections import Optional, Set
from sys import exit
from time.time import _CTimeSpec


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


@value
@register_passable("trivial")
struct timeval:
    var tv_sec: Int64
    var tv_usec: Int64


@value
@register_passable("trivial")
struct FD_SET:
    var bits: StaticTuple[Int64, 16]

    fn __init__(out self):
        self.bits = StaticTuple[Int64, 16]()

        @parameter
        for i in range(16):
            self.bits[i] = 0

    fn set(mut self, fd: Int):
        self.bits[fd // 64] |= 1 << fd % 64

    fn is_set(self, fd: Int) -> Bool:
        return (self.bits[fd // 64] & (1 << fd % 64)) != 0


fn FD_ZERO[origin: MutableOrigin](set: Pointer[FD_SET, origin]) -> c_void:
    """Libc POSIX `FD_ZERO` function
    Reference: https://man7.org/linux/man-pages/man2/select.2.html
    Fn signature: void FD_ZERO(FD_SET *set).

    Args:
        set: A pointer to the set of file descriptors to clear.
    """
    return external_call["FD_ZERO", c_void, Pointer[FD_SET, origin]](set)


fn _select(
    nfds: c_int,
    readfds: Pointer[FD_SET],
    writefds: Pointer[FD_SET],
    exceptfds: Pointer[FD_SET],
    timeout: Pointer[timeval],
) -> c_int:
    """Libc POSIX `select` function
    Reference: https://man7.org/linux/man-pages/man2/select.2.html
    Fn signature: int select(int nfds, FD_SET *readfds, FD_SET *writefds, FD_SET *exceptfds, struct timeval *timeout).

    Args: nfds: The highest-numbered file descriptor in any of the three sets, plus 1.
        readfds: A pointer to the set of file descriptors to read from.
        writefds: A pointer to the set of file descriptors to write to.
        exceptfds: A pointer to the set of file descriptors to check for exceptions.
        timeout: A pointer to a timeval struct to set a timeout.
    Returns: The number of file descriptors in the sets or -1 in case of failure.
    """
    return external_call[
        "select",
        c_int,  # FnName, RetType
    ](nfds, readfds, writefds, exceptfds, timeout)


fn select(
    highest_fd: c_int,
    read_fds: FD_SET,
    write_fds: FD_SET,
    except_fds: FD_SET,
    timeout: timeval,
) raises -> UInt:
    """Libc POSIX `select` function.

    Args:
        nfds: The highest-numbered file descriptor in any of the three sets, plus 1.
        read_fds: A pointer to the set of file descriptors to read from.
        write_fds: A pointer to the set of file descriptors to write to.
        except_fds: A pointer to the set of file descriptors to check for exceptions.
        timeout: A pointer to a timeval struct to set a timeout.

    Returns:
        The number of file descriptors in the sets.

    #### C Function Signature:
    ```c
    int select(int nfds, FD_SET *readfds, FD_SET *writefds, FD_SET *exceptfds, struct timeval *timeout);
    ```

    #### Reference
    https://man7.org/linux/man-pages/man2/select.2.html
    """
    var result = _select(
        highest_fd,
        Pointer.address_of(read_fds),
        Pointer.address_of(write_fds),
        Pointer.address_of(except_fds),
        Pointer.address_of(timeout),
    )

    if result == -1:
        var errno = get_errno()
        if errno == EBADF:
            raise Error("EBADF: An invalid file descriptor was given in one of the sets.")
        elif errno == EINTR:
            raise Error("EINTR: A signal was caught.")
        elif errno == EINVAL:
            raise Error("EINVAL: nfds is negative or exceeds the RLIMIT_NOFILE resource limit.")
        elif errno == ENOMEM:
            raise Error("ENOMEM: Unable to allocate memory for internal tables.")
        else:
            raise Error("Unknown error occurred.")

    return UInt(Int(result))


alias EVENT_READ = 1
alias EVENT_WRITE = 2


# trait Selector():
#     """Selector abstract base class.

#     A selector supports registering file objects to be monitored for specific
#     I/O events.

#     A file object is a file descriptor or any object with a `fileno()` method.
#     An arbitrary object can be attached to the file object, which can be used
#     for example to store context information, a callback, etc.

#     A selector can use various implementations (select(), poll(), epoll()...)
#     depending on the platform. The default `Selector` class uses the most
#     efficient implementation on the current platform.
#     """

#     fn register(self, fileobj: Int32, events: Int) raises:
#         """Register a file object.

#         Args:
#             fileobj: File object or file descriptor.
#             events: Events to monitor (bitwise mask of EVENT_READ|EVENT_WRITE).

#         Returns:
#             SelectorKey instance

#         Raises:
#             ValueError if events is invalid
#             KeyError if fileobj is already registered
#             OSError if fileobj is closed or otherwise is unacceptable to
#                     the underlying system call (if a system call is made)
#         """
#         ...

#     fn unregister(self, fileobj: Int32) raises:
#         """Unregister a file object.

#         Args:
#             fileobj: File object or file descriptor.

#         Returns:
#             SelectorKey instance.

#         Raises:
#             KeyError if fileobj is not registered.

#         Note:
#             If fileobj is registered but has since been closed this does
#         """
#         ...

#     # fn modify(self, fileobj: Int32, events: Int, data):
#     #     """Change a registered file object monitored events or attached data.

#     #     Args:
#     #         fileobj: file object or file descriptor
#     #         events: events to monitor (bitwise mask of EVENT_READ|EVENT_WRITE)
#     #         data: attached data

#     #     Returns:
#     #         SelectorKey instance

#     #     Raises:
#     #         Anything that unregister() or register() raises
#     #     """
#     #     ...

#     fn select(self, timeout: Int32):
#         """Perform the actual selection, until some monitored file objects are
#         ready or a timeout expires.

#         Args:
#             timeout: if timeout > 0, this specifies the maximum wait time, in seconds.
#                     if timeout <= 0, the select() call won't block, and will
#                     report the currently ready file objects
#                     if timeout is None, select() will block until a monitored
#                     file object becomes ready

#         Returns:
#             List of (key, events) for ready file objects
#             `events` is a bitwise mask of `EVENT_READ`|`EVENT_WRITE`.
#         """
#         ...

#     fn close(self):
#         """Close the selector.

#         This must be called to make sure that any underlying resource is freed.
#         """
#         ...

#     # fn get_key(self, fileobj: Int32):
#     #     """Return the key associated to a registered file object.

#     #     Returns:
#     #         SelectorKey for this file object.
#     #     """
#     #     ...

#     # fn get_map(self):
#     #     """Return a mapping of file objects to selector keys."""
#     #     ...


# # struct SelectorKey():
# #     """Key for a file object in a Selector.

# #     A key can be used to identify a registered file object in a Selector.
# #     """

# #     var fileobj: Int32
# #     var fd: Int32
# #     var events: Int32
# #     var data: Any

# #     fn __init__(out self, fileobj: Int32, fd: Int32, events: Int32, data: Any):
# #         self.fileobj = fileobj
# #         self.fd = fd
# #         self.events = events
# #         self.data = data

# #     fn __repr__(self) -> String:
# #         return String("SelectorKey(fileobj={}, fd={}, events={}, data={})").format(
# #             self.fileobj, self.fd, self.events, self.data
# #         )


fn stdin_select(timeout: Optional[Int] = None) raises -> Int:
    """Perform the actual selection, until some monitored file objects are
    ready or a timeout expires.

    Args:
        timeout: if timeout > 0, this specifies the maximum wait time, in seconds.
            if timeout <= 0, the select() call won't block, and will
            report the currently ready file objects
            if timeout is None, select() will block until a monitored
            file object becomes ready

    Returns:
        List of (key, events) for ready file objects
        `events` is a bitwise mask of `EVENT_READ`|`EVENT_WRITE`.
    """
    var readers = FD_SET()
    readers.set(STDIN)

    var tv = timeval(0, 0)
    if timeout:
        tv.tv_sec = Int64(timeout.value())

    if (
        select(
            STDIN + 1,
            readers,
            FD_SET(),
            FD_SET(),
            tv,
        )
        == 0
    ):
        return 0

    if readers.is_set(0):
        var events = 0
        events |= EVENT_READ
        return events

    return 0


struct SelectSelector(Movable):
    var readers: Set[Int]
    var writers: Set[Int]
    var _highest_fd: Int

    fn __init__(out self):
        self.readers = Set[Int]()
        self.writers = Set[Int]()
        self._highest_fd = 0

    fn __moveinit__(out self, owned other: SelectSelector):
        self.readers = other.readers^
        self.writers = other.writers^
        self._highest_fd = other._highest_fd

    fn register(mut self, fd: Int, events: Int) raises -> None:
        """Register a file object.

        Args:
            fd: File object or file descriptor.
            events: Events to monitor (bitwise mask of EVENT_READ|EVENT_WRITE).

        Raises:
            ValueError if events is invalid
        """
        if (not events) or (events & ~(EVENT_READ | EVENT_WRITE)):
            raise Error("ValueError: Invalid events: ", String(events))

        if events & EVENT_READ:
            self.readers.add(fd)

        if events & EVENT_WRITE:
            self.writers.add(fd)

        if fd > self._highest_fd:
            self._highest_fd = fd

    fn unregister(mut self, fd: Int) raises -> None:
        """Unregister a file object.

        Args:
            fd: File object or file descriptor.

        Raises:
            KeyError if fileobj is not registered.

        Note:
            If fileobj is registered but has since been closed this does
        """
        self.readers.remove(fd)
        self.writers.remove(fd)

    fn select(mut self, timeout: Optional[Int] = None) raises -> List[StaticTuple[Int, 2]]:
        """Perform the actual selection, until some monitored file objects are
        ready or a timeout expires.

        Args:
            timeout: If timeout > 0, this specifies the maximum wait time, in seconds.
                if timeout <= 0, the select() call won't block, and will
                report the currently ready file objects
                if timeout is None, select() will block until a monitored
                file object becomes ready.

        Returns:
            List of (key, events) for ready file objects
            `events` is a bitwise mask of `EVENT_READ`|`EVENT_WRITE`.
        """
        var readers = FD_SET()
        for fd in self.readers:
            readers.set(fd[])

        var writers = FD_SET()
        for fd in self.writers:
            writers.set(fd[])

        var tv = timeval(0, 1)
        if timeout:
            tv.tv_sec = Int64(timeout.value())

        _ = select(
            self._highest_fd + 1,
            readers,
            writers,
            FD_SET(),
            tv,
        )

        var ready = List[StaticTuple[Int, 2]]()
        for fd in self.readers:
            var events = 0
            if readers.is_set(fd[]):
                events |= EVENT_READ
            ready.append(StaticTuple[Int, 2](fd[], events))

        for fd in self.writers:
            var events = 0
            if writers.is_set(fd[]):
                print(self._highest_fd)
                events |= EVENT_WRITE
            ready.append(StaticTuple[Int, 2](fd[], events))

        return ready^


# fn kqueue() -> c_int:
#     """int kqueue(void)."""
#     return external_call["kqueue", c_int]()

# @value
# struct Kevent():
#     var ident: UInt
#     var filter: Int16
#     var flags: UInt16
#     var fflags: UInt32
#     var data: Int64
#     var udata: UnsafePointer[c_void]

#     fn __init__(out self, fd: UInt, filter: Int16, flags: UInt16, fflags: UInt32 = 0, data: Int64 = 0):
#         self.ident = fd
#         self.filter = filter
#         self.flags = flags
#         self.fflags = fflags
#         self.data = data
#         self.udata = UnsafePointer[c_void]()


# fn kevent(kq: c_int, changelist: UnsafePointer[Kevent], nchanges: c_int,
#     eventlist: UnsafePointer[Kevent], nevents: c_int,
#     timeout: UnsafePointer[_CTimeSpec]) -> c_int:
#     """int kevent(int kq, const struct kevent *changelist, int nchanges,
#     struct kevent *eventlist, int nevents,
#     const struct timespec *timeout);."""
#     return external_call["kevent", c_int, c_int, UnsafePointer[Kevent], c_int, UnsafePointer[Kevent], c_int, UnsafePointer[_CTimeSpec]](kq, changelist, nchanges, eventlist, nevents, timeout)


# alias KQ_EV_ADD = 1
# alias KQ_EV_CLEAR = 32
# alias KQ_EV_DELETE = 2
# alias KQ_EV_DISABLE = 8
# alias KQ_EV_ENABLE = 4
# alias KQ_EV_EOF = 32768
# alias KQ_EV_ERROR = 16384
# alias KQ_EV_FLAG1 = 8192
# alias KQ_EV_ONESHOT = 16
# alias KQ_EV_SYSFLAGS = 61440
# alias KQ_FILTER_AIO = -3
# alias KQ_FILTER_PROC = -5
# alias KQ_FILTER_READ = -1
# alias KQ_FILTER_SIGNAL = -6
# alias KQ_FILTER_TIMER = -7
# alias KQ_FILTER_VNODE = -4
# alias KQ_FILTER_WRITE = -2
# alias KQ_NOTE_ATTRIB = 8
# alias KQ_NOTE_CHILD = 4
# alias KQ_NOTE_DELETE = 1
# alias KQ_NOTE_EXEC = 536870912
# alias KQ_NOTE_EXIT = 2147483648
# alias KQ_NOTE_EXTEND = 4
# alias KQ_NOTE_FORK = 1073741824
# alias KQ_NOTE_LINK = 16
# alias KQ_NOTE_LOWAT = 1
# alias KQ_NOTE_PCTRLMASK = -1048576
# alias KQ_NOTE_PDATAMASK = 1048575
# alias KQ_NOTE_RENAME = 32
# alias KQ_NOTE_REVOKE = 64
# alias KQ_NOTE_TRACK = 1
# alias KQ_NOTE_TRACKERR = 2
# alias KQ_NOTE_WRITE = 2


# struct KQueueSelector():
#     var _selector: Int32
#     var _max_events: Int

#     fn __init__(out self):
#         self._selector = kqueue()
#         if self._selector == -1:
#             _ = external_call["perror", c_void, UnsafePointer[UInt8]](String("kqueue").unsafe_ptr())
#             exit(1)
#         self._max_events = 0

#     fn __moveinit__(out self, owned other: KQueueSelector):
#         self._selector = other._selector
#         self._max_events = other._max_events

#     fn register(mut self, fd: Int, events: Int) raises -> None:
#         """Register a file object.

#         Args:
#             fd: File object or file descriptor.
#             events: Events to monitor (bitwise mask of EVENT_READ|EVENT_WRITE).

#         Raises:
#             ValueError if events is invalid
#         """
#         if (not events) or (events & ~(EVENT_READ | EVENT_WRITE)):
#             raise Error("ValueError: Invalid events: " + str(events))

#         if events & EVENT_READ:
#             var timeout = _CTimeSpec(0, 0)
#             var changelist = Kevent(fd, KQ_FILTER_READ, KQ_EV_ADD)
#             var eventlist = UnsafePointer[Kevent]()
#             var kev = kevent(self._selector,
#                 UnsafePointer.address_of(changelist), 1,
#                 eventlist, 0,
#                 UnsafePointer.address_of(timeout)
#             )
#             if kev == -1:
#                 _ = external_call["perror", c_void, UnsafePointer[UInt8]](String("kevent").unsafe_ptr())
#                 exit(1)
#             self._max_events += 1

#         # if events & EVENT_WRITE:
#         #     kev = kevent(fd, KQ_FILTER_WRITE,
#         #                         KQ_EV_ADD)
#         #     self._selector.control([kev], 0, 0)
#         #     self._max_events += 1


#     fn unregister(mut self, fd: Int, events: Int) raises -> None:
#         """Unregister a file object.

#         Args:
#             fd: File object or file descriptor.

#         Raises:
#             KeyError if fileobj is not registered.

#         Note:
#             If fileobj is registered but has since been closed this does
#         """
#         if events & EVENT_READ:
#             var timeout = _CTimeSpec(0, 0)
#             var changelist = Kevent(fd, KQ_FILTER_READ, KQ_EV_DELETE)
#             var eventlist = UnsafePointer[Kevent]()
#             var kev = kevent(self._selector,
#                 UnsafePointer.address_of(changelist), 1,
#                 eventlist, 0,
#                 UnsafePointer.address_of(timeout)
#             )
#             if kev == -1:
#                 _ = external_call["perror", c_void, UnsafePointer[UInt8]](String("kevent").unsafe_ptr())
#                 exit(1)
#             self._max_events -= 1

#     fn select(mut self, timeout: Optional[Int] = None) -> List[StaticTuple[Int, 2]]:
#         """Perform the actual selection, until some monitored file objects are
#         ready or a timeout expires.

#         Args:
#             timeout: if timeout > 0, this specifies the maximum wait time, in seconds.
#                     if timeout <= 0, the select() call won't block, and will
#                     report the currently ready file objects
#                     if timeout is None, select() will block until a monitored
#                     file object becomes ready

#         Returns:
#             List of (key, events) for ready file objects
#             `events` is a bitwise mask of `EVENT_READ`|`EVENT_WRITE`.
#         """
#         var readers = FD_SET()
#         for fd in self.readers:
#             readers.set(fd[])

#         var writers = FD_SET()
#         for fd in self.writers:
#             writers.set(fd[])

#         var tv = timeval(0, 0)
#         if timeout:
#             tv.tv_sec = Int64(timeout.value())

#         if select(
#             self._highest_fd + 1,
#             UnsafePointer.address_of(readers),
#             UnsafePointer.address_of(writers),
#             UnsafePointer[FD_SET](),
#             UnsafePointer.address_of(tv)
#         ) == -1:
#             # _ = external_call["perror", c_void, UnsafePointer[UInt8]](String("select").unsafe_ptr())
#             print("select failed")
#             exit(1)

#         var ready = List[StaticTuple[Int, 2]]()
#         for fd in self.readers:
#             var events = 0
#             if readers.is_set(fd[]):
#                 events |= EVENT_READ
#             ready.append(StaticTuple[Int, 2](fd[], events))

#         for fd in self.writers:
#             var events = 0
#             if writers.is_set(fd[]):
#                 print(self._highest_fd)
#                 events |= EVENT_WRITE
#             ready.append(StaticTuple[Int, 2](fd[], events))

#         return ready

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
