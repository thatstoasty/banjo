"""A one-shot handoff from a background task to the update loop.

`TaskGroup` tasks run on real OS threads, in parallel. That makes the obvious
TUI split -- a render task, an input task, a tick task, all sharing one model --
a data race, and there is no mutex in the standard library to make it safe.

The way out is not to share the model at all. The update loop stays the sole
owner of both the model and the terminal; a background task owns nothing but
its own work and reports back through one of these. The only thing shared and
written from both sides is a one-byte flag, published and observed atomically;
the result itself rides behind it. So there is no lock to take and nothing to
tear.

That keeps blocking work -- a request, a file read, a query -- off the loop
without giving up single ownership: the loop keeps painting at full rate while
the task blocks, and collects the result on whatever frame it lands.

A task also has to be joined before the mailbox it points at is destroyed, so
work still outstanding when the loop quits would stall the exit. `cancel` is the
way out: the loop asks the task to stop, and a task that does its work in slices
checks `is_cancelled` between them and returns early.

```mojo
__async def load[o: MutOrigin](box: Pointer[Mailbox[Int], o]) -> None:
    while more_to_do:
        if box[].is_cancelled():      # checked between slices of work
            return
        do_a_slice()
    box[].post(result)                # never blocks; the loop collects it later

var box = Mailbox[Int]()
tg.create_task(load(Pointer(to=box)))
...
var result = box.take()               # None until it lands, Some exactly once
...
box.cancel()                          # once the loop is done
tg.wait()
```
"""

from std.atomic import Atomic, Ordering


comptime _PENDING: UInt8 = 0
"""No value has been posted yet."""
comptime _READY: UInt8 = 1
"""A value has been posted and not yet collected."""
comptime _TAKEN: UInt8 = 2
"""The posted value has been collected."""


struct Mailbox[T: Movable & Deinitable](Movable):
    """A single-use, lock-free slot for handing one value back to the loop.

    One task posts, the loop takes. `take` yields the value exactly once, so a
    loop can call it every frame and act only on the frame it arrives.

    The payload is not itself atomic, and cannot be. `Atomic` takes any type as
    of Mojo 1.1, but its operations still require that type to be a `Scalar`,
    so `Atomic[Optional[String]]` constructs and then cannot be loaded. Only the
    flag is atomic, and that is enough: `post` releases the flag after writing
    the payload, and `take` acquires it before reading the payload, so a reader
    that sees the flag is guaranteed to see the whole value. That is what lets a
    value with heap storage -- a `String`, a `List` -- be built on one thread
    and owned by another.

    Strictly one producer and one consumer. Two tasks posting to one mailbox
    would race on the payload, which the flag does not order.

    Parameters:
        T: The type of value being handed over.
    """

    var state: Atomic[UInt8]
    """Whether a value has been posted, and whether it has been collected."""
    var value: Optional[Self.T]
    """The posted value. Only touched by the loop once `state` reads as ready."""
    var cancel_flag: Atomic[UInt8]
    """Set by the loop to ask the task to give up early.

    A byte rather than `Scalar[DType.bool]`, which is a single bit: an atomic
    access has to be at least a byte wide. `mojo run` accepts the bool and
    `mojo build` rejects it while lowering to LLVM, so it only shows up once
    something is compiled ahead of time.
    """

    def __init__(out self):
        """Creates an empty mailbox."""
        self.state = Atomic[UInt8](_PENDING)
        self.value = None
        self.cancel_flag = Atomic[UInt8](0)

    def post(mut self, var value: Self.T):
        """Publishes a value to the loop. Called once, from the task.

        The value is stored before the flag that advertises it, and the flag is
        stored with release ordering, so the payload's write cannot be moved
        after it. A loop that sees the flag is guaranteed to see a fully
        written value.

        Args:
            value: The result to hand back.
        """
        self.value = value^
        self.state.store[ordering=Ordering.RELEASE](_READY)

    def take(mut self) -> Optional[Self.T]:
        """Collects the posted value, if one has arrived. Called from the loop.

        Returns:
            The value on the first call after it is posted, `None` on every
            other call.
        """
        # One atomic step from ready to taken, rather than a load and then a
        # store: the check and the claim cannot be separated, so the value is
        # handed out once even if `take` is ever reached from two places.
        # Acquire on success pairs with `post`'s release and makes the payload
        # visible; a failed attempt reads nothing, so it needs no ordering.
        var expected = _READY
        if not self.state.compare_exchange[
            success_ordering=Ordering.ACQUIRE,
            failure_ordering=Ordering.RELAXED,
        ](expected, _TAKEN):
            return None
        return self.value.take()

    def cancel(mut self):
        """Asks the task to stop. Called from the loop, when it is shutting down.

        This only sets a flag. A task that never checks it still runs to
        completion, so the loop must join regardless -- cancelling is what makes
        that join short rather than optional.

        Relaxed, because the flag publishes nothing: no data is read on the
        strength of it, so it only needs to become visible eventually, which
        every atomic store does.
        """
        self.cancel_flag.store[ordering=Ordering.RELAXED](1)

    def is_cancelled(self) -> Bool:
        """Reports whether the loop has asked this task to stop.

        A task doing long work should check this between slices of it, and
        return without posting once it reads True.

        Returns:
            True once the loop has called `cancel`.
        """
        return self.cancel_flag.load[ordering=Ordering.RELAXED]() != 0
