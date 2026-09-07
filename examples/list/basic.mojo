"""A list driven by banjo's runtime.

The widget holds no state: `ListState` lives on the model, exactly as ratatui
keeps it on the application.
"""

from std.utils.variant import Variant

from banjo.app import Program, Runtime
from banjo.components.default_item import DefaultItemStyles, default_item
from banjo.components.filter import rank
from banjo.components.text_input import TextInput
from banjo.components.help import HelpView
from banjo.components.key import Binding, Help, press
from banjo.components.list import ListItem, ListState, ListView
from termctl.event.event import Char, Enter, Esc, Event, KeyEvent
from termctl.multiplex.kqueue import KQueueSelector
import mog
from mog import Profile


comptime RENDER_HZ = 60.0
"""The ceiling on repaints."""
comptime VISIBLE_ROWS = 8
"""How many rows of the list are shown at once."""

def fruits() -> List[Tuple[String, String]]:
    """The rows this demo shows, as title and description pairs.

    Returns:
        The fruits, in order.
    """
    return [
        ("Apple", "Crisp, and everywhere"),
        ("Apricot", "Small, orange, stone fruit"),
        ("Banana", "Comes in its own wrapper"),
        ("Blackberry", "Grows on brambles"),
        ("Blueberry", "Small and blue, as billed"),
        ("Cherry", "Two on a stem, usually"),
        ("Cranberry", "Tart enough to notice"),
        ("Date", "Sweet, from a palm"),
        ("Elderberry", "Best cooked"),
        ("Fig", "Full of tiny seeds"),
        ("Grape", "Wine, eventually"),
        ("Grapefruit", "Bitter breakfast"),
        ("Kiwi", "Fuzzy outside, green in"),
        ("Lemon", "Sour, useful"),
        ("Mango", "Messy and worth it"),
        ("Nectarine", "A peach without the fuzz"),
        ("Orange", "Named after the colour"),
        ("Papaya", "Tropical, musky"),
        ("Peach", "Fuzzy and sweet"),
        ("Pear", "Ripens after picking"),
    ]


@fieldwise_init
struct Quit(TrivialRegisterPassable, Writable):
    """The user asked to exit."""

    pass


@fieldwise_init
struct Msg(ImplicitlyCopyable):
    """Everything this app can be told."""

    var value: Variant[KeyEvent, Quit]

    def isa[T: Copyable](self) -> Bool:
        return self.value.isa[T]()

    def __getitem_param__[T: Copyable](ref self) -> ref [origin_of(self.value)._get_owned_interior["value"]] T:
        return self.value[T]


struct Model(Program):
    comptime Msg = Msg

    var view_: ListView
    """The widget. A description of how to draw, holding no selection state."""
    var state: ListState
    """The selection and scroll position, owned here rather than by the widget."""
    var help: HelpView
    """Renders the key bindings beneath the list."""
    var bindings: List[Binding]
    """What the help view describes."""
    var filter_input: TextInput
    """The filter box, shown while filtering."""
    var filtering: Bool
    """Whether the filter box currently has focus."""
    var styles: DefaultItemStyles
    """Kept so rows can be rebuilt when the filter changes."""
    var done: Bool

    def __init__(out self) raises:
        var styles = DefaultItemStyles(Profile.ANSI)
        var items = List[ListItem]()
        for ref fruit in fruits():
            items.append(default_item(fruit[0].copy(), fruit[1].copy(), styles))

        self.view_ = ListView(items^)
        self.view_.scroll_padding = 1

        self.help = HelpView(width=70)
        self.bindings = [
            self.view_.keymap.up.copy(),
            self.view_.keymap.down.copy(),
            self.view_.keymap.first.copy(),
            self.view_.keymap.last.copy(),
            Binding([press(Char("/"))], Help("/", "filter")),
            Binding([press(Char("q"))], Help("q", "quit")),
        ]

        self.state = ListState()
        self.state.select(0)

        self.filter_input = TextInput()
        self.filter_input.placeholder = "Filter..."
        self.filter_input.prompt = "/ "
        self.filtering = False
        self.styles = styles^
        self.done = False

    @staticmethod
    def on_event(event: Event) raises -> Optional[Msg]:
        if not event.isa[KeyEvent]():
            return None
        var key = event[KeyEvent]
        # `q` quits, but only when it is not being typed into the filter box.
        # The model decides that, so the raw key is forwarded either way.
        return Msg(key)

    def on_tick(mut self, tag: Int) raises -> Optional[Msg]:
        return None

    def on_result(mut self, value: Int) raises -> Optional[Msg]:
        return None

    def visible_fruits(self) raises -> List[Tuple[String, String]]:
        """The fruits matching the current filter, best match first.

        Returns:
            The fruits to show.
        """
        var all = fruits()
        if self.filter_input.value.byte_length() == 0:
            return all^

        var titles = List[String]()
        for ref fruit in all:
            titles.append(fruit[0].copy())

        var out = List[Tuple[String, String]]()
        for ref hit in rank(self.filter_input.value, titles):
            out.append((all[hit.index][0].copy(), all[hit.index][1].copy()))
        return out^

    def rebuild(mut self) raises:
        """Rebuilds the rows from the current filter and resets the selection."""
        var items = List[ListItem]()
        for ref fruit in self.visible_fruits():
            items.append(default_item(fruit[0].copy(), fruit[1].copy(), self.styles))
        self.view_.items = items^

        if len(self.view_.items) == 0:
            self.state.select(None)
        else:
            self.state.select(0)
            self.view_.scroll_into_view(VISIBLE_ROWS, self.state)

    def update(mut self, msg: Msg) raises -> Optional[Msg]:
        if msg.isa[Quit]():
            self.done = True
            return None

        if msg.isa[KeyEvent]() and not self.filtering:
            var pressed = msg[KeyEvent]
            if pressed.code.isa[Char]() and (pressed.code[Char] == "q" or pressed.code[Char] == "Q"):
                self.done = True
                return None
        if not msg.isa[KeyEvent]():
            return None

        var key = msg[KeyEvent]

        if self.filtering:
            if key.code.isa[Esc]():
                self.filtering = False
                self.filter_input.reset()
                self.rebuild()
                return None
            if key.code.isa[Enter]():
                self.filtering = False
                return None
            if self.filter_input.update(key):
                self.rebuild()
            return None

        if key.code.isa[Char]() and key.code[Char] == "/":
            self.filtering = True
            return None

        _ = self.view_.update(key, self.state, VISIBLE_ROWS)
        return None

    def view(self) raises -> String:
        var selected = String("none")
        if self.state.selected:
            selected = self.visible_fruits()[self.state.selected.value()][0].copy()

        var header = String("Fruit")
        if self.filtering or self.filter_input.value.byte_length() > 0:
            header = self.filter_input.view()

        var body = self.view_.render(VISIBLE_ROWS, self.state)
        if len(self.view_.items) == 0:
            body = String("  no matches")

        return String(
            header,
            "\n\n",
            body,
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
