"""A selectable, scrolling table with a help bar.

The table describes how to draw; the selection lives on the model as
`TableState`, which is the same two fields `ListState` holds.
"""

from std.sys.info import CompilationTarget
from std.utils.variant import Variant

from banjo.app import Program, Runtime
from banjo.components.help import HelpView
from banjo.components.key import Binding, Help
from banjo.components.table import Column, Table, TableState
from termctl.event.event import Char, Event, KeyEvent
from termctl.multiplex import Selector
import mog
from mog import Profile


comptime RENDER_HZ = 60.0
"""The ceiling on repaints."""
comptime BODY_ROWS = 8
"""How many body rows are shown at once."""


@fieldwise_init
struct Msg(ImplicitlyCopyable):
    """Everything this app can be told."""

    var value: Variant[KeyEvent]

    def isa[T: Copyable](self) -> Bool:
        return self.value.isa[T]()

    def __getitem_param__[T: Copyable](ref self) -> ref [origin_of(self.value)._get_owned_interior["value"]] T:
        return self.value[T]


def projects() -> List[List[String]]:
    """The rows this demo shows.

    Returns:
        The table body.
    """
    return [
        ["bubbletea", "Go", "29k"],
        ["ratatui", "Rust", "13k"],
        ["lipgloss", "Go", "8k"],
        ["textual", "Python", "27k"],
        ["bubbles", "Go", "6k"],
        ["crossterm", "Rust", "4k"],
        ["blessed", "JavaScript", "11k"],
        ["notcurses", "C", "4k"],
        ["termbox", "C", "5k"],
        ["tview", "Go", "11k"],
        ["cursive", "Rust", "4k"],
        ["urwid", "Python", "3k"],
        ["ink", "JavaScript", "27k"],
        ["mog", "Mojo", "1"],
        ["banjo", "Mojo", "1"],
    ]


struct Model(Program):
    comptime Msg = Msg

    var table: Table
    """The widget. Holds no selection state."""
    var state: TableState
    """The selection and scroll position, owned here."""
    var help: HelpView
    """Renders the key bindings beneath the table."""
    var bindings: List[Binding]
    """What the help view describes."""
    var done: Bool

    def __init__(out self) raises:
        var columns: List[Column] = [
            Column("Project", 12),
            Column("Language", 12),
            Column("Stars", 6),
        ]
        self.table = Table(columns^, projects(), border=mog.ROUNDED_BORDER)
        self.table.border_style = mog.Style(Profile.ANSI).foreground(mog.Color(8))
        self.table.styles.header = mog.Style(Profile.ANSI).foreground(mog.Color(6))
        self.table.styles.selected = mog.Style(Profile.ANSI).foreground(mog.Color(5)).reverse(True)

        self.state = TableState()
        self.state.select(0)

        self.help = HelpView(width=70)
        self.bindings = [
            self.table.keymap.up.copy(),
            self.table.keymap.down.copy(),
            self.table.keymap.page_down.copy(),
            self.table.keymap.first.copy(),
            self.table.keymap.last.copy(),
            Binding(keys=[Char("q")], help=Help("q", "quit")),
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
            return

        ref key = msg[KeyEvent]
        if key.code.isa[Char]() and (key.code[Char] == "q" or key.code[Char] == "Q"):
            self.done = True
            return

        _ = self.table.update(key, self.state, BODY_ROWS)
        return

    def view(self) raises -> String:
        var selected = "none"
        var row = self.table.selected_row(self.state)
        if row:
            selected = row.value()[0].copy()

        return String(
            "TUI projects\n\n",
            self.table.render(BODY_ROWS, self.state),
            "\n\nselected: ",
            selected,
            "\n",
            self.help.short_view(self.bindings),
        )

    def is_done(self) -> Bool:
        return self.done


def run_model[T: Selector](var selector: T, mut model: Model) raises:
    var rt = Runtime[Model](selector^, RENDER_HZ)
    rt.run(model)


def main() raises:
    var model = Model()
    comptime if CompilationTarget.is_macos():
        from termctl.multiplex import KQueueSelector
        run_model(KQueueSelector(), model)
    else:
        from termctl.multiplex import SelectSelector
        run_model(SelectSelector(), model)
