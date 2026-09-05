"""A one-shot handoff from a background task to the update loop.

`TaskGroup` tasks run on real OS threads, in parallel. That makes the obvious
TUI split -- a render task, an input task, a tick task, all sharing one model --
a data race, and there is no mutex in the standard library to make it safe.

The way out is not to share the model at all. The update loop stays the sole
owner of both the model and the terminal; a background task owns nothing but
its own work and reports back through one of these. What crosses the thread
boundary is a single machine word, published and observed atomically, so there
is no lock to take and nothing to tear.

That keeps blocking work -- a request, a file read, a query -- off the loop
without giving up single ownership: the loop keeps painting at full rate while
the task blocks, and collects the result on whatever frame it lands.

A task also has to be joined before the mailbox it points at is destroyed, so
work still outstanding when the loop quits would stall the exit. `cancel` is the
way out: the loop asks the task to stop, and a task that does its work in slices
checks `is_cancelled` between them and returns early.

```mojo
async def load[o: MutOrigin](box: Pointer[Mailbox, o]) -> None:
    while more_to_do:
        if box[].is_cancelled():      # checked between slices of work
            return
        do_a_slice()
    box[].post(result)                # blocks this task's thread, not the loop

var box = Mailbox()
tg.create_task(load(Pointer(to=box)))
...
var result = box.take()               # None until it lands, Some exactly once
...
box.cancel()                          # once the loop is done
tg.wait()
```
"""

from std.atomic import Atomic


comptime _PENDING = 0
"""No value has been posted yet."""
comptime _READY = 1
"""A value has been posted and not yet collected."""
comptime _TAKEN = 2
"""The posted value has been collected."""


struct Mailbox:
    """A single-use, lock-free slot for handing one integer back to the loop.

    One task posts, the loop takes. `take` yields the value exactly once, so a
    loop can call it every frame and act only on the frame it arrives.
    """

    var state: Atomic[DType.int64]
    """Whether a value has been posted, and whether it has been collected."""
    var value: Atomic[DType.int64]
    """The posted value. Only meaningful once `state` reads as ready."""
    var cancel_flag: Atomic[DType.int64]
    """Set by the loop to ask the task to give up early."""

    def __init__(out self):
        """Creates an empty mailbox."""
        self.state = Atomic[DType.int64](_PENDING)
        self.value = Atomic[DType.int64](_PENDING)
        self.cancel_flag = Atomic[DType.int64](0)

    def post(mut self, value: Int):
        """Publishes a value to the loop. Called once, from the task.

        The value is stored before the flag that advertises it, and both stores
        are sequentially consistent, so a loop that sees the flag is guaranteed
        to see the value.

        Args:
            value: The result to hand back.
        """
        self.value.store(Int64(value))
        self.state.store(Int64(_READY))

    def take(mut self) -> Optional[Int]:
        """Collects the posted value, if one has arrived. Called from the loop.

        Returns:
            The value on the first call after it is posted, `None` on every
            other call.
        """
        if self.state.load() != Int64(_READY):
            return None

        self.state.store(Int64(_TAKEN))
        return Int(self.value.load())

    def cancel(mut self):
        """Asks the task to stop. Called from the loop, when it is shutting down.

        This only sets a flag. A task that never checks it still runs to
        completion, so the loop must join regardless -- cancelling is what makes
        that join short rather than optional.
        """
        self.cancel_flag.store(Int64(1))

    def is_cancelled(mut self) -> Bool:
        """Reports whether the loop has asked this task to stop.

        A task doing long work should check this between slices of it, and
        return without posting once it reads True.

        Returns:
            True once the loop has called `cancel`.
        """
        return self.cancel_flag.load() != Int64(0)
