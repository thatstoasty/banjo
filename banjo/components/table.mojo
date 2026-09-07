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


struct TableStyles(Copyable):
    """How the parts of a table are drawn."""

    var header: Optional[mog.Style]
    """The heading row."""
    var cell: Optional[mog.Style]
    """Every body cell."""
    var selected: Optional[mog.Style]
    """The selected row, in place of `cell`."""

    def __init__(
        out self,
        var header: Optional[mog.Style] = None,
        var cell: Optional[mog.Style] = None,
        var selected: Optional[mog.Style] = None,
    ):
        """Creates unstyled table styles."""
        self.header = header^
        self.cell = cell^
        self.selected = selected^


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
        self.up = Binding(keys=[Up(), Char("k")], help=Help("up/k", "up"))
        self.down = Binding(keys=[Down(), Char("j")], help=Help("down/j", "down"))
        self.page_up = Binding(keys=[PageUp(), Char("b")], help=Help("pgup/b", "page up"))
        self.page_down = Binding(keys=[PageDown(), Char("f")], help=Help("pgdn/f", "page down"))
        self.first = Binding(keys=[Home(), Char("g")], help=Help("home/g", "go to start"))
        self.last = Binding(keys=[End(), Char("G")], help=Help("end/G", "go to end"))


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
    var border: Optional[mog.Border]
    """The box drawn around and between cells. None leaves the table unframed.

    Any of `mog`'s borders works: `mog.ROUNDED_BORDER`, `mog.NORMAL_BORDER`,
    `mog.ASCII_BORDER` and so on. The characters are used the way `mog.Table`
    uses them, so a border looks the same drawn by either.
    """
    var border_style: Optional[mog.Style]
    """How the border characters are drawn."""
    var keymap: KeyMap
    """The key bindings `update` responds to."""

    def __init__(
        out self,
        var columns: List[Column],
        var rows: List[List[String]],
        styles: TableStyles = TableStyles(),
        keymap: KeyMap = KeyMap(),
        *,
        show_header: Bool = True,
        border: Optional[mog.Border] = None,
        border_style: Optional[mog.Style] = None,
    ):
        """Creates a table.

        Args:
            columns: The columns, in order.
            rows: The body, one list of cells per row.
            styles: The styles for the table.
            keymap: The key bindings for the table.
            show_header: Whether to show the header row.
            border: The box to draw around and between cells, if any.
            border_style: How to draw the border characters.
        """
        self.columns = columns^
        self.rows = rows^
        self.styles = styles.copy()
        self.show_header = show_header
        self.border = border.copy()
        self.border_style = border_style.copy()
        self.keymap = keymap.copy()

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

    def _write_cell(self, mut out: String, text: ImmStringSpan, width: Int) raises:
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

    def _write_row(self, mut out: String, cells: List[String], separator: StringSpan) raises:
        """Writes one row's cells side by side.

        The separator goes between cells but not at the ends, so the caller
        owns the outer edges and can draw them in the border's style rather
        than the row's.

        Args:
            out: The buffer to write into.
            cells: The row's contents.
            separator: Drawn between one cell and the next.

        Raises:
            Error: If truncation fails.
        """
        var first = True
        for i in range(len(self.columns)):
            if self.columns[i].width <= 0:
                continue
            if not first:
                out.write_string(separator)
            first = False
            if i >= len(cells):
                self._write_cell(out, "", self.columns[i].width)
            else:
                self._write_cell(out, cells[i], self.columns[i].width)

    def _write_edge(self, mut out: String, character: StringSpan) raises:
        """Writes one border character, in the border's style if there is one.

        Args:
            out: The buffer to write into.
            character: The character to write.

        Raises:
            Error: If styling fails.
        """
        if self.border_style:
            out.write_string(self.border_style.value().render(character))
        else:
            out.write_string(character)

    def _write_rule(
        self, mut out: String, left: StringSpan, fill: StringSpan, join: StringSpan, right: StringSpan
    ) raises:
        """Writes one horizontal rule spanning every visible column.

        Built whole and styled once, rather than a character at a time: a rule
        is uniform, so one `render` covers it.

        Args:
            out: The buffer to write into.
            left: The corner or tee that starts the rule.
            fill: Repeated across each column, once per cell of width.
            join: Drawn where two columns meet.
            right: The corner or tee that ends the rule.

        Raises:
            Error: If styling fails.
        """
        var rule = String()
        rule.write_string(left)
        var first = True
        for ref column in self.columns:
            if column.width <= 0:
                continue
            if not first:
                rule.write_string(join)
            first = False
            for _ in range(column.width):
                rule.write_string(fill)
        rule.write_string(right)

        if self.border_style:
            out.write_string(self.border_style.value().render(rule))
        else:
            out.write_string(rule)

    def header_view(self) raises -> String:
        """Renders the heading row.

        Returns:
            The rendered heading, empty if headings are switched off.

        Raises:
            Error: If styling fails.
        """
        if not self.show_header:
            return String()

        var separator = String()
        if self.border:
            separator = self.border.value().left.copy()

        var row = String()
        var first = True
        for ref column in self.columns:
            if column.width <= 0:
                continue
            if not first:
                row.write_string(separator)
            first = False
            self._write_cell(row, column.title, column.width)

        if self.styles.header:
            return self.styles.header.value().render(row)
        return row^

    def render(self, height: Int, state: TableState) raises -> String:
        """Draws the table.

        Pure: the state is read, never written. See `scroll_into_view`.

        Args:
            height: How many body rows to draw. The heading, when shown, is
                drawn above these rather than counted among them, and so are
                the border's rules.
            state: The selection and scroll position.

        Returns:
            The rendered table.

        Raises:
            Error: If styling fails.
        """
        # Written straight into one buffer rather than collected as a list of
        # lines and joined.
        var out = String()
        var wrote_a_line = False

        # The separator between cells is the border's own vertical bar, and it
        # sits inside the row rather than around it, so a selected row's style
        # runs unbroken across the whole width.
        var separator = String()
        if self.border:
            ref box = self.border.value()
            self._write_rule(out, box.top_left, box.top, box.middle_top, box.top_right)
            wrote_a_line = True
            separator = box.left.copy()

        if self.show_header:
            if wrote_a_line:
                out.write_string("\n")
            wrote_a_line = True
            if self.border:
                self._write_edge(out, self.border.value().left)
            out.write_string(self.header_view())
            if self.border:
                self._write_edge(out, self.border.value().right)

                ref box = self.border.value()
                out.write_string("\n")
                self._write_rule(out, box.middle_left, box.bottom, box.middle, box.middle_right)

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

                if self.border:
                    self._write_edge(out, self.border.value().left)

                var is_selected = scratch.selected and scratch.selected.value() == index
                if not ((is_selected and self.styles.selected) or self.styles.cell):
                    # Nothing to wrap the row in, so build it in place rather
                    # than staging it in a string only to copy it out again.
                    self._write_row(out, self.rows[index], separator)
                else:
                    # One of the two styles is set, or the branch above would
                    # have taken it.
                    var row = String()
                    self._write_row(row, self.rows[index], separator)
                    if is_selected and self.styles.selected:
                        out.write_string(self.styles.selected.value().render(row))
                    else:
                        out.write_string(self.styles.cell.value().render(row))

                if self.border:
                    self._write_edge(out, self.border.value().right)

        if self.border:
            ref box = self.border.value()
            if wrote_a_line:
                out.write_string("\n")
            self._write_rule(out, box.bottom_left, box.bottom, box.middle_bottom, box.bottom_right)

        return out^
