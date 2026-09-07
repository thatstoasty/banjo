"""A single-line text input, sized for things like a filter box.

Deliberately not a port of `bubbles/text_input`, which is roughly 2,000 lines
once its `cursor` and `internal` dependencies are counted. A list's filter box
needs typing, deletion and cursor movement, and that is what this is.

The cursor is drawn as a glyph inserted at the cursor position rather than by
restyling the character underneath it, so a visible cursor needs no styles and
no colour profile.

```mojo
var input = TextInput()
input.placeholder = String("Filter...")
_ = input.update(event)
return input.view()
```
"""

import mog
from mist.transform.ansi import string_width

from banjo.components.key import Binding, Help, matches, press
from termctl.event.event import Backspace, Char, Delete, End, Home, KeyEvent, KeyModifiers, Left, Right


@fieldwise_init
struct KeyMap(Copyable):
    """The key bindings a text input responds to, beyond typing."""

    var backspace: Binding
    """Deletes the character before the cursor."""
    var delete: Binding
    """Deletes the character under the cursor."""
    var left: Binding
    """Moves the cursor one character left."""
    var right: Binding
    """Moves the cursor one character right."""
    var start: Binding
    """Moves the cursor to the start."""
    var end: Binding
    """Moves the cursor to the end."""
    var clear: Binding
    """Clears the whole value."""

    def __init__(out self):
        """Creates the default bindings."""
        self.backspace = Binding([press(Backspace())], Help("backspace", "delete back"))
        self.delete = Binding([press(Delete())], Help("delete", "delete"))
        self.left = Binding([press(Left())], Help("left", "left"))
        self.right = Binding([press(Right())], Help("right", "right"))
        self.start = Binding([press(Home())], Help("home", "start"))
        self.end = Binding([press(End())], Help("end", "end"))
        self.clear = Binding([press(Char("u"), KeyModifiers.CONTROL)], Help("ctrl+u", "clear"))


def _grapheme_count(text: StringSpan) -> Int:
    """Counts the grapheme clusters in text.

    Cursor positions are counted in graphemes, not bytes or codepoints, so
    that arrow keys step over a character the way it is drawn: `e` followed by
    a combining acute is one column on screen and so one step for the cursor.

    Args:
        text: The text to measure.

    Returns:
        The number of grapheme clusters.
    """
    var count = 0
    for _ in text.graphemes():
        count += 1
    return count


def _grapheme_offset(text: StringSpan, index: Int) -> Int:
    """Finds where a grapheme starts, in bytes.

    Args:
        text: The text to walk.
        index: Which grapheme to find.

    Returns:
        The byte offset the grapheme starts at, or the byte length of the text
        if `index` is past the end.
    """
    if index <= 0:
        return 0
    var offset = 0
    var seen = 0
    for grapheme in text.graphemes():
        if seen == index:
            return offset
        offset += grapheme.byte_length()
        seen += 1
    return offset


def _grapheme_bounds(text: StringSpan, index: Int) -> Tuple[Int, Int]:
    """Finds the byte range one grapheme occupies.

    Args:
        text: The text to walk.
        index: Which grapheme to find.

    Returns:
        The first and last-plus-one byte of the grapheme. Both are the byte
        length of the text when `index` is past the end, so an out-of-range
        index describes an empty range rather than raising.
    """
    var offset = 0
    var seen = 0
    for grapheme in text.graphemes():
        if seen == index:
            return (offset, offset + grapheme.byte_length())
        offset += grapheme.byte_length()
        seen += 1
    return (offset, offset)


def _grapheme_index(text: StringSpan, offset: Int) -> Int:
    """Finds which grapheme a byte offset falls after.

    Used to place the cursor after an edit. Deriving it from the rebuilt text
    rather than adding to the old cursor keeps the count right when an insert
    joins the character before it -- typing a combining accent after `e`
    lengthens that grapheme instead of adding one.

    Args:
        text: The text to walk.
        offset: The byte offset to place.

    Returns:
        The number of graphemes that begin before `offset`.
    """
    var index = 0
    var seen = 0
    for grapheme in text.graphemes():
        if seen >= offset:
            break
        seen += grapheme.byte_length()
        index += 1
    return index


struct TextInput(Copyable):
    """A single line of editable text."""

    var value: String
    """The text entered so far."""
    var cursor: Int
    """Where the cursor sits, counted in graphemes from the start."""
    var placeholder: String
    """Shown instead of the value while the value is empty."""
    var prompt: String
    """Drawn to the left of the text."""
    var cursor_glyph: String
    """Drawn at the cursor position."""
    var width: Int
    """How wide the text may be drawn. Zero means unlimited."""
    var offset: Int
    """First visible grapheme, when the value is wider than `width`.

    Written by `update`, read by `view`. Keeping it means the window holds
    still while the cursor moves inside it; deriving it afresh each render
    would instead pin the cursor to one edge and scroll the text underneath it.
    """
    var styles_prompt: Optional[mog.Style]
    """How the prompt is drawn."""
    var styles_text: Optional[mog.Style]
    """How the value is drawn."""
    var styles_placeholder: Optional[mog.Style]
    """How the placeholder is drawn."""
    var keymap: KeyMap
    """The key bindings this input responds to."""

    def __init__(out self):
        """Creates an empty input."""
        self.value = String()
        self.cursor = 0
        self.offset = 0
        self.placeholder = String()
        self.prompt = String("> ")
        self.cursor_glyph = String("▏")
        self.width = 0
        self.offset = 0
        self.styles_prompt = None
        self.styles_text = None
        self.styles_placeholder = None
        self.keymap = KeyMap()

    def length(self) -> Int:
        """Returns the length of the value in graphemes.

        Returns:
            The grapheme count.
        """
        return _grapheme_count(self.value)

    def set_value(mut self, var value: String):
        """Replaces the value, putting the cursor at the end.

        Args:
            value: The new value.
        """
        self.value = value^
        self.cursor = self.length()
        self.offset = 0

    def reset(mut self):
        """Clears the value and the cursor."""
        self.value = String()
        self.cursor = 0
        self.offset = 0

    def insert(mut self, text: StringSpan):
        """Inserts text at the cursor.

        Args:
            text: The text to insert.
        """
        var at = _grapheme_offset(self.value, self.cursor)
        var rebuilt = String(capacity=self.value.byte_length() + text.byte_length())
        rebuilt.write_string(self.value[byte=0:at])
        rebuilt.write_string(text)
        rebuilt.write_string(self.value[byte = at : self.value.byte_length()])

        self.cursor = _grapheme_index(rebuilt, at + text.byte_length())
        self.value = rebuilt^

    def delete_before(mut self):
        """Deletes the character before the cursor."""
        if self.cursor == 0:
            return
        var bounds = _grapheme_bounds(self.value, self.cursor - 1)
        var rebuilt = String(capacity=self.value.byte_length())
        rebuilt.write_string(self.value[byte = 0 : bounds[0]])
        rebuilt.write_string(self.value[byte = bounds[1] : self.value.byte_length()])
        self.value = rebuilt^
        self.cursor -= 1

    def delete_under(mut self):
        """Deletes the character under the cursor."""
        var bounds = _grapheme_bounds(self.value, self.cursor)
        if bounds[0] == bounds[1]:
            return
        var rebuilt = String(capacity=self.value.byte_length())
        rebuilt.write_string(self.value[byte = 0 : bounds[0]])
        rebuilt.write_string(self.value[byte = bounds[1] : self.value.byte_length()])
        self.value = rebuilt^

    def _follow_cursor(mut self):
        """Scrolls the window the least amount needed to show the cursor.

        Called from `update` rather than `view`, so the window is remembered
        between renders and only moves when the cursor would leave it.
        """
        if self.width <= 0:
            self.offset = 0
            return

        if self.cursor < self.offset:
            self.offset = self.cursor
        elif self.cursor >= self.offset + self.width:
            self.offset = self.cursor - self.width + 1

        var furthest = self.length() - self.width + 1
        if self.offset > furthest:
            self.offset = furthest
        if self.offset < 0:
            self.offset = 0

    def update(mut self, event: KeyEvent) raises -> Bool:
        """Applies a keystroke.

        Args:
            event: The key event that arrived.

        Returns:
            True if the value or the cursor changed.

        Raises:
            Error: Propagated from key matching.
        """
        var changed = self._apply(event)
        if changed:
            self._follow_cursor()
        return changed

    def _apply(mut self, event: KeyEvent) raises -> Bool:
        """Applies a keystroke without touching the scroll window.

        Args:
            event: The key event that arrived.

        Returns:
            True if the value or the cursor changed.

        Raises:
            Error: Propagated from key matching.
        """
        if matches(event, self.keymap.backspace):
            if self.cursor == 0:
                return False
            self.delete_before()
            return True

        if matches(event, self.keymap.delete):
            if self.cursor >= self.length():
                return False
            self.delete_under()
            return True

        if matches(event, self.keymap.clear):
            if self.value.byte_length() == 0:
                return False
            self.reset()
            return True

        if matches(event, self.keymap.left):
            if self.cursor == 0:
                return False
            self.cursor -= 1
            return True

        if matches(event, self.keymap.right):
            if self.cursor >= self.length():
                return False
            self.cursor += 1
            return True

        if matches(event, self.keymap.start):
            if self.cursor == 0:
                return False
            self.cursor = 0
            return True

        if matches(event, self.keymap.end):
            if self.cursor == self.length():
                return False
            self.cursor = self.length()
            return True

        # Anything else that is a plain character is typed into the value.
        # Control chords are left for the application to interpret.
        if event.code.isa[Char]() and not event.modifiers.contains(KeyModifiers.CONTROL):
            self.insert(String(event.code[Char].char))
            return True

        return False

    def _visible(self) -> Tuple[Int, Int, Int]:
        """Works out which part of the value fits, keeping the cursor shown.

        Derived rather than stored, so that `view` can stay pure --
        `banjo.app.Program.view` takes an immutable `self`. The window depends
        only on the cursor and the width, so recomputing it gives the same
        answer every time. Byte offsets are returned rather than the text
        itself so that nothing is copied: `view` slices `self.value` in place.

        Returns:
            The first and last-plus-one visible byte, and the byte the cursor
            sits at. The third is always between the first two.
        """
        var total = self.length()
        var start = 0
        var end = total
        if self.width > 0 and total >= self.width:
            # The stored offset is a starting point, not the truth: `width` may
            # have changed since `update` last ran. Nudge a local copy so the
            # cursor is always visible, without writing anything back -- the
            # same defensive derivation `ListView.render` does on a scratch
            # state.
            start = self.offset
            if self.cursor < start:
                start = self.cursor
            elif self.cursor >= start + self.width:
                start = self.cursor - self.width + 1
            if start > total - self.width:
                start = total - self.width
            if start < 0:
                start = 0
            end = start + self.width

        var cursor = self.cursor
        if cursor < start:
            cursor = start
        elif cursor > end:
            cursor = end

        return (
            _grapheme_offset(self.value, start),
            _grapheme_offset(self.value, end),
            _grapheme_offset(self.value, cursor),
        )

    def view(self) raises -> String:
        """Draws the input.

        Returns:
            The rendered input, including the prompt and cursor.

        Raises:
            Error: If styling fails.
        """
        var out = String()
        if self.prompt.byte_length() > 0:
            if self.styles_prompt:
                out.write_string(self.styles_prompt.value().render(self.prompt))
            else:
                out.write_string(self.prompt)

        if self.value.byte_length() == 0 and self.placeholder.byte_length() > 0:
            out.write_string(self.cursor_glyph)
            if self.styles_placeholder:
                out.write_string(self.styles_placeholder.value().render(self.placeholder))
            else:
                out.write_string(self.placeholder)
            return out

        var visible = self._visible()
        if not self.styles_text:
            # Nothing to wrap the text in, so write the window straight out
            # rather than staging it in a second string.
            out.write_string(self.value[byte = visible[0] : visible[2]])
            out.write_string(self.cursor_glyph)
            out.write_string(self.value[byte = visible[2] : visible[1]])
            return out

        var text = String(capacity=visible[1] - visible[0] + self.cursor_glyph.byte_length())
        text.write_string(self.value[byte = visible[0] : visible[2]])
        text.write_string(self.cursor_glyph)
        text.write_string(self.value[byte = visible[2] : visible[1]])
        out.write_string(self.styles_text.value().render(text))
        return out
