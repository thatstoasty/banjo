from time import sleep
from mist.screen import clear_screen, move_cursor


@value
@register_passable("trivial")
struct Renderer:
    var framerate: Float64

    fn __init__(out self, fps: Float64 = 30.0):
        self.framerate = 1.0 / fps

    fn write(self, input: String):
        clear_screen()
        move_cursor(1, 1)
        print(input, end="")
