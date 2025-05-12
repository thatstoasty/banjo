from sys.ffi import external_call, os_is_windows, os_is_macos
from collections import Optional, Set
from sys import exit, stdin
from time.time import _CTimeSpec

from banjo.termios.c import c_void, c_int
import banjo.termios.c
from banjo.multiplex.selector import Selector
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


struct SelectSelector(Movable, Selector):
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
            raise Error("ValueError: Invalid events: ", events)

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

    fn select(mut self, timeout: Optional[Int] = None) raises -> List[InlineArray[Int, 2]]:
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

        var ready = List[InlineArray[Int, 2]]()
        for fd in self.readers:
            var events = 0
            if readers.test(fd[]):
                events |= EVENT_READ
            ready.append(InlineArray[Int, 2](fd[], events))

        for fd in self.writers:
            var events = 0
            if writers.test(fd[]):
                events |= EVENT_WRITE
            ready.append(InlineArray[Int, 2](fd[], events))

        return ready^

    fn close(self) -> None:
        """Close the selector.

        This must be called to make sure that any underlying resource is freed.
        """
        pass
