from utils import StaticTuple
from collections import InlineArray
from memory import UnsafePointer
from sys.ffi import external_call, os_is_windows, os_is_macos
from collections import Optional, Set
from sys import exit, stdin
from time.time import _CTimeSpec

from banjo.termios.c import c_void, c_int
import banjo.termios.c
from banjo._bitset import BitSet


@value
@register_passable("trivial")
struct timeval:
    var tv_sec: Int64
    var tv_usec: Int64


alias FileDescriptorBitSet = BitSet[16]


fn _select(
    nfds: c_int,
    readfds: Pointer[FileDescriptorBitSet],
    writefds: Pointer[FileDescriptorBitSet],
    exceptfds: Pointer[FileDescriptorBitSet],
    timeout: Pointer[timeval],
) -> c_int:
    """Libc POSIX `select` function.

    Args:
        nfds: The highest-numbered file descriptor in any of the three sets, plus 1.
        readfds: A pointer to the set of file descriptors to read from.
        writefds: A pointer to the set of file descriptors to write to.
        exceptfds: A pointer to the set of file descriptors to check for exceptions.
        timeout: A pointer to a timeval struct to set a timeout.

    Returns:
        The number of file descriptors in the sets or -1 in case of failure.

    #### C Function:
    ```c
    int select(int nfds, FileDescriptorBitSet *readfds, FileDescriptorBitSet *writefds, FileDescriptorBitSet *exceptfds, struct timeval *timeout);
    ```

    #### Notes:
    Reference: https://man7.org/linux/man-pages/man2/select.2.html
    """
    return external_call[
        "select",
        c_int,  # FnName, RetType
    ](nfds, readfds, writefds, exceptfds, timeout)


fn select(
    highest_fd: c_int,
    read_fds: FileDescriptorBitSet,
    write_fds: FileDescriptorBitSet,
    except_fds: FileDescriptorBitSet,
    timeout: timeval,
) raises -> UInt:
    """Libc POSIX `select` function.

    Args:
        highest_fd: The highest-numbered file descriptor in any of the three sets, plus 1.
        read_fds: A pointer to the set of file descriptors to read from.
        write_fds: A pointer to the set of file descriptors to write to.
        except_fds: A pointer to the set of file descriptors to check for exceptions.
        timeout: A pointer to a timeval struct to set a timeout.

    Returns:
        The number of file descriptors in the sets.

    #### C Function Signature:
    ```c
    int select(int nfds, FileDescriptorBitSet *readfds, FileDescriptorBitSet *writefds, FileDescriptorBitSet *exceptfds, struct timeval *timeout);
    ```

    #### Reference
    https://man7.org/linux/man-pages/man2/select.2.html.
    """
    var result = _select(
        highest_fd,
        Pointer(to=read_fds),
        Pointer(to=write_fds),
        Pointer(to=except_fds),
        Pointer(to=timeout),
    )

    if result == -1:
        var errno = c.get_errno()
        if errno == c.EBADF:
            raise Error("[EBADF] An invalid file descriptor was given in one of the sets.")
        elif errno == c.EINTR:
            raise Error("[EINTR] A signal was caught.")
        elif errno == c.EINVAL:
            raise Error("[EINVAL] nfds is negative or exceeds the RLIMIT_NOFILE resource limit.")
        elif errno == c.ENOMEM:
            raise Error("[ENOMEM] Unable to allocate memory for internal tables.")
        else:
            raise Error("[UNKNOWN] Unknown error occurred.")

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
        timeout: If timeout > 0, this specifies the maximum wait time, in seconds.
            if timeout <= 0, the select() call won't block, and will
            report the currently ready file objects
            if timeout is None, select() will block until a monitored
            file object becomes ready.

    Returns:
        List of (key, events) for ready file objects
        `events` is a bitwise mask of `EVENT_READ`|`EVENT_WRITE`.
    """
    var readers = FileDescriptorBitSet()
    readers.set(stdin.value)

    var tv = timeval(0, 0)
    if timeout:
        tv.tv_sec = Int64(timeout.value())

    if (
        select(
            stdin.value + 1,
            readers,
            FileDescriptorBitSet(),
            FileDescriptorBitSet(),
            tv,
        )
        == 0
    ):
        return 0

    if readers.test(0):
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
            ValueError if events is invalid.
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
            If fileobj is registered but has since been closed this does.
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
        var readers = FileDescriptorBitSet()
        for fd in self.readers:
            readers.set(fd[])

        var writers = FileDescriptorBitSet()
        for fd in self.writers:
            writers.set(fd[])

        var tv = timeval(0, 1)
        if timeout:
            tv.tv_sec = Int64(timeout.value())

        _ = select(
            self._highest_fd + 1,
            readers,
            writers,
            FileDescriptorBitSet(),
            tv,
        )

        var ready = List[StaticTuple[Int, 2]]()
        for fd in self.readers:
            var events = 0
            if readers.test(fd[]):
                events |= EVENT_READ
            ready.append(StaticTuple[Int, 2](fd[], events))

        for fd in self.writers:
            var events = 0
            if writers.test(fd[]):
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
#                 UnsafePointer(to=changelist), 1,
#                 eventlist, 0,
#                 UnsafePointer(to=timeout)
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
#                 UnsafePointer(to=changelist), 1,
#                 eventlist, 0,
#                 UnsafePointer(to=timeout)
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
#         var readers = FileDescriptorBitSet()
#         for fd in self.readers:
#             readers.set(fd[])

#         var writers = FileDescriptorBitSet()
#         for fd in self.writers:
#             writers.set(fd[])

#         var tv = timeval(0, 0)
#         if timeout:
#             tv.tv_sec = Int64(timeout.value())

#         if select(
#             self._highest_fd + 1,
#             UnsafePointer(to=readers),
#             UnsafePointer(to=writers),
#             UnsafePointer[FileDescriptorBitSet](),
#             UnsafePointer(to=tv)
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


# ### Monitoring file descriptors ###
# @value
# @register_passable("trivial")
# struct epoll_data:
#     var ptr: UnsafePointer[c_void]
#     var fd: c_int
#     var u32: UInt32
#     var u64: UInt64

#     fn __init__(out self, fd: c_int):
#         self.ptr = UnsafePointer[c_void]()
#         self.fd = fd
#         self.u32 = 0
#         self.u64 = 0


# @value
# @register_passable("trivial")
# struct epoll_event:
#     var events: UInt32
#     """Epoll events."""
#     var data: epoll_data
#     """User data variable."""


# # EPOLL op values
# alias EPOLL_CTL_ADD = 1
# alias EPOLL_CTL_DEL = 2
# alias EPOLL_CTL_MOD = 3

# # EPOLL op values
# alias EPOLLIN = 1
# alias EPOLLOUT = 4
# alias EPOLLRDHUP = 8192
# alias EPOLLPRI = 2
# alias EPOLLERR = 8
# alias EPOLLHUP = 16
# alias EPOLLET = 0x80000000
# alias EPOLLONESHOT = 0x40000000
# alias EPOLLEXCLUSIVE = 0x10000000


# fn epoll_create(size: c_int) -> c_int:
#     return external_call["epoll_create", c_int, c_int](size)


# fn epoll_create1(flags: c_int) -> c_int:
#     return external_call["epoll_create1", c_int, c_int](flags)


# fn epoll_ctl(epfd: c_int, op: c_int, fd: c_int, event: UnsafePointer[epoll_event]) -> c_int:
#     return external_call["epoll_ctl", c_int, c_int, c_int, c_int, UnsafePointer[epoll_event]](epfd, op, fd, event)


# fn epoll_wait(epfd: c_int, events: UnsafePointer[epoll_event], maxevents: c_int, timeout: c_int) -> c_int:
#     return external_call["epoll_wait", c_int, c_int, UnsafePointer[epoll_event], c_int, c_int](
#         epfd, events, maxevents, timeout
#     )


# # fn epoll_pwait(epfd: c_int, events: UnsafePointer[epoll_event], maxevents: c_int, timeout: c_int, sigmask: UnsafePointer[sigset_t]) -> c_int:
# #     return external_call["epoll_pwait", c_int, c_int, UnsafePointer[epoll_event], c_int, c_int, UnsafePointer[sigset_t]](epfd, events, maxevents, timeout, sigmask)


# # fn epoll_pwait2(epfd: c_int, events: UnsafePointer[epoll_event], maxevents: c_int, timeout: UnsafePointer[_CTimeSpec], sigmask: UnsafePointer[sigset_t]) -> c_int:
# #     return external_call["epoll_pwait", c_int, c_int, UnsafePointer[epoll_event], c_int, c_int, UnsafePointer[sigset_t]](epfd, events, maxevents, timeout, sigmask)
