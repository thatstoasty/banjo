"""Typing into a single-line input.

Two inputs are shown. The second has a width, so once what you type exceeds it
the window scrolls: the text holds still while the cursor moves inside it, and
only shifts when the cursor would leave.

Escape quits, since `q` has to be typeable.
"""

from std.utils.variant import Variant

from banjo.app import Program, Runtime
from banjo.components.help import HelpView
from banjo.components.key import Binding, Help, matches, press
from banjo.components.text_input import TextInput
from termctl.event.event import Char, Esc, Event, KeyEvent, Tab
from termctl.multiplex.kqueue import KQueueSelector
import mog
from mog import Profile


comptime RENDER_HZ = 60.0
"""The ceiling on repaints."""


@fieldwise_init
struct Msg(ImplicitlyCopyable):
    """Everything this app can be told."""

    var value: Variant[KeyEvent]

    def isa[T: Copyable](self) -> Bool:
        return self.value.isa[T]()

    def __getitem_param__[T: Copyable](ref self) -> ref [origin_of(self.value)._get_owned_interior["value"]] T:
        return self.value[T]


struct Model(Program):
    comptime Msg = Msg

    var name: TextInput
    """Unbounded: grows as you type."""
    var narrow: TextInput
    """Twelve columns wide, so it scrolls."""
    var focus_narrow: Bool
    """Which input has focus. Tab switches."""
    var help: HelpView
    """Renders the key bindings."""
    var bindings: List[Binding]
    """What the help view describes."""
    var done: Bool

    def __init__(out self) raises:
        var accent = mog.Style(Profile.ANSI).foreground(mog.Color(5))
        var dim = mog.Style(Profile.ANSI).foreground(mog.Color(8))

        self.name = TextInput()
        self.name.prompt = String("  name   > ")
        self.name.placeholder = String("type something")
        self.name.styles_prompt = accent.copy()
        self.name.styles_placeholder = dim.copy()

        self.narrow = TextInput()
        self.narrow.prompt = String("  narrow > ")
        self.narrow.placeholder = String("12 columns")
        self.narrow.width = 12
        self.narrow.styles_prompt = accent.copy()
        self.narrow.styles_placeholder = dim.copy()

        self.focus_narrow = False
        self.help = HelpView(width=76)
        self.bindings = [
            Binding([press(Tab())], Help("tab", "switch field")),
            self.name.keymap.left.copy(),
            self.name.keymap.right.copy(),
            self.name.keymap.clear.copy(),
            Binding([press(Esc())], Help("esc", "quit")),
        ]
        self.done = False

    @staticmethod
    def on_event(event: Event) raises -> Optional[Msg]:
        if not event.isa[KeyEvent]():
            return None
        return Msg(event[KeyEvent])

    def on_tick(mut self, tag: Int) raises -> Optional[Msg]:
        return None

    def on_result(mut self, value: Int) raises -> Optional[Msg]:
        return None

    def update(mut self, msg: Msg) raises -> Optional[Msg]:
        if not msg.isa[KeyEvent]():
            return None

        var key = msg[KeyEvent]
        if key.code.isa[Esc]():
            self.done = True
            return None

        if key.code.isa[Tab]():
            self.focus_narrow = not self.focus_narrow
            return None

        # Only the focused input sees the keystroke.
        if self.focus_narrow:
            _ = self.narrow.update(key)
        else:
            _ = self.name.update(key)
        return None

    def view(self) raises -> String:
        var name_marker = "   " if self.focus_narrow else " > "
        var narrow_marker = " > " if self.focus_narrow else "   "

        # Read through a reference: a `TextInput` is not implicitly copyable,
        # and there is no reason to copy one just to display it.
        ref focused = self.narrow if self.focus_narrow else self.name

        return String(
            "Text input\n\n",
            name_marker,
            self.name.view(),
            "\n",
            narrow_marker,
            self.narrow.view(),
            "\n\n  value: ",
            repr(focused.value),
            "\n  cursor: ",
            focused.cursor,
            " of ",
            focused.length(),
            "\n",
            self.help.short_view(self.bindings),
        )

    def is_done(self) -> Bool:
        return self.done


def main() raises:
    var model = Model()
    var rt = Runtime[Model, KQueueSelector](KQueueSelector(), RENDER_HZ)
    rt.run(model)
