"""The same app as `basic.mojo`, with blocking work moved off the loop.

`TaskGroup` tasks are real threads, so the model and the terminal stay owned by
the runtime alone. The task shares nothing with it but a `Mailbox`, and what it
posts arrives as an ordinary message through `on_result`.

The payoff is visible while the game runs: the spinner keeps turning and the
snake keeps moving at full rate for the whole time the task sits blocked.
"""

from std.runtime.asyncrt import TaskGroup
from std.time import sleep
from banjo.app import Runtime
from banjo.task import Mailbox
from termctl.multiplex.kqueue import KQueueSelector
from snake.app import Model, SPIN_TIMER, STEP_TIMER


comptime RENDER_HZ = 24.0
"""How often the board is repainted."""
comptime STEP_HZ = 10.0
"""How often the snake advances, independent of the frame rate."""
comptime SPIN_HZ = 12.0
"""How often the loading indicator advances while the task is outstanding."""


async def load_best_score[o: MutOrigin](box: Pointer[Mailbox[Int], o]) -> None:
    """Stands in for a blocking call -- a request, a file read, a query.

    This ties up its own thread for two seconds, which is the point: the loop
    never waits on it and stays at full frame rate throughout.

    Parameters:
        o: Origin of the mailbox this task reports to.

    Args:
        box: Where to leave the result for the runtime to collect.
    """
    # Done in slices rather than one long block, so the runtime can call this
    # off. Real blocking work needs the same shape: a chunk, then a check.
    var slices = 40
    while slices > 0:
        if box[].is_cancelled():
            return
        sleep(0.05)
        slices -= 1

    box[].post(1274)


def main() raises:
    var model = Model()
    var rt = Runtime[Model, KQueueSelector](KQueueSelector(), RENDER_HZ)
    rt.every(STEP_HZ, STEP_TIMER)
    rt.every(SPIN_HZ, SPIN_TIMER)

    var tg = TaskGroup()
    tg.create_task(load_best_score(rt.mailbox()))

    rt.run(model)

    # `run` has already cancelled the task, so this join is short.
    tg.wait()
