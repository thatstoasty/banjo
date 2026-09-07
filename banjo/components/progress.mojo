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
from banjo.constants import SMALL_BUFFER_SIZE


def _write_percentage_text(percent: Float64, mut text: String):
    """Formats the percentage as it appears after the bar.

    Args:
        percent: The proportion filled, from zero to one.
        text: The string to write into.
    """
    var whole = Int(percent * 100.0 + 0.5)
    if whole < 0:
        whole = 0
    if whole > 100:
        whole = 100
    text.write(" ", whole, "%")


struct ProgressBar(Copyable):
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

    def __init__(
        out self,
        width: Int = 40,
        full_char: String = "█",
        empty_char: String = "░",
        full_style: Optional[mog.Style] = None,
        empty_style: Optional[mog.Style] = None,
        percentage_style: Optional[mog.Style] = None,
        *,
        show_percentage: Bool = True,
    ):
        """Creates a bar of the given width.

        Args:
            width: The total width, including the percentage if shown.
            full_char: The character to draw for the filled portion.
            empty_char: The character to draw for the remainder.
            full_style: How to style the filled portion.
            empty_style: How to style the remainder.
            percentage_style: How to style the percentage.
            show_percentage: Whether to write the percentage after the bar.
        """
        self.width = width
        self.full_char = full_char
        self.empty_char = empty_char
        self.show_percentage = show_percentage
        self.full_style = full_style
        self.empty_style = empty_style
        self.percentage_style = percentage_style

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

        var text = String(capacity=SMALL_BUFFER_SIZE)
        if self.show_percentage:
            _write_percentage_text(ratio, text)

        var bar_width = self.width - Int(string_width(text))
        if bar_width < 0:
            bar_width = 0

        var filled = Int(Float64(bar_width) * ratio + 0.5)
        if filled > bar_width:
            filled = bar_width
        if filled < 0:
            filled = 0

        var full = String(capacity=SMALL_BUFFER_SIZE)
        for _ in range(filled):
            full.write_string(self.full_char)

        var empty = String(capacity=SMALL_BUFFER_SIZE)
        for _ in range(bar_width - filled):
            empty.write_string(self.empty_char)

        var out = String(capacity=SMALL_BUFFER_SIZE)
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

        return out^
