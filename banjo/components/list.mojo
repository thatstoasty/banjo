"""A scrollable, selectable list.

The contract follows ratatui rather than `bubbles`: the widget describes how to
draw, the application owns the state, and items are a concrete type the
application maps its own data into. See `doc/porting-bubbles-list.md` for why.

Unlike ratatui this renders to a `String` through `mog` rather than into a cell
buffer, so it composes with the rest of `banjo`.

```mojo
var state = ListState()
state.select(0)

var view = ListView(items)
view.highlight_symbol = "> "

# in the app's view():
return view.render(height=10, state=state)
```

The struct is `ListView` rather than `List` because `List` is Mojo's builtin
collection and would be shadowed inside this module.
"""

import mog
from mist.transform.ansi import string_width

from banjo.constants import SMALL_BUFFER_SIZE
from banjo.components.key import Binding, Help, matches, press
from termctl.event.event import Char, Down, End, Home, KeyEvent, PageDown, PageUp, Up


@fieldwise_init
struct Direction(Equatable, TrivialRegisterPassable, Writable):
    """Which way the list is laid out."""

    var value: UInt8
    """The raw discriminant."""

    comptime TOP_TO_BOTTOM = Self(0)
    """The first item is drawn at the top."""
    comptime BOTTOM_TO_TOP = Self(1)
    """The first item is drawn at the bottom."""


struct ListItem(Copyable):
    """One row of a list: its text, and the style that text is drawn in.

    Content may span several lines; `height` reports how many.
    """

    var content: String
    """The text of this item. May contain newlines."""
    var style: Optional[mog.Style]
    """The style this item is drawn in, if it overrides the list's own."""
    var selected_content: Optional[String]
    """How this item looks when selected, if that is more than a style change.

    Ratatui patches `highlight_style` over the cells it has already laid out,
    so a selected row can restyle parts of itself. mog renders to a string,
    which cannot be patched after the fact, so an item whose selected
    appearance differs per line -- a title and description styled separately,
    say -- supplies that appearance here instead.
    """

    def __init__(
        out self,
        var content: String,
        var style: Optional[mog.Style] = None,
        var selected_content: Optional[String] = None,
    ):
        """Creates an item.

        A style is optional rather than defaulting to `mog.Style()`, because
        that default has to be built at compile time and mog's bare `Renderer`
        queries the terminal's colour profile through a global, which cannot be
        interpreted then. An unstyled item also does no styling work at all.

        Args:
            content: The text of the item, possibly spanning several lines.
            style: The style to draw it in, if any.
            selected_content: How it looks when selected, if that differs by
                more than a style.
        """
        self.content = content^
        self.style = style^
        self.selected_content = selected_content^

    def height(self) -> Int:
        """Returns how many lines this item occupies.

        Returns:
            The line count, at least one.
        """
        return len(self.content.splitlines()) if self.content.byte_length() > 0 else 1


struct ListState(Copyable):
    """Which item is selected and how far the list is scrolled.

    Owned by the application, not the widget, so the same items can be rendered
    in more than one place and so the widget itself stays a description.

    Unlike ratatui, the selection movers take the item count and clamp against
    it. Ratatui lets `selected` run past the end and clamps only while
    rendering, which leaves the state briefly inconsistent with what is shown.
    """

    var offset: Int
    """Index of the first item considered for display."""
    var selected: Optional[Int]
    """Index of the selected item, if any."""

    def __init__(
        out self,
        offset: Int = 0,
        selected: Optional[Int] = None,
    ):
        """Creates an unscrolled state with nothing selected."""
        self.offset = offset
        self.selected = selected

    def select(mut self, index: Optional[Int]):
        """Selects an item, or clears the selection.

        Clearing the selection also rewinds the scroll offset, matching
        ratatui: a list with nothing selected has nothing to stay scrolled to.

        Args:
            index: The index to select, or None to clear.
        """
        self.selected = index
        if not index:
            self.offset = 0

    def select_next(mut self, item_count: Int):
        """Moves the selection one item forward, stopping at the last item.

        With nothing selected this selects the first item.

        Args:
            item_count: How many items the list holds.
        """
        if item_count <= 0:
            return
        var next = 0 if not self.selected else self.selected.value() + 1
        if next > item_count - 1:
            next = item_count - 1
        self.selected = next

    def select_previous(mut self, item_count: Int):
        """Moves the selection one item backward, stopping at the first item.

        With nothing selected this selects the last item.

        Args:
            item_count: How many items the list holds.
        """
        if item_count <= 0:
            return
        var previous = item_count - 1 if not self.selected else self.selected.value() - 1
        if previous < 0:
            previous = 0
        self.selected = previous

    def select_first(mut self, item_count: Int):
        """Selects the first item.

        Args:
            item_count: How many items the list holds.
        """
        if item_count > 0:
            self.selected = 0

    def select_last(mut self, item_count: Int):
        """Selects the last item.

        Args:
            item_count: How many items the list holds.
        """
        if item_count > 0:
            self.selected = item_count - 1

    def scroll_down_by(mut self, amount: Int, item_count: Int):
        """Moves the selection forward by several items at once.

        Args:
            amount: How many items to move by.
            item_count: How many items the list holds.
        """
        if item_count <= 0:
            return
        var start = 0 if not self.selected else self.selected.value()
        var target = start + amount
        if target > item_count - 1:
            target = item_count - 1
        self.selected = target

    def scroll_up_by(mut self, amount: Int, item_count: Int):
        """Moves the selection backward by several items at once.

        Args:
            amount: How many items to move by.
            item_count: How many items the list holds.
        """
        if item_count <= 0:
            return
        var start = 0 if not self.selected else self.selected.value()
        var target = start - amount
        if target < 0:
            target = 0
        self.selected = target


@fieldwise_init
struct KeyMap(Copyable):
    """The key bindings a list responds to."""

    var up: Binding
    """Moves the selection up."""
    var down: Binding
    """Moves the selection down."""
    var page_up: Binding
    """Moves the selection up by a screenful."""
    var page_down: Binding
    """Moves the selection down by a screenful."""
    var first: Binding
    """Selects the first item."""
    var last: Binding
    """Selects the last item."""

    def __init__(out self):
        """Creates the default bindings."""
        self.up = Binding(help=Help("up/k", "up"), keys=[Up(), Char("k")])
        self.down = Binding(help=Help("down/j", "down"), keys=[Down(), Char("j")])
        self.page_up = Binding(help=Help("pgup/b", "page up"), keys=[PageUp(), Char("b")])
        self.page_down = Binding(help=Help("pgdn/f", "page down"), keys=[PageDown(), Char("f")])
        self.first = Binding(help=Help("home/g", "go to start"), keys=[Home(), Char("g")])
        self.last = Binding(help=Help("end/G", "go to end"), keys=[End(), Char("G")])


struct ListView(Copyable):
    """A description of how to draw a list. The state lives elsewhere."""

    var items: List[ListItem]
    """The rows to draw."""
    var style: Optional[mog.Style]
    """Applied to rows that carry no style of their own."""
    var highlight_style: Optional[mog.Style]
    """Applied to the selected row, in place of any other style."""
    var highlight_symbol: String
    """Drawn to the left of the selected row."""
    var repeat_highlight_symbol: Bool
    """Whether the symbol repeats on every line of a multi-line selected row."""
    var direction: Direction
    """Which way the list is laid out."""
    var scroll_padding: Int
    """How many rows to keep visible either side of the selection."""
    var keymap: KeyMap
    """The key bindings `update` responds to."""

    def __init__(
        out self,
        var items: List[ListItem],
        style: Optional[mog.Style] = None,
        var highlight_style: Optional[mog.Style] = None,
        var highlight_symbol: String = String(),
        direction: Direction = Direction.TOP_TO_BOTTOM,
        scroll_padding: Int = 0,
        var keymap: KeyMap = KeyMap(),
        *,
        repeat_highlight_symbol: Bool = False,
    ):
        """Creates a list over the given items.

        Args:
            items: The rows to draw.
            style: How to draw rows that carry no style of their own.
            highlight_style: How to draw the selected row, if it is more than a style change.
            highlight_symbol: Drawn to the left of the selected row.
            direction: Which way the list is laid out.
            scroll_padding: How many rows to keep visible either side of the selection.
            keymap: The key bindings `update` responds to.
            repeat_highlight_symbol: Whether the symbol repeats on every line of a multi-line selected row.
        """
        self.items = items^
        self.style = style
        self.highlight_style = highlight_style
        self.highlight_symbol = highlight_symbol
        self.repeat_highlight_symbol = repeat_highlight_symbol
        self.direction = direction
        self.scroll_padding = scroll_padding
        self.keymap = keymap^

    def update(mut self, event: KeyEvent, mut state: ListState, height: Int) raises -> Bool:
        """Applies a keystroke to the list's state and rescrolls if needed.

        Args:
            event: The key event that arrived.
            state: The state to move.
            height: How many lines the list will be drawn into, needed to work
                out how far to scroll.

        Returns:
            True if the selection moved, which the caller can use to decide
            whether a repaint is needed.

        Raises:
            Error: Propagated from key matching.
        """
        var before = state.selected
        var count = len(self.items)

        if matches(event, self.keymap.down):
            state.select_next(count)
        elif matches(event, self.keymap.up):
            state.select_previous(count)
        elif matches(event, self.keymap.first):
            state.select_first(count)
        elif matches(event, self.keymap.last):
            state.select_last(count)
        else:
            return False

        self.scroll_into_view(height, state)

        if not before:
            return Bool(state.selected)
        if not state.selected:
            return True
        return before.value() != state.selected.value()

    def scroll_into_view(self, height: Int, mut state: ListState):
        """Scrolls so the selection is visible, and clamps it to the items.

        `update` does this already. Call it directly after setting the
        selection some other way, so the stored offset stays meaningful across
        renders -- `render` itself is pure and will not write one back.

        Args:
            height: How many lines the list will be drawn into.
            state: The state to bring into view.
        """
        if len(self.items) == 0 or height <= 0:
            state.offset = 0
            return
        _ = self._visible_bounds(height, state)

    def _padded_selection(self, selected: Int, height: Int, first: Int, last: Int) -> Int:
        """Nudges the index the viewport must contain, to honour scroll padding.

        The padding shrinks rather than being ignored when the rows around the
        selection do not fit, so that uneven row heights cannot push the
        viewport into a different position on every render.

        Args:
            selected: The selected index, already clamped.
            height: The number of lines available.
            first: The first index currently visible.
            last: One past the last index currently visible.

        Returns:
            The index the viewport has to include.
        """
        var last_valid = len(self.items) - 1

        var padding = self.scroll_padding
        while padding > 0:
            var low = selected - padding
            if low < 0:
                low = 0
            var high = selected + padding
            if high > last_valid:
                high = last_valid

            var around = 0
            for i in range(low, high + 1):
                around += self.items[i].height()
            if around <= height:
                break
            padding -= 1

        var ahead = selected + padding
        if ahead > last_valid:
            ahead = last_valid
        if ahead >= last:
            var result = selected + padding
            return result if result <= last_valid else last_valid

        var behind = selected - padding
        if behind < 0:
            behind = 0
        if behind < first:
            return behind

        return selected

    def _visible_bounds(self, height: Int, mut state: ListState) -> Tuple[Int, Int]:
        """Works out which items fit, scrolling to keep the selection in view.

        Args:
            height: The number of lines available.
            state: The state; its offset is updated to what was actually used.

        Returns:
            The first visible index and one past the last.
        """
        var count = len(self.items)
        var offset = state.offset
        if offset > count - 1:
            offset = count - 1
        if offset < 0:
            offset = 0

        var first = offset
        var last = offset
        var used = 0

        for i in range(offset, count):
            if used + self.items[i].height() > height:
                break
            used += self.items[i].height()
            last += 1

        var target = offset
        if state.selected:
            var selected = state.selected.value()
            if selected > count - 1:
                selected = count - 1
            if selected < 0:
                selected = 0
            state.selected = selected
            target = self._padded_selection(selected, height, first, last)

        # The target sits below the viewport: extend downward, dropping rows
        # off the top until what is left fits.
        while target >= last and last < count:
            used += self.items[last].height()
            last += 1
            while used > height and first < last - 1:
                used -= self.items[first].height()
                first += 1

        # The target sits above the viewport: extend upward, dropping rows off
        # the bottom instead.
        while target < first and first > 0:
            first -= 1
            used += self.items[first].height()
            while used > height and last > first + 1:
                last -= 1
                used -= self.items[last].height()

        state.offset = first
        return (first, last)

    def render(self, height: Int, state: ListState) raises -> String:
        """Draws the list.

        Pure: the state is read, never written. `banjo.app.Program.view` takes
        an immutable `self`, so a view cannot be where scrolling is decided --
        that belongs in `update`, which is what `scroll_into_view` is for. The
        window is still derived defensively here, so a stale offset renders
        correctly even if it was never persisted.

        Args:
            height: How many lines are available.
            state: The selection and scroll position.

        Returns:
            The rendered list.

        Raises:
            Error: If styling fails.
        """
        if len(self.items) == 0 or height <= 0:
            return String()

        var scratch = state.copy()
        var bounds = self._visible_bounds(height, scratch)
        # As wide as the symbol is drawn, not as many bytes as it takes to
        # encode: "> " is two of each, but "\u25b6 " is two columns in four
        # bytes, and padding by bytes indents every unselected row too far.
        var blank = String()
        for _ in range(string_width(self.highlight_symbol)):
            blank.write_string(" ")

        # Written straight into one buffer rather than collected as a list of
        # rows and joined. `BOTTOM_TO_TOP` walks the window backwards instead
        # of reversing a list afterwards, which is the same order without the
        # rows having to exist separately to be reordered.
        var bottom_up = self.direction == Direction.BOTTOM_TO_TOP
        var out = String(capacity=SMALL_BUFFER_SIZE)
        for step in range(bounds[1] - bounds[0]):
            var index = bounds[1] - 1 - step if bottom_up else bounds[0] + step
            ref item = self.items[index]
            var is_selected = scratch.selected and scratch.selected.value() == index

            if step > 0:
                out.write_string("\n")

            # The selected row's style replaces rather than layers, since mog
            # has no equivalent of lipgloss's `Inherit`. Each branch writes to
            # the buffer itself: a single `body` variable would have to hold
            # both a borrowed content span and an owned rendered string, and
            # those are different types.
            if is_selected and item.selected_content:
                self._write_row(out, item.selected_content.value(), blank, is_selected)
            elif is_selected and self.highlight_style:
                self._write_row(out, self.highlight_style.value().render(item.content), blank, is_selected)
            elif item.style:
                self._write_row(out, item.style.value().render(item.content), blank, is_selected)
            elif self.style:
                self._write_row(out, self.style.value().render(item.content), blank, is_selected)
            else:
                self._write_row(out, item.content, blank, is_selected)

        return out^

    def _write_row(self, mut out: String, body: ImmStringSpan, blank: ImmStringSpan, is_selected: Bool):
        """Writes one item's body, prefixed with the highlight symbol.

        Takes the body as a span so that the caller can pass either an item's
        own content or a freshly styled string without either being copied.

        Args:
            out: The buffer to write into.
            body: The item's rendered body, which may span several lines.
            blank: Spaces as wide as the highlight symbol.
            is_selected: Whether this item is the selected one.
        """
        if self.highlight_symbol.byte_length() == 0:
            out.write_string(body)
            return

        var lines = body.splitlines()
        for i in range(len(lines)):
            # Branching rather than a ternary: the symbol is owned by `self`
            # and `blank` is the caller's, so the two arms have different
            # origins and cannot be picked between as one value.
            if is_selected and (i == 0 or self.repeat_highlight_symbol):
                out.write_string(self.highlight_symbol)
            else:
                out.write_string(blank)
            out.write_string(lines[i])
            if i < len(lines) - 1:
                out.write_string("\n")
