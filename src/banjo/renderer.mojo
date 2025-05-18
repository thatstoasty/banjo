from banjo.terminal.cursor import clear_screen, move_cursor


@value
@register_passable("trivial")
struct Renderer:
    """A simple renderer that prints to the terminal."""

    var framerate: Float64
    """The framerate of the renderer in terms of `1 / fps`."""

    fn __init__(out self, fps: Float64 = 30.0):
        """Initializes the renderer with the given framerate.

        Args:
            fps: The framerate of the renderer in frames per second.
        """
        self.framerate = 1.0 / fps

    fn write(self, input: String) -> None:
        """Writes the given input to the terminal.

        Args:
            input: The input to write to the terminal.
        """
        clear_screen()
        move_cursor(1, 1)
        print(input, end="")
