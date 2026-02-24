from runtime.asyncrt import TaskGroup
from mist.terminal.tty import TTY, Mode
from mist.event.read import EventReader
from sample.app import Model, handle_event


async fn view(model: Model) -> None:
    """View loop for the TUI. This is responsible for rendering the view to the terminal.

    Args:
        model: The TUI instance.
    """
    var renderer = model.renderer.copy()
    while not model.done:
        renderer.write(model.view())


async fn update(mut model: Model) -> None:
    """Update loop for the TUI. This is responsible for handling input and updating the model.

    Args:
        model: The TUI instance.
    """
    try:
        var reader = EventReader()
        while not model.done:
            var msg = handle_event(reader.read())
            if msg:
                while True:
                    msg = model.update(msg.value())
                    if not msg:
                        break
    except e:
        print(e)
        return


fn main() raises:
    var tui = Model()
    var tg = TaskGroup()
    with TTY[Mode.RAW]():
        tg.create_task(view(tui))
        tg.create_task(update(tui))
        tg.wait()
