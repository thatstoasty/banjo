"""The update loop itself, so an app only has to describe its behaviour.

`banjo.loop` gives the pieces -- a deadline and a timed poll. This assembles
them into the loop those pieces are always assembled into: wait on the nearest
deadline, feed input to `update`, deliver anything a task has finished, and
repaint on a cadence. What is left for an app is `update`, `view`, and how a
keypress becomes a message.

Timed messages are declared rather than hand-wired. `every` registers a
subscription, and the runtime folds its deadline into the same wait as input, so
a game tick or a spinner costs no extra thread and no extra poll.

```mojo
var model = Model()
var rt = Runtime[Model, KQueueSelector](KQueueSelector(), fps=24.0)
rt.every(10.0, Msg(Step()))
rt.run(model)
```

The runtime owns the renderer. A model that cannot reach it cannot fork its
frame-diffing state, which is the failure mode this shape is meant to prevent.
"""

from std.sys import stdout
from std.time import perf_counter_ns

from termctl.event.event import Event
from termctl.event.read import EventReader
from termctl.multiplex.selector import Selector
from termctl.terminal.tty import TTY, Mode

from banjo.loop import Ticker, poll_event
from banjo.renderer import Renderer
from banjo.task import Mailbox


trait Program(Movable):
    """What an app describes; `Runtime` supplies the loop around it."""

    comptime Msg: ImplicitlyCopyable & Deinitable
    """This app's message type."""

    @staticmethod
    def on_event(event: Event) raises -> Optional[Self.Msg]:
        """Translates a terminal event into a message, or ignores it.

        Args:
            event: The event read from the terminal.

        Returns:
            The message to apply, or None to ignore the event.

        Raises:
            Error: If the event cannot be interpreted.
        """
        ...

    def on_tick(mut self, tag: Int) raises -> Optional[Self.Msg]:
        """Produces the message for a timer that has come due.

        The app decides what a tick means, so a timer can stay silent when it
        has nothing to say -- a paused game emitting no Step keeps the runtime
        from marking the view dirty and rebuilding it for nothing.

        Args:
            tag: The tag the timer was registered with.

        Returns:
            The message to apply, or None to let this tick pass.

        Raises:
            Error: If the tick cannot be handled.
        """
        ...

    def on_result(mut self, value: Int) raises -> Optional[Self.Msg]:
        """Translates a finished background task's result into a message.

        Apps that never spawn a task return None.

        Args:
            value: The value the task posted to the runtime's mailbox.

        Returns:
            The message to apply, or None to ignore the result.

        Raises:
            Error: If the result cannot be interpreted.
        """
        ...

    def update(mut self, msg: Self.Msg) raises -> Optional[Self.Msg]:
        """Applies one message, optionally returning a follow-up message.

        Args:
            msg: The message to apply.

        Returns:
            A message to apply next, or None when the chain is done.

        Raises:
            Error: If the update fails.
        """
        ...

    def view(self) raises -> String:
        """Renders the current state.

        Returns:
            The frame to paint.

        Raises:
            Error: If rendering fails.
        """
        ...

    def is_done(self) -> Bool:
        """Reports whether the loop should stop.

        Returns:
            True once the app wants to exit.
        """
        ...


@fieldwise_init
struct Timer(Copyable):
    """A cadence the runtime asks the app about.

    Deliberately holds no message. A `List` of app-typed messages stored on the
    generic runtime corrupted the heap, and the app is a better place for that
    decision anyway.
    """

    var ticker: Ticker
    """When the next tick comes due."""
    var tag: Int
    """Identifies this timer to the app's `on_tick`."""


def dispatch[P: Program](mut program: P, msg: P.Msg) raises:
    """Applies a message and every follow-up message it returns, to completion.

    A free function rather than a method: as a static method on the generic
    runtime, calling this with a message copied out of the runtime's own
    subscription list corrupted the heap.

    Parameters:
        P: The app being updated.

    Args:
        program: The app to update.
        msg: The message to apply.

    Raises:
        Error: Propagated from `update`.
    """
    var pending = Optional[P.Msg](msg)
    while pending:
        pending = program.update(pending.value())


struct Runtime[P: Program, T: Selector]:
    """Owns the terminal, the clock, and the loop.

    Parameters:
        P: The app this runtime drives.
        T: The selector backing terminal polling.
    """

    var reader: EventReader[Self.T]
    """Terminal input."""
    var renderer: Renderer
    """Terminal output. Owned here so no model can copy it."""
    var frames: Ticker
    """The repaint cadence."""
    var timers: List[Timer]
    """Cadences registered with `every`."""
    var box: Mailbox
    """Where a background task leaves its result."""

    def __init__(out self, var selector: Self.T, fps: Float64) raises:
        """Creates a runtime bound to the terminal.

        Args:
            selector: The selector backend used to poll the terminal.
            fps: The ceiling on repaints per second.

        Raises:
            Error: If the terminal cannot be opened for reading.
        """
        self.reader = EventReader[Self.T](selector^)
        self.renderer = Renderer(stdout, Int(fps))
        self.frames = Ticker(fps)
        self.timers = List[Timer]()
        self.box = Mailbox()

    def every(mut self, hz: Float64, tag: Int):
        """Registers a cadence at which the app's `on_tick` is consulted.

        The timer's deadline joins the same wait as terminal input, so this
        costs no additional thread and no additional syscall.

        Args:
            hz: Ticks per second.
            tag: Passed back to `on_tick` so the app knows which timer fired.
        """
        self.timers.append(Timer(Ticker(hz), tag))

    def mailbox(mut self) -> Pointer[Mailbox, origin_of(self.box)]:
        """Hands out the mailbox a background task should post to.

        The runtime polls it every pass and routes what lands to `on_result`.

        Returns:
            A pointer to this runtime's mailbox.
        """
        return Pointer(to=self.box)

    def run(mut self, mut program: Self.P) raises:
        """Runs the app until it reports done, then restores the terminal.

        Args:
            program: The app to drive.

        Raises:
            Error: Propagated from the terminal, `update`, or `view`.
        """
        # Whether the model has changed since the last paint.
        var dirty = True

        with TTY[Mode.RAW]():
            while not program.is_done():
                # Wait on whichever deadline lands first. The wait happens in
                # the kernel, so idling is nearly free and a keypress wakes us
                # immediately rather than waiting out the rest of a frame.
                var deadline = self.frames.deadline_ns
                var i = 0
                while i < len(self.timers):
                    if self.timers[i].ticker.deadline_ns < deadline:
                        deadline = self.timers[i].ticker.deadline_ns
                    i += 1

                var event = poll_event(self.reader, deadline)
                if event:
                    var msg = Self.P.on_event(event.value())
                    if msg:
                        dispatch(program, msg.value())
                        dirty = True

                # Collect a finished task's result on whatever pass it lands
                # on. This is a load and a compare, cheap enough to do always.
                var arrived = self.box.take()
                if arrived:
                    var msg = program.on_result(arrived.value())
                    if msg:
                        dispatch(program, msg.value())
                        dirty = True

                # Read the clock once and drive every ticker off it, so a slow
                # update cannot leave them disagreeing about what time it is.
                var now = perf_counter_ns()

                var t = 0
                while t < len(self.timers):
                    if self.timers[t].ticker.due(now):
                        var tag = self.timers[t].tag
                        self.timers[t].ticker.advance(now)
                        var msg = program.on_tick(tag)
                        if msg:
                            dispatch(program, msg.value())
                            dirty = True
                    t += 1

                # Painting last means a frame always reflects the input and the
                # ticks just applied, rather than trailing them by one. The
                # cadence caps repaints rather than forcing them.
                if self.frames.due(now):
                    if dirty:
                        # Bound to a local rather than passed inline. `write`
                        # takes a span, and the frame it borrows has to outlive
                        # the call.
                        var frame = program.view()
                        self.renderer.write(frame)
                        dirty = False
                    # Advance even when nothing was painted, or the deadline
                    # goes stale and every poll returns instantly.
                    self.frames.advance(now)

        # Nobody will read a task's result now. Asking it to stop is what keeps
        # the join below short instead of stalling the exit.
        self.box.cancel()
