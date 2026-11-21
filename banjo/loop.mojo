"""Frame pacing for a single-threaded update loop.

A TUI has to do two things that pull against each other: repaint on a schedule,
and react to input the instant it arrives. Doing both usually reaches for a
render thread, but the terminal event source already multiplexes the TTY through
a selector, and a selector takes a timeout. So the loop can simply wait in the
kernel until *either* input arrives or the next deadline expires, whichever
comes first.

That gives frame pacing and input latency at the same time, on one thread: an
idle interface costs no CPU, and a keypress is never sitting in a buffer waiting
out a sleep.

```mojo
var frames = Ticker(60.0)
while not model.done:
    var event = poll_event(reader, frames.deadline_ns)
    if event:
        ...  # feed the update function

    var now = perf_counter_ns()
    if frames.due(now):
        renderer.write(model.view())
        frames.advance(now)
```
"""

from std.time import perf_counter_ns

from termctl.event.event import Event
from termctl.event.read import EventReader
from termctl.multiplex.selector import Selector


comptime NANOS_PER_SECOND = 1_000_000_000
"""Nanoseconds in a second."""
comptime NANOS_PER_MICROSECOND = 1_000
"""Nanoseconds in a microsecond, the unit selectors take their timeouts in."""


struct Ticker(Copyable):
    """A fixed-rate deadline used to pace one part of the loop.

    A loop may hold several of these -- one for repainting, one for a game
    tick, one for a spinner -- and wait on whichever is nearest.
    """

    var period_ns: Int
    """Nanoseconds between ticks."""
    var deadline_ns: Int
    """Monotonic time at which the next tick comes due."""

    def __init__(out self, hz: Float64):
        """Creates a ticker running at the given rate.

        The first tick is due immediately, so a loop paints its opening frame
        without waiting out a full period first.

        Args:
            hz: Ticks per second. Values at or below zero fall back to 1 Hz
                rather than producing a zero period the loop would spin on.
        """
        var rate = hz
        if rate <= 0.0:
            rate = 1.0
        self.period_ns = Int(Float64(NANOS_PER_SECOND) / rate)
        self.deadline_ns = perf_counter_ns()

    def due(self, at: Int) -> Bool:
        """Reports whether this ticker has come due.

        Args:
            at: The monotonic time to test against, from `perf_counter_ns()`.

        Returns:
            True if the deadline has been reached or passed.
        """
        return at >= self.deadline_ns

    def advance(mut self, at: Int):
        """Schedules the next tick, dropping any periods already missed.

        Catching up one period at a time would let a single slow frame snowball
        into a burst of back-to-back ticks, so a ticker that has fallen more
        than one period behind restarts from `at` instead.

        Args:
            at: The monotonic time the tick was serviced at, from `perf_counter_ns()`.
        """
        self.deadline_ns += self.period_ns
        if self.deadline_ns <= at:
            self.deadline_ns = at + self.period_ns


def poll_event[T: Selector](mut reader: EventReader[T], deadline_ns: Int) raises -> Optional[Event]:
    """Waits for a terminal event, giving up at `deadline_ns`.

    The wait happens inside the selector, so this blocks without burning a core
    and returns the moment input is readable. A deadline already in the past
    makes this a non-blocking drain of whatever is already buffered.

    Parameters:
        T: The selector implementation backing the reader.

    Args:
        reader: The event reader to draw from.
        deadline_ns: Monotonic time to return by, from `perf_counter_ns()`.

    Returns:
        The next event, or None if the deadline passed first.

    Raises:
        Error: Propagated from the underlying event source.
    """
    while True:
        var remaining_ns = deadline_ns - perf_counter_ns()
        if remaining_ns < 0:
            remaining_ns = 0

        if not reader.poll(remaining_ns // NANOS_PER_MICROSECOND):
            return None

        # A successful poll may still yield nothing public -- responses to
        # terminal queries travel the same path -- so keep waiting out whatever
        # is left of the deadline rather than reporting a timeout early.
        var event = reader.try_read()
        if event:
            return event^
