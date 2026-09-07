"""A selectable, scrolling table with a help bar.

The table describes how to draw; the selection lives on the model as
`TableState`, which is the same two fields `ListState` holds.
"""

from std.utils.variant import Variant

from banjo.app import Program, Runtime
from banjo.components.help import HelpView
from banjo.components.key import Binding, Help, press
from banjo.components.table import Column, Table, TableState
from termctl.event.event import Char, Event, KeyEvent
from termctl.multiplex.kqueue import KQueueSelector
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


def _row(name: String, language: String, stars: String) -> List[String]:
    """Builds one row's cells.

    Args:
        name: The project name.
        language: The language it is written in.
        stars: How many stars it has.

    Returns:
        The cells, in column order.
    """
    var cells: List[String] = [name.copy(), language.copy(), stars.copy()]
    return cells^


def projects() -> List[List[String]]:
    """The rows this demo shows.

    Returns:
        The table body.
    """
    return [
        _row(String("bubbletea"), String("Go"), String("29k")),
        _row(String("ratatui"), String("Rust"), String("13k")),
        _row(String("lipgloss"), String("Go"), String("8k")),
        _row(String("textual"), String("Python"), String("27k")),
        _row(String("bubbles"), String("Go"), String("6k")),
        _row(String("crossterm"), String("Rust"), String("4k")),
        _row(String("blessed"), String("JavaScript"), String("11k")),
        _row(String("notcurses"), String("C"), String("4k")),
        _row(String("termbox"), String("C"), String("5k")),
        _row(String("tview"), String("Go"), String("11k")),
        _row(String("cursive"), String("Rust"), String("4k")),
        _row(String("urwid"), String("Python"), String("3k")),
        _row(String("ink"), String("JavaScript"), String("27k")),
        _row(String("mog"), String("Mojo"), String("1")),
        _row(String("banjo"), String("Mojo"), String("1")),
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
            Column(String("Project"), 12),
            Column(String("Language"), 12),
            Column(String("Stars"), 6),
        ]
        self.table = Table(columns^, projects(), border=mog.ROUNDED_BORDER)
        self.table.border_style = mog.Style(Profile.ANSI).foreground(mog.Color(8))
        self.table.styles.header = mog.Style(Profile.ANSI).foreground(mog.Color(6)).underline(True)
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
            Binding([press(Char("q"))], Help("q", "quit")),
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
        if key.code.isa[Char]() and (key.code[Char] == "q" or key.code[Char] == "Q"):
            self.done = True
            return None

        _ = self.table.update(key, self.state, BODY_ROWS)
        return None

    def view(self) raises -> String:
        var selected = String("none")
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


def main() raises:
    var model = Model()
    var rt = Runtime[Model, KQueueSelector](KQueueSelector(), RENDER_HZ)
    rt.run(model)
