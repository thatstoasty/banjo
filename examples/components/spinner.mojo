"""Spinners animated by the runtime's ticker.

The component holds frames and an index; `Runtime.every` supplies the cadence.
Each frame set carries the rate it was designed for, so the timer is registered
from the spinner rather than from a number picked here.
"""

from std.utils.variant import Variant

from banjo.app import Program, Runtime
from banjo.components.spinner import Spinner, Frames
from termctl.event.event import KeyCode, Event, KeyEvent
from termctl.multiplex import DefaultSelector
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
            Spinner.LINE,
            Spinner.MINI_DOT,
            Spinner.DOT,
            Spinner.JUMP,
            Spinner.PULSE,
            Spinner.POINTS,
            Spinner.METER,
            Spinner.MOON,
        ]
        self.labels = [
            "line",
            "mini_dot",
            "dot",
            "jump",
            "pulse",
            "points",
            "meter",
            "moon",
        ]

        var accent = mog.Style(Profile.ansi).foreground(mog.Color(5))
        for i in range(len(self.spinners)):
            self.spinners[i].style = accent.copy()

        self.done = False

    @staticmethod
    def on_event(event: Event) raises -> Optional[Msg]:
        var key = event.as_key_event()
        if not key:
            return None
        return Msg(key.value())

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
            if code == KeyCode.from_string("q") or code == KeyCode.from_string("Q"):
                self.done = True
        return None

    def view(self) raises -> String:
        var out = "Spinners (q to quit)\n\n"
        for i in range(len(self.spinners)):
            out.write_string("  ")
            out.write_string(self.spinners[i].view())
            out.write_string("  ")
            out.write_string(self.labels[i])
            out.write_string("  (")
            out.write(Int(self.spinners[i].hz()))
            out.write_string(" Hz)\n")
        return out^

    def is_done(self) -> Bool:
        return self.done


def main() raises:
    var model = Model()
    var rt = Runtime[Model](DefaultSelector(), RENDER_HZ)
    rt.every(SPIN_HZ, SPIN_TIMER)
    rt.run(model)
