"""Pagination state and its rendering, as dots or as `page/total`.

A port of `bubbles/paginator`. Two departures from the Go original:

- `ArabicFormat` is gone. Go stores a printf format string (`"%d/%d"`) and
  applies it at render time; without printf the equivalent is a separator, so
  that is what `separator` is.
- `update` returns nothing rather than a command, since it never produced one.

```mojo
var pages = Paginator(per_page=10)
_ = pages.set_total_pages(len(items))
var bounds = pages.slice_bounds(len(items))
for i in range(bounds[0], bounds[1]):
    ...
```
"""

from termctl.event.event import Char, KeyCode, KeyEvent, Left, PageDown, PageUp, Right

from banjo.components.key import Binding, Help, matches, press
from banjo.constants import SMALL_BUFFER_SIZE

@fieldwise_init
struct Layout(Equatable, TrivialRegisterPassable, Writable):
    """How the pagination is drawn."""

    var value: UInt8
    """The raw discriminant."""

    comptime ARABIC = Self(0)
    """Rendered as `page/total`."""
    comptime DOTS = Self(1)
    """Rendered as one dot per page, the current one filled."""


@fieldwise_init
struct KeyMap(Copyable):
    """The key bindings a paginator responds to."""

    var prev_page: Binding
    """Moves one page backward."""
    var next_page: Binding
    """Moves one page forward."""

    def __init__(out self):
        """Creates the default bindings: h/left/pgup and l/right/pgdown."""
        self.prev_page = Binding(
            keys=[PageUp(), Left(), Char("h")],
            help=Help("h/left", "previous page"),
        )
        self.next_page = Binding(
            keys=[PageDown(), Right(), Char("l")],
            help=Help("l/right", "next page"),
        )

def _calculate_total_pages(items: UInt16, per_page: UInt16) -> UInt16:
    """Sets the page count from a number of items, rounding up.

    A count below one leaves the paginator untouched, matching the Go
    original, so that an empty collection does not collapse it to zero
    pages mid-render.

    Args:
        items: How many items there are in total.
        per_page: How many items fit on a page.

    Returns:
        The resulting page count.
    """
    if items < 1:
        return 1

    var pages = items // per_page
    if items % per_page > 0:
        pages += 1
    return pages


struct Paginator(Copyable):
    """Tracks which page of a collection is being shown."""

    var layout: Layout
    """How the pagination is drawn."""
    var page: UInt16
    """The current page, counting from zero."""
    var per_page: UInt16
    """How many items fit on a page."""
    var total_pages: UInt16
    """How many pages there are."""
    var active_dot: String
    """Marks the current page under `Layout.DOTS`."""
    var inactive_dot: String
    """Marks every other page under `Layout.DOTS`."""
    var separator: String
    """Sits between page and total under `Layout.ARABIC`."""
    var keymap: KeyMap
    """The key bindings this paginator responds to."""

    def __init__(
        out self,
        layout: Layout = Layout.ARABIC,
        per_page: UInt16 = 1,
        total_pages: UInt16 = 1,
        active_dot: String = "•",
        inactive_dot: String = "○",
        separator: String = "/",
        var keymap: KeyMap = KeyMap(),
    ):
        """Creates a paginator on its first page.

        Args:
            layout: How the pagination is drawn.
            per_page: How many items fit on a page.
            total_pages: How many pages there are.
            active_dot: Marks the current page under `Layout.DOTS`.
            inactive_dot: Marks every other page under `Layout.DOTS`.
            separator: Sits between page and total under `Layout.ARABIC`.
            keymap: The key bindings this paginator responds to.
        """
        self.layout = layout
        self.page = 0
        self.per_page = per_page if per_page > 0 else 1
        self.total_pages = total_pages if total_pages > 0 else 1
        self.active_dot = active_dot
        self.inactive_dot = inactive_dot
        self.separator = separator
        self.keymap = keymap^

    def __init__(
        out self,
        items: UInt16,
        layout: Layout = Layout.ARABIC,
        per_page: UInt16 = 1,
        active_dot: String = "•",
        inactive_dot: String = "○",
        separator: String = "/",
        var keymap: KeyMap = KeyMap(),
    ):
        """Creates a paginator on its first page.

        Args:
            items: How many items there are in total.
            layout: How the pagination is drawn.
            per_page: How many items fit on a page.
            active_dot: Marks the current page under `Layout.DOTS`.
            inactive_dot: Marks every other page under `Layout.DOTS`.
            separator: Sits between page and total under `Layout.ARABIC`.
            keymap: The key bindings this paginator responds to.
        """
        self.layout = layout
        self.page = 0
        self.per_page = per_page if per_page > 0 else 1
        self.total_pages = _calculate_total_pages(items, self.per_page)
        self.active_dot = active_dot
        self.inactive_dot = inactive_dot
        self.separator = separator
        self.keymap = keymap^

    def slice_bounds(self, length: UInt16) -> Tuple[UInt16, UInt16]:
        """Returns the half-open range of items visible on the current page.

        Args:
            length: The length of the collection being paginated.

        Returns:
            The start and end indices, where end is exclusive.
        """
        var start = UInt16(self.page) * self.per_page
        var end = start + self.per_page
        if end > length:
            end = length
        return (start, end)

    def items_on_page(self, total_items: UInt16) -> UInt16:
        """Returns how many items the current page actually shows.

        The last page is usually short, so this is not always `per_page`.

        Args:
            total_items: The length of the collection being paginated.

        Returns:
            The number of items on the current page.
        """
        if total_items < 1:
            return 0
        var bounds = self.slice_bounds(total_items)
        return bounds[1] - bounds[0]

    def on_first_page(self) -> Bool:
        """Reports whether the first page is showing.

        Returns:
            True if the current page is the first.
        """
        return self.page == 0

    def on_last_page(self) -> Bool:
        """Reports whether the last page is showing.

        Returns:
            True if the current page is the last.
        """
        return self.page == self.total_pages - 1

    def prev_page(mut self):
        """Moves one page backward, stopping at the first page."""
        if self.page > 0:
            self.page -= 1

    def next_page(mut self):
        """Moves one page forward, stopping at the last page."""
        if not self.on_last_page():
            self.page += 1

    def update(mut self, event: KeyEvent) raises:
        """Applies a keystroke to the paginator.

        Args:
            event: The key event that arrived.

        Raises:
            Error: Propagated from key matching.
        """
        if matches(event, self.keymap.next_page):
            self.next_page()
        elif matches(event, self.keymap.prev_page):
            self.prev_page()

    def view(self) -> String:
        """Renders the pagination.

        Returns:
            The rendered pagination.
        """
        if self.layout == Layout.DOTS:
            var out = String(capacity=SMALL_BUFFER_SIZE)
            for i in range(self.total_pages):
                if i == self.page:
                    out.write_string(self.active_dot)
                else:
                    out.write_string(self.inactive_dot)
            return out

        return String(self.page + 1, self.separator, self.total_pages)
