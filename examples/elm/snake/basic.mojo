from banjo.app import Runtime
from termctl.multiplex.kqueue import KQueueSelector
from snake.app import Model, STEP_TIMER


comptime RENDER_HZ = 24.0
"""How often the board is repainted."""
comptime STEP_HZ = 10.0
"""How often the snake advances, independent of the frame rate."""


def main() raises:
    var model = Model()
    var rt = Runtime[Model, KQueueSelector](KQueueSelector(), RENDER_HZ)

    # The snake's speed is its own timer, not a consequence of how fast keys
    # arrive. `on_tick` stays silent unless the game is actually running.
    rt.every(STEP_HZ, STEP_TIMER)

    rt.run(model)
