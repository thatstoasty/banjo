"""Paging through a collection.

The paginator holds only the arithmetic: which page is showing, how many there
are, and which slice of a collection that corresponds to. Drawing the items is
the application's job, which is why `slice_bounds` exists.
"""

from std.utils.variant import Variant

from banjo.app import Program, Runtime
from banjo.components.help import HelpView
from banjo.components.key import Binding, Help, press
from banjo.components.paginator import Layout, Paginator
from termctl.event.event import Char, Event, KeyEvent
from termctl.multiplex.kqueue import KQueueSelector
import mog
from mog import Profile


comptime RENDER_HZ = 60.0
"""The ceiling on repaints."""
comptime PER_PAGE = 6
"""How many entries fit on a page."""


def entries() -> List[String]:
    """The collection being paged through.

    Returns:
        The entries, in order.
    """
    var out = List[String]()
    var names: List[String] = [
        String("aardvark"), String("badger"), String("capybara"), String("dormouse"),
        String("echidna"), String("ferret"), String("gerbil"), String("hedgehog"),
        String("ibex"), String("jerboa"), String("kinkajou"), String("lemur"),
        String("marmot"), String("numbat"), String("ocelot"), String("pangolin"),
        String("quokka"), String("raccoon"), String("serval"), String("tapir"),
    ]
    for name in names:
        out.append(name.copy())
    return out^


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

    var pages: Paginator
    """Which page is showing, and how many there are."""
    var dots: Paginator
    """The same state drawn the other way, to show both layouts at once."""
    var help: HelpView
    """Renders the key bindings."""
    var bindings: List[Binding]
    """What the help view describes."""
    var done: Bool

    def __init__(out self) raises:
        self.pages = Paginator(per_page=PER_PAGE)
        _ = self.pages.set_total_pages(len(entries()))

        self.dots = Paginator(layout=Layout.DOTS, per_page=PER_PAGE)
        _ = self.dots.set_total_pages(len(entries()))
        self.dots.active_dot = mog.Style(Profile.ANSI).foreground(mog.Color(5)).render("●")
        self.dots.inactive_dot = mog.Style(Profile.ANSI).foreground(mog.Color(8)).render("○")

        self.help = HelpView(width=70)
        self.bindings = [
            self.pages.keymap.prev_page.copy(),
            self.pages.keymap.next_page.copy(),
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

        # Both paginators track the same position, so they see the same keys.
        self.pages.update(key)
        self.dots.update(key)
        return None

    def view(self) raises -> String:
        var all = entries()
        var bounds = self.pages.slice_bounds(len(all))

        var body = String()
        for i in range(bounds[0], bounds[1]):
            body.write_string("  ")
            body.write_string(all[i])
            body.write_string("\n")

        return String(
            "Animals\n\n",
            body,
            "\n  ",
            self.dots.view(),
            "   page ",
            self.pages.view(),
            "   showing ",
            self.pages.items_on_page(len(all)),
            " of ",
            len(all),
            "\n",
            self.help.short_view(self.bindings),
        )

    def is_done(self) -> Bool:
        return self.done


def main() raises:
    var model = Model()
    var rt = Runtime[Model, KQueueSelector](KQueueSelector(), RENDER_HZ)
    rt.run(model)
