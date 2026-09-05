"""A single-line text input, sized for things like a filter box.

Deliberately not a port of `bubbles/textinput`, which is roughly 2,000 lines
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
struct KeyMap(Copyable, Movable):
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


def _codepoints(text: StringSpan) -> List[String]:
    """Splits text into its codepoints.

    Cursor positions are counted in codepoints, not bytes, so that arrow keys
    step over a multi-byte character once rather than several times.

    Args:
        text: The text to split.

    Returns:
        One string per codepoint.
    """
    var out = List[String]()
    for codepoint in text.codepoint_slices():
        out.append(String(codepoint))
    return out^


struct TextInput(Copyable, Movable):
    """A single line of editable text."""

    var value: String
    """The text entered so far."""
    var cursor: Int
    """Where the cursor sits, counted in codepoints from the start."""
    var placeholder: String
    """Shown instead of the value while the value is empty."""
    var prompt: String
    """Drawn to the left of the text."""
    var cursor_glyph: String
    """Drawn at the cursor position."""
    var width: Int
    """How wide the text may be drawn. Zero means unlimited."""
    var offset: Int
    """First visible codepoint, when the value is wider than `width`.

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
        """Returns the length of the value in codepoints.

        Returns:
            The codepoint count.
        """
        return self.value.count_codepoints()

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
        var parts = _codepoints(self.value)
        var rebuilt = String()
        for i in range(len(parts)):
            if i == self.cursor:
                rebuilt.write_string(text)
            rebuilt.write_string(parts[i])
        if self.cursor >= len(parts):
            rebuilt.write_string(text)

        self.value = rebuilt^
        self.cursor += _codepoints(text).__len__()

    def delete_before(mut self):
        """Deletes the character before the cursor."""
        if self.cursor == 0:
            return
        var parts = _codepoints(self.value)
        var rebuilt = String()
        for i in range(len(parts)):
            if i != self.cursor - 1:
                rebuilt.write_string(parts[i])
        self.value = rebuilt^
        self.cursor -= 1

    def delete_under(mut self):
        """Deletes the character under the cursor."""
        var parts = _codepoints(self.value)
        if self.cursor >= len(parts):
            return
        var rebuilt = String()
        for i in range(len(parts)):
            if i != self.cursor:
                rebuilt.write_string(parts[i])
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

    def _visible(self) -> Tuple[List[String], Int]:
        """Works out which codepoints fit, scrolling to keep the cursor shown.

        Derived rather than stored, so that `view` can stay pure --
        `banjo.app.Program.view` takes an immutable `self`. The window depends
        only on the cursor and the width, so recomputing it gives the same
        answer every time.

        Returns:
            The visible codepoints and where the cursor sits among them.
        """
        var parts = _codepoints(self.value)
        if self.width <= 0 or len(parts) < self.width:
            return (parts^, self.cursor)

        # The stored offset is a starting point, not the truth: `width` may
        # have changed since `update` last ran. Nudge a local copy so the
        # cursor is always visible, without writing anything back -- the same
        # defensive derivation `ListView.render` does on a scratch state.
        var start = self.offset
        if self.cursor < start:
            start = self.cursor
        elif self.cursor >= start + self.width:
            start = self.cursor - self.width + 1
        if start > len(parts) - self.width:
            start = len(parts) - self.width
        if start < 0:
            start = 0

        var end = start + self.width
        if end > len(parts):
            end = len(parts)

        var window = List[String]()
        for i in range(start, end):
            window.append(parts[i].copy())
        return (window^, self.cursor - start)

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
        var text = String()
        for i in range(len(visible[0])):
            if i == visible[1]:
                text.write_string(self.cursor_glyph)
            text.write_string(visible[0][i])
        if visible[1] >= len(visible[0]):
            text.write_string(self.cursor_glyph)

        if self.styles_text:
            out.write_string(self.styles_text.value().render(text))
        else:
            out.write_string(text)
        return out
