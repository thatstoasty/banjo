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
struct Frames(Copyable):
    """A set of spinner frames and the rate they are meant to run at."""

    var frames: List[String]
    """The frames, shown in order and then repeated."""
    var hz: Float64
    """How many frames per second this set is designed for."""


def line() -> Frames:
    """A rotating bar.

    Returns:
        The frame set.
    """
    return Frames(["|", "/", "-", "\\"], 10.0)


def mini_dot() -> Frames:
    """A single braille dot orbiting.

    Returns:
        The frame set.
    """
    return Frames(
        [
            "⠋",
            "⠙",
            "⠹",
            "⠸",
            "⠼",
            "⠴",
            "⠦",
            "⠧",
            "⠇",
            "⠏",
        ],
        12.0,
    )


def dot() -> Frames:
    """A braille block cycling.

    Returns:
        The frame set.
    """
    return Frames(
        [
            "⣾",
            "⣽",
            "⣻",
            "⢿",
            "⡿",
            "⣟",
            "⣯",
            "⣷",
        ],
        10.0,
    )


def jump() -> Frames:
    """A dot bouncing along a line.

    Returns:
        The frame set.
    """
    return Frames(
        ["⢄", "⢂", "⢁", "⡁", "⡈", "⡐", "⡠"],
        10.0,
    )


def pulse() -> Frames:
    """A block fading in and out.

    Returns:
        The frame set.
    """
    return Frames(["█", "▓", "▒", "░"], 8.0)


def points() -> Frames:
    """A dot travelling across three positions.

    Returns:
        The frame set.
    """
    return Frames(["∙∙∙", "●∙∙", "∙●∙", "∙∙●"], 7.0)


def meter() -> Frames:
    """A three-segment meter filling and emptying.

    Returns:
        The frame set.
    """
    return Frames(
        [
            "▱▱▱",
            "▰▱▱",
            "▰▰▱",
            "▰▰▰",
            "▰▰▱",
            "▰▱▱",
        ],
        7.0,
    )


def moon() -> Frames:
    """The phases of the moon.

    Returns:
        The frame set.
    """
    return Frames(
        [
            "🌑",
            "🌒",
            "🌓",
            "🌔",
            "🌕",
            "🌖",
            "🌗",
            "🌘",
        ],
        8.0,
    )


struct Spinner(Copyable):
    """A spinner and the frame it is currently showing."""

    var frames: Frames
    """The frame set being animated."""
    var frame: Int
    """Which frame is showing."""
    var style: Optional[mog.Style]
    """How the frame is drawn."""

    def __init__(out self, var frames: Frames = line()):
        """Creates a spinner on its first frame.

        Args:
            frames: The frame set to animate.
        """
        self.frames = frames^
        self.frame = 0
        self.style = None

    def hz(self) -> Float64:
        """Returns the rate this spinner's frames are designed for.

        Pass it to `Runtime.every` so the animation runs at its intended speed.

        Returns:
            Frames per second.
        """
        return self.frames.hz

    def advance(mut self):
        """Moves to the next frame, wrapping at the end."""
        if len(self.frames.frames) == 0:
            return
        self.frame = (self.frame + 1) % len(self.frames.frames)

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
        if len(self.frames.frames) == 0:
            return String()

        # Defensive: the frame set can be swapped for a shorter one between
        # ticks, which would otherwise leave the index out of range.
        var index = self.frame % len(self.frames.frames)
        if self.style:
            return self.style.value().render(self.frames.frames[index])
        return self.frames.frames[index].copy()
