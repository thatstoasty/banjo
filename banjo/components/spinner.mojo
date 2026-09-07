"""An animated spinner.

A port of `bubbles/spinner`, minus its timing machinery. Go's spinner owns a
`tea.Cmd` that reschedules itself at the spinner's FPS. `banjo` already has a
scheduler -- `Runtime.every` -- so this holds frames and an index, and the
application drives it:

```mojo
rt.every(SPIN_HZ, SPIN_TIMER)

# in on_tick:
if tag == SPIN_TIMER:
    return Msg(Spin())

# in update:
self.spinner.advance()
```

Each frame set carries the rate `bubbles` animates it at, so an application can
register the timer without inventing a number.
"""

import mog


@fieldwise_init
struct Frames(ImplicitlyCopyable, Sized, Writable):
    """A set of spinner frames and the rate they are meant to run at."""

    var frames: List[String]
    """The frames, shown in order and then repeated."""
    var hz: Float64
    """How many frames per second this set is designed for."""

    comptime LINE = Self(["|", "/", "-", "\\"], 10.0)
    """A rotating bar."""
    comptime MINI_DOT = Self(["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"], 12.0)
    """A single braille dot orbiting."""
    comptime DOT = Self(["⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"], 10.0)
    """A braille block cycling."""
    comptime JUMP = Self(["⢄", "⢂", "⢁", "⡁", "⡈", "⡐", "⡠"], 10.0)
    """A dot bouncing along a line."""
    comptime PULSE = Self(["█", "▓", "▒", "░"], 8.0)
    """A block fading in and out."""
    comptime POINTS = Self(["∙∙∙", "●∙∙", "∙●∙", "∙∙●"], 7.0)
    """A dot travelling across three positions."""
    comptime METER = Self(["▱▱▱", "▰▱▱", "▰▰▱", "▰▰▰", "▰▰▱", "▰▱▱"], 7.0)
    """A three-segment meter filling and emptying."""
    comptime MOON = Self(["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"], 8.0)
    """The phases of the moon."""

    def __init__(out self, *, copy: Self):
        """Creates a copy of another frame set.

        Args:
            copy: The frame set to copy.
        """
        self.frames = copy.frames.copy()
        self.hz = copy.hz

    def __len__(self) -> Int:
        """Returns how many frames are in this set.

        Returns:
            The frame count.
        """
        return len(self.frames)


struct Spinner(ImplicitlyCopyable):
    """A spinner and the frame it is currently showing."""

    var frames: Frames
    """The frame set being animated."""
    var frame: UInt
    """Which frame is showing."""
    var style: Optional[mog.Style]
    """How the frame is drawn."""

    comptime LINE = Self(Frames.LINE)
    """A rotating bar."""
    comptime MINI_DOT = Self(Frames.MINI_DOT)
    """A single braille dot orbiting."""
    comptime DOT = Self(Frames.DOT)
    """A braille block cycling."""
    comptime JUMP = Self(Frames.JUMP)
    """A dot bouncing along a line."""
    comptime PULSE = Self(Frames.PULSE)
    """A block fading in and out."""
    comptime POINTS = Self(Frames.POINTS)
    """A dot travelling across three positions."""
    comptime METER = Self(Frames.METER)
    """A three-segment meter filling and emptying."""
    comptime MOON = Self(Frames.MOON)
    """The phases of the moon."""

    def __init__(out self, var frames: Frames = Frames.LINE, style: Optional[mog.Style] = None):
        """Creates a spinner on its first frame.

        Args:
            frames: The frame set to animate.
            style: Text styler.
        """
        self.frames = frames^
        self.frame = 0
        self.style = style

    def hz(self) -> Float64:
        """Returns the rate this spinner's frames are designed for.

        Pass it to `Runtime.every` so the animation runs at its intended speed.

        Returns:
            Frames per second.
        """
        return self.frames.hz

    def advance(mut self):
        """Moves to the next frame, wrapping at the end."""
        if len(self.frames) == 0:
            return
        self.frame = (self.frame + 1) % UInt(len(self.frames))

    def reset(mut self):
        """Returns to the first frame."""
        self.frame = 0

    def view(self) raises -> String:
        """Draws the current frame.

        Returns:
            The rendered frame, empty if the frame set is.

        Raises:
            Error: If styling fails.
        """
        if len(self.frames) == 0:
            return String()

        # Defensive: the frame set can be swapped for a shorter one between
        # ticks, which would otherwise leave the index out of range.
        var index = self.frame % UInt(len(self.frames))
        if self.style:
            return self.style.value().render(self.frames.frames[index])
        return self.frames.frames[index].copy()
