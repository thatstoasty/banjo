"""Spinners animated by the runtime's ticker.

The component holds frames and an index; `Runtime.every` supplies the cadence.
Each frame set carries the rate it was designed for, so the timer is registered
from the spinner rather than from a number picked here.
"""

from std.utils.variant import Variant

from banjo.app import Program, Runtime
from banjo.components.spinner import Spinner, dot, jump, line, meter, mini_dot, moon, points, pulse
from termctl.event.event import Char, Event, KeyEvent
from termctl.multiplex.kqueue import KQueueSelector
import mog
from mog import Profile


comptime RENDER_HZ = 60.0
"""The ceiling on repaints."""
comptime SPIN_TIMER = 0
"""Tag for the timer that advances every spinner."""
comptime SPIN_HZ = 12.0
"""Fast enough for the quickest frame set shown here."""


@fieldwise_init
struct Tick(TrivialRegisterPassable, Writable):
    """Advance the spinners one frame."""

    pass


@fieldwise_init
struct Msg(ImplicitlyCopyable):
    """Everything this app can be told."""

    var value: Variant[KeyEvent, Tick]

    def isa[T: Copyable](self) -> Bool:
        return self.value.isa[T]()

    def __getitem_param__[T: Copyable](ref self) -> ref [origin_of(self.value)._get_owned_interior["value"]] T:
        return self.value[T]


struct Model(Program):
    comptime Msg = Msg

    var spinners: List[Spinner]
    """One of each frame set."""
    var labels: List[String]
    """What each is called."""
    var done: Bool

    def __init__(out self) raises:
        self.spinners = [
            Spinner(line()),
            Spinner(mini_dot()),
            Spinner(dot()),
            Spinner(jump()),
            Spinner(pulse()),
            Spinner(points()),
            Spinner(meter()),
            Spinner(moon()),
        ]
        self.labels = [
            String("line"),
            String("mini_dot"),
            String("dot"),
            String("jump"),
            String("pulse"),
            String("points"),
            String("meter"),
            String("moon"),
        ]

        var accent = mog.Style(Profile.ANSI).foreground(mog.Color(5))
        for i in range(len(self.spinners)):
            self.spinners[i].style = accent.copy()

        self.done = False

    @staticmethod
    def on_event(event: Event) raises -> Optional[Msg]:
        if not event.isa[KeyEvent]():
            return None
        return Msg(event[KeyEvent])

    def on_tick(mut self, tag: Int) raises -> Optional[Msg]:
        if tag == SPIN_TIMER:
            return Msg(Tick())
        return None

    def on_result(mut self, value: Int) raises -> Optional[Msg]:
        return None

    def update(mut self, msg: Msg) raises -> Optional[Msg]:
        if msg.isa[Tick]():
            for i in range(len(self.spinners)):
                self.spinners[i].advance()
            return None

        if msg.isa[KeyEvent]():
            ref code = msg[KeyEvent].code
            if code.isa[Char]() and (code[Char] == "q" or code[Char] == "Q"):
                self.done = True
        return None

    def view(self) raises -> String:
        var out = String("Spinners (q to quit)\n\n")
        for i in range(len(self.spinners)):
            out.write_string("  ")
            out.write_string(self.spinners[i].view())
            out.write_string("  ")
            out.write_string(self.labels[i])
            out.write_string("  (")
            out.write_string(String(Int(self.spinners[i].hz())))
            out.write_string(" Hz)\n")
        return out

    def is_done(self) -> Bool:
        return self.done


def main() raises:
    var model = Model()
    var rt = Runtime[Model, KQueueSelector](KQueueSelector(), RENDER_HZ)
    rt.every(SPIN_HZ, SPIN_TIMER)
    rt.run(model)
