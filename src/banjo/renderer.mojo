from mist.terminal.cursor import clear_screen, move_cursor


@fieldwise_init
@register_passable("trivial")
struct Renderer(Copyable, ExplicitlyCopyable, Movable):
    """A simple renderer that prints to the terminal."""

    var framerate: Float64
    """The framerate of the renderer in frames per second."""

    fn write(self, input: String) -> None:
        """Writes the given input to the terminal.

        Args:
            input: The input to write to the terminal.
        """
        clear_screen()
        print(input, end="")
