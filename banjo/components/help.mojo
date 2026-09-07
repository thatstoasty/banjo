"""A help view rendering key bindings, short on one line or full in columns.

A port of `bubbles/help`. Go declares a `KeyMap` interface with `ShortHelp()`
and `FullHelp()`; here the bindings are passed in directly, since Mojo has no
boxed existentials and an application can hand over a list just as easily.

Disabled bindings are skipped, so a key map that enables and disables bindings
with application state produces correct help without further bookkeeping.

```mojo
var help = HelpView(width=60)
var line = help.short_view([keymap.up, keymap.down, keymap.quit])
```
"""

import mog
from mist.transform.ansi import string_width

from banjo.components.key import Binding


@fieldwise_init
struct HelpStyles(Copyable):
    """Styles for the parts of a help view.

    Every style is optional; anything left unset renders unstyled. `mog.Style`
    cannot be built as a default argument, because its bare renderer queries
    the terminal's colour profile through a global that cannot be evaluated at
    compile time.
    """

    var key: Optional[mog.Style]
    """The keystroke, for example `up/k`."""
    var desc: Optional[mog.Style]
    """The description, for example `move up`."""
    var separator: Optional[mog.Style]
    """What sits between entries."""
    var ellipsis: Optional[mog.Style]
    """The marker shown when entries did not fit."""

    def __init__(out self):
        """Creates unstyled help."""
        self.key = None
        self.desc = None
        self.separator = None
        self.ellipsis = None


struct HelpView(Copyable):
    """Renders key bindings as help text."""

    var width: Int
    """The width to fit within. Zero means unlimited."""
    var short_separator: String
    """Sits between entries in the short view."""
    var full_separator: String
    """Sits between columns in the full view."""
    var ellipsis: String
    """Shown in place of entries that did not fit."""
    var styles: HelpStyles
    """How the parts are drawn."""

    def __init__(out self, width: Int = 0):
        """Creates a help view.

        Args:
            width: The width to fit within, or zero for unlimited.
        """
        self.width = width
        self.short_separator = " • "
        self.full_separator = "    "
        self.ellipsis = "…"
        self.styles = HelpStyles()

    def _styled(self, style: Optional[mog.Style], text: ImmStringSpan) raises -> String:
        """Applies a style if one is set.

        Args:
            style: The style to apply, if any.
            text: The text to draw.

        Returns:
            The text, styled or not.

        Raises:
            Error: If styling fails.
        """
        if style:
            return style.value().render(text)
        return String(text)

    def _tail(self, total_width: Int, next_width: Int) raises -> Tuple[String, Bool]:
        """Decides whether another entry fits, and what to show if it does not.

        Args:
            total_width: How wide the view already is.
            next_width: How wide the next entry would be.

        Returns:
            The trailing ellipsis to append, and whether the entry fits. The
            ellipsis is only offered when it fits itself; otherwise the view
            simply stops.

        Raises:
            Error: If styling fails.
        """
        if self.width > 0 and total_width + next_width > self.width:
            var tail = String(" ", self._styled(self.styles.ellipsis, self.ellipsis))
            if total_width + Int(string_width(tail)) < self.width:
                return (tail^, False)
            return (String(), False)
        return (String(), True)

    def short_view(self, bindings: List[Binding]) raises -> String:
        """Renders bindings on a single line.

        Args:
            bindings: The bindings to describe, in the order shown.

        Returns:
            The rendered help, empty if nothing is enabled.

        Raises:
            Error: If styling fails.
        """
        var out = String()
        var total = 0
        var separator = self._styled(self.styles.separator, self.short_separator)

        for ref binding in bindings:
            if not binding.enabled():
                continue

            var entry = String()
            if total > 0:
                entry.write_string(separator)
            entry.write_string(self._styled(self.styles.key, binding.help.key))
            entry.write_string(" ")
            entry.write_string(self._styled(self.styles.desc, binding.help.desc))

            var entry_width = Int(string_width(entry))
            var decision = self._tail(total, entry_width)
            if not decision[1]:
                out.write_string(decision[0])
                break

            total += entry_width
            out.write_string(entry)

        return out

    def full_view(self, groups: List[List[Binding]]) raises -> String:
        """Renders bindings as columns, one column per group.

        Args:
            groups: The binding groups, one per column.

        Returns:
            The rendered help, empty if nothing is enabled.

        Raises:
            Error: If styling fails.
        """
        var columns = List[String]()
        var total = 0
        var separator = self._styled(self.styles.separator, self.full_separator)

        for ref group in groups:
            var keys = List[String]()
            var descs = List[String]()
            for ref binding in group:
                if not binding.enabled():
                    continue
                keys.append(binding.help.key.copy())
                descs.append(binding.help.desc.copy())

            # A column with nothing enabled is dropped rather than left blank.
            if len(keys) == 0:
                continue

            var column = String()
            if total > 0:
                column.write_string(separator)
            column.write_string(
                mog.join_horizontal(
                    mog.Position.TOP,
                    self._styled(self.styles.key, "\n".join(keys)),
                    " ",
                    self._styled(self.styles.desc, "\n".join(descs)),
                )
            )

            var column_width = Int(mog.get_width(column))
            var decision = self._tail(total, column_width)
            if not decision[1]:
                if decision[0].byte_length() > 0:
                    columns.append(decision[0])
                break

            total += column_width
            columns.append(column^)

        if len(columns) == 0:
            return String()
        return mog.join_horizontal(mog.Position.TOP, columns)
