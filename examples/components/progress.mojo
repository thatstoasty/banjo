"""A progress bar advanced by the runtime's ticker.

`bubbles` animates its bar with a spring simulation scheduled through
`tea.Cmd`. `banjo` has no commands, so the percentage is model state stepped
from `on_tick` -- which is all the animation ever was.
"""

from std.utils.variant import Variant

from banjo.app import Program, Runtime
from banjo.components.progress import ProgressBar
from banjo.components.spinner import Spinner, mini_dot
from termctl.event.event import Char, Event, KeyEvent
from termctl.multiplex.kqueue import KQueueSelector
import mog
from mog import Profile


comptime RENDER_HZ = 60.0
"""The ceiling on repaints."""
comptime STEP_TIMER = 0
"""Tag for the timer that advances the download."""
comptime STEP_HZ = 20.0
"""How often the percentage moves."""
comptime SPIN_TIMER = 1
"""Tag for the timer that advances the spinner."""


@fieldwise_init
struct Step(TrivialRegisterPassable, Writable):
    """Advance the download a little."""

    pass


@fieldwise_init
struct Spin(TrivialRegisterPassable, Writable):
    """Advance the spinner one frame."""

    pass


@fieldwise_init
struct Msg(ImplicitlyCopyable):
    """Everything this app can be told."""

    var value: Variant[KeyEvent, Step, Spin]

    def isa[T: Copyable](self) -> Bool:
        return self.value.isa[T]()

    def __getitem_param__[T: Copyable](ref self) -> ref [origin_of(self.value)._get_owned_interior["value"]] T:
        return self.value[T]


struct Model(Program):
    comptime Msg = Msg

    var bar: ProgressBar
    """Draws the proportion. Stateless: the percentage is passed to `view`."""
    var plain: ProgressBar
    """The same bar without its percentage text."""
    var spinner: Spinner
    """Shown while the download is running."""
    var percent: Float64
    """How far along the download is."""
    var running: Bool
    """Whether the percentage is advancing."""
    var done: Bool

    def __init__(out self) raises:
        self.bar = ProgressBar(width=48)
        self.bar.full_style = mog.Style(Profile.ANSI).foreground(mog.Color(2))
        self.bar.empty_style = mog.Style(Profile.ANSI).foreground(mog.Color(8))

        self.plain = ProgressBar(width=48)
        self.plain.show_percentage = False
        self.plain.full_char = String("=")
        self.plain.empty_char = String("-")

        self.spinner = Spinner(mini_dot())
        self.percent = 0.0
        self.running = True
        self.done = False

    @staticmethod
    def on_event(event: Event) raises -> Optional[Msg]:
        if not event.isa[KeyEvent]():
            return None
        return Msg(event[KeyEvent])

    def on_tick(mut self, tag: Int) raises -> Optional[Msg]:
        if tag == STEP_TIMER and self.running and self.percent < 1.0:
            return Msg(Step())
        # Nothing to animate once the download has finished.
        if tag == SPIN_TIMER and self.running and self.percent < 1.0:
            return Msg(Spin())
        return None

    def on_result(mut self, value: Int) raises -> Optional[Msg]:
        return None

    def update(mut self, msg: Msg) raises -> Optional[Msg]:
        if msg.isa[Step]():
            self.percent += 0.0125
            if self.percent > 1.0:
                self.percent = 1.0
            return None

        if msg.isa[Spin]():
            self.spinner.advance()
            return None

        if msg.isa[KeyEvent]():
            ref code = msg[KeyEvent].code
            if code.isa[Char]():
                var c = code[Char]
                if c == "q" or c == "Q":
                    self.done = True
                elif c == " ":
                    self.running = not self.running
                elif c == "r" or c == "R":
                    self.percent = 0.0
                    self.running = True
        return None

    def view(self) raises -> String:
        var status = String("done")
        if self.percent < 1.0:
            status = String(self.spinner.view(), " downloading") if self.running else String("  paused")

        return String(
            "Progress (space to pause, r to restart, q to quit)\n\n  ",
            self.bar.view(self.percent),
            "\n  ",
            self.plain.view(self.percent),
            "\n\n  ",
            status,
        )

    def is_done(self) -> Bool:
        return self.done


def main() raises:
    var model = Model()
    var rt = Runtime[Model, KQueueSelector](KQueueSelector(), RENDER_HZ)
    rt.every(STEP_HZ, STEP_TIMER)
    rt.every(model.spinner.hz(), SPIN_TIMER)
    rt.run(model)
