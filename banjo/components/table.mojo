"""A table with a header row and a selectable, scrolling body.

A port of `bubbles/table`, following the same contract as `ListView`: the
widget describes how to draw, and the selection lives in the caller's state.
`TableState` is `ListState` -- the two are the same two fields, and sharing
them means the selection and scrolling logic exists once.

```mojo
var state = TableState()
state.select(0)

var table = Table(columns^, rows^)
return table.render(height=10, state=state)
```
"""

import mog
from mist.transform import truncate
from mist.transform.ansi import string_width

from banjo.components.key import Binding, Help, matches, press
from banjo.components.list import ListState
from termctl.event.event import Char, Down, End, Home, KeyEvent, PageDown, PageUp, Up


comptime TableState = ListState
"""Which row is selected and how far the table is scrolled.

An alias rather than a separate type: it holds exactly what `ListState` holds,
and `bubbles` duplicates the navigation logic between its list and its table
for no benefit.
"""


@fieldwise_init
struct Column(Copyable):
    """One column of a table."""

    var title: String
    """The heading."""
    var width: Int
    """How many cells wide the column is. Content is truncated to fit."""


@fieldwise_init
struct TableStyles(Copyable):
    """How the parts of a table are drawn."""

    var header: Optional[mog.Style]
    """The heading row."""
    var cell: Optional[mog.Style]
    """Every body cell."""
    var selected: Optional[mog.Style]
    """The selected row, in place of `cell`."""

    def __init__(out self):
        """Creates unstyled table styles."""
        self.header = None
        self.cell = None
        self.selected = None


@fieldwise_init
struct KeyMap(Copyable):
    """The key bindings a table responds to."""

    var up: Binding
    """Moves the selection up."""
    var down: Binding
    """Moves the selection down."""
    var page_up: Binding
    """Moves the selection up by a screenful."""
    var page_down: Binding
    """Moves the selection down by a screenful."""
    var first: Binding
    """Selects the first row."""
    var last: Binding
    """Selects the last row."""

    def __init__(out self):
        """Creates the default bindings."""
        self.up = Binding([press(Up()), press(Char("k"))], Help("up/k", "up"))
        self.down = Binding([press(Down()), press(Char("j"))], Help("down/j", "down"))
        self.page_up = Binding([press(PageUp()), press(Char("b"))], Help("pgup/b", "page up"))
        self.page_down = Binding([press(PageDown()), press(Char("f"))], Help("pgdn/f", "page down"))
        self.first = Binding([press(Home()), press(Char("g"))], Help("home/g", "go to start"))
        self.last = Binding([press(End()), press(Char("G"))], Help("end/G", "go to end"))


struct Table(Copyable):
    """A description of how to draw a table. The selection lives elsewhere."""

    var columns: List[Column]
    """The columns, in order."""
    var rows: List[List[String]]
    """The body, one list of cells per row."""
    var styles: TableStyles
    """How the parts are drawn."""
    var show_header: Bool
    """Whether the heading row is drawn."""
    var keymap: KeyMap
    """The key bindings `update` responds to."""

    def __init__(out self, var columns: List[Column], var rows: List[List[String]]):
        """Creates a table.

        Args:
            columns: The columns, in order.
            rows: The body, one list of cells per row.
        """
        self.columns = columns^
        self.rows = rows^
        self.styles = TableStyles()
        self.show_header = True
        self.keymap = KeyMap()

    def selected_row(self, state: TableState) -> Optional[List[String]]:
        """Returns the selected row, if there is one.

        Args:
            state: The current selection.

        Returns:
            The row's cells, or None when nothing is selected.
        """
        if not state.selected:
            return None
        var index = state.selected.value()
        if index < 0 or index >= len(self.rows):
            return None
        return self.rows[index].copy()

    def update(mut self, event: KeyEvent, mut state: TableState, height: Int) raises -> Bool:
        """Applies a keystroke to the table's state and rescrolls if needed.

        Args:
            event: The key event that arrived.
            state: The state to move.
            height: How many body rows will be drawn.

        Returns:
            True if the selection moved.

        Raises:
            Error: Propagated from key matching.
        """
        var before = state.selected
        var count = len(self.rows)

        if matches(event, self.keymap.down):
            state.select_next(count)
        elif matches(event, self.keymap.up):
            state.select_previous(count)
        elif matches(event, self.keymap.page_down):
            state.scroll_down_by(height, count)
        elif matches(event, self.keymap.page_up):
            state.scroll_up_by(height, count)
        elif matches(event, self.keymap.first):
            state.select_first(count)
        elif matches(event, self.keymap.last):
            state.select_last(count)
        else:
            return False

        self.scroll_into_view(height, state)

        if not before:
            return state.selected.__bool__()
        if not state.selected:
            return True
        return before.value() != state.selected.value()

    def scroll_into_view(self, height: Int, mut state: TableState):
        """Scrolls so the selection is visible, and clamps it to the rows.

        `update` does this already. Call it directly after setting the
        selection some other way: `render` is pure and writes nothing back.

        Args:
            height: How many body rows will be drawn.
            state: The state to bring into view.
        """
        var count = len(self.rows)
        if count == 0 or height <= 0:
            state.offset = 0
            return

        if state.selected:
            var selected = state.selected.value()
            if selected > count - 1:
                selected = count - 1
            if selected < 0:
                selected = 0
            state.selected = selected

            if selected < state.offset:
                state.offset = selected
            elif selected >= state.offset + height:
                state.offset = selected - height + 1

        var furthest = count - height
        if state.offset > furthest:
            state.offset = furthest
        if state.offset < 0:
            state.offset = 0

    def _write_cell(self, mut out: String, text: StringSpan, width: Int) raises:
        """Writes one cell's text, truncated or padded to its column.

        Args:
            out: The buffer to write into.
            text: The cell's contents.
            width: The column width.

        Raises:
            Error: If truncation fails.
        """
        # `truncate` allocates, so it is only called when the text is actually
        # too wide -- which for most cells it is not.
        var fitted_width = Int(string_width(text))
        if fitted_width > width:
            var fitted = truncate(text, UInt(width), "…")
            fitted_width = Int(string_width(fitted))
            out.write_string(fitted)
        else:
            out.write_string(text)

        for _ in range(width - fitted_width):
            out.write_string(" ")

    def _write_row(self, mut out: String, cells: List[String]) raises:
        """Writes one row's cells side by side.

        Args:
            out: The buffer to write into.
            cells: The row's contents.

        Raises:
            Error: If truncation fails.
        """
        for i in range(len(self.columns)):
            if self.columns[i].width <= 0:
                continue
            if i >= len(cells):
                self._write_cell(out, "", self.columns[i].width)
            else:
                self._write_cell(out, cells[i], self.columns[i].width)

    def header_view(self) raises -> String:
        """Renders the heading row.

        Returns:
            The rendered heading, empty if headings are switched off.

        Raises:
            Error: If styling fails.
        """
        if not self.show_header:
            return String()

        var row = String()
        for ref column in self.columns:
            if column.width <= 0:
                continue
            self._write_cell(row, column.title, column.width)

        if self.styles.header:
            return self.styles.header.value().render(row)
        return row^

    def render(self, height: Int, state: TableState) raises -> String:
        """Draws the table.

        Pure: the state is read, never written. See `scroll_into_view`.

        Args:
            height: How many body rows to draw. The heading, when shown, is
                drawn above these rather than counted among them.
            state: The selection and scroll position.

        Returns:
            The rendered table.

        Raises:
            Error: If styling fails.
        """
        # Written straight into one buffer rather than collected as a list of
        # lines and joined.
        var out = String()
        var wrote_a_line = self.show_header
        if self.show_header:
            out.write_string(self.header_view())

        if len(self.rows) > 0 and height > 0:
            # Derived defensively on a scratch copy, so a stale offset still
            # renders correctly without writing one back.
            var scratch = state.copy()
            self.scroll_into_view(height, scratch)

            var end = scratch.offset + height
            if end > len(self.rows):
                end = len(self.rows)

            for index in range(scratch.offset, end):
                if wrote_a_line:
                    out.write_string("\n")
                wrote_a_line = True

                var is_selected = scratch.selected and scratch.selected.value() == index
                if not ((is_selected and self.styles.selected) or self.styles.cell):
                    # Nothing to wrap the row in, so build it in place rather
                    # than staging it in a string only to copy it out again.
                    self._write_row(out, self.rows[index])
                    continue

                # One of the two styles is set, or the branch above would have
                # taken it.
                var row = String()
                self._write_row(row, self.rows[index])
                if is_selected and self.styles.selected:
                    out.write_string(self.styles.selected.value().render(row))
                else:
                    out.write_string(self.styles.cell.value().render(row))

        return out^
