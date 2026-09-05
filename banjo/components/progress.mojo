"""A progress bar.

A port of `bubbles/progress`, reduced to what `banjo` and `mog` can express.

Two things are deliberately absent. Go animates towards a target percentage
with a spring simulation, rescheduling itself through `tea.Cmd`; `banjo` has no
commands, and animation belongs to the application, which can step a percentage
from `on_tick` exactly as it steps a spinner. Go also renders a gradient across
the filled portion using `lipgloss.Blend1D`, which `mog` has no equivalent of.

What is left is a pure function of a percentage, which is also how ratatui's
`Gauge` works.

```mojo
var bar = ProgressBar(width=40)
return bar.view(0.42)
```
"""

import mog
from mist.transform.ansi import string_width


struct ProgressBar(Copyable, Movable):
    """Draws a proportion of a fixed width as a filled bar."""

    var width: Int
    """The total width of the bar, including the percentage if it is shown."""
    var full_char: String
    """Drawn for the filled portion."""
    var empty_char: String
    """Drawn for the remainder."""
    var show_percentage: Bool
    """Whether the percentage is written after the bar."""
    var full_style: Optional[mog.Style]
    """How the filled portion is drawn."""
    var empty_style: Optional[mog.Style]
    """How the remainder is drawn."""
    var percentage_style: Optional[mog.Style]
    """How the percentage is drawn."""

    def __init__(out self, width: Int = 40):
        """Creates a bar of the given width.

        Args:
            width: The total width, including the percentage if shown.
        """
        self.width = width
        self.full_char = String("█")
        self.empty_char = String("░")
        self.show_percentage = True
        self.full_style = None
        self.empty_style = None
        self.percentage_style = None

    def _percentage_text(self, percent: Float64) -> String:
        """Formats the percentage as it appears after the bar.

        Args:
            percent: The proportion filled, from zero to one.

        Returns:
            The percentage text, with a leading space.
        """
        var whole = Int(percent * 100.0 + 0.5)
        if whole < 0:
            whole = 0
        if whole > 100:
            whole = 100
        return String(" ", whole, "%")

    def view(self, percent: Float64) raises -> String:
        """Draws the bar at the given proportion.

        Args:
            percent: The proportion filled. Values outside zero to one are
                clamped, so a caller need not guard its own arithmetic.

        Returns:
            The rendered bar.

        Raises:
            Error: If styling fails.
        """
        var ratio = percent
        if ratio < 0.0:
            ratio = 0.0
        if ratio > 1.0:
            ratio = 1.0

        var text = String()
        if self.show_percentage:
            text = self._percentage_text(ratio)

        var bar_width = self.width - Int(string_width(text))
        if bar_width < 0:
            bar_width = 0

        var filled = Int(Float64(bar_width) * ratio + 0.5)
        if filled > bar_width:
            filled = bar_width
        if filled < 0:
            filled = 0

        var full = String()
        for _ in range(filled):
            full.write_string(self.full_char)

        var empty = String()
        for _ in range(bar_width - filled):
            empty.write_string(self.empty_char)

        var out = String()
        if self.full_style and full.byte_length() > 0:
            out.write_string(self.full_style.value().render(full))
        else:
            out.write_string(full)

        if self.empty_style and empty.byte_length() > 0:
            out.write_string(self.empty_style.value().render(empty))
        else:
            out.write_string(empty)

        if self.show_percentage:
            if self.percentage_style:
                out.write_string(self.percentage_style.value().render(text))
            else:
                out.write_string(text)

        return out
