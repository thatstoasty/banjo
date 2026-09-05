"""The same app as `basic.mojo`, with blocking work moved off the loop.

`TaskGroup` tasks are real threads, so the model and the terminal stay owned by
the runtime alone. The task shares nothing with it but a `Mailbox`, and what it
posts arrives as an ordinary message through `on_result`.

The payoff is visible immediately: the spinner keeps turning and the menu stays
fully responsive for the whole time the task sits blocked.
"""

from std.runtime.asyncrt import TaskGroup
from std.time import sleep
from banjo.app import Runtime
from banjo.task import Mailbox
from termctl.multiplex.kqueue import KQueueSelector
from sample.app import Model, SPIN_TIMER


comptime RENDER_HZ = 60.0
"""The ceiling on repaints."""
comptime SPIN_HZ = 12.0
"""How often the loading indicator advances while the task is outstanding."""


async def load_session[o: MutOrigin](box: Pointer[Mailbox, o]) -> None:
    """Stands in for a blocking call -- a request, a file read, a query.

    This ties up its own thread for two seconds, which is the point: the loop
    never waits on it and stays fully responsive throughout.

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

    box[].post(42)


def main() raises:
    var model = Model()
    var rt = Runtime[Model, KQueueSelector](KQueueSelector(), RENDER_HZ)
    rt.every(SPIN_HZ, SPIN_TIMER)

    var tg = TaskGroup()
    tg.create_task(load_session(rt.mailbox()))

    rt.run(model)

    # `run` has already cancelled the task, so this join is short.
    tg.wait()
