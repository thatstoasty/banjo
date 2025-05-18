from time import sleep
from sys import stderr, stdin
from runtime.asyncrt import TaskGroup
from banjo.terminal.tty import TTY, Mode
from banjo.renderer import Renderer
from banjo.multiplex.select import EVENT_READ, SelectSelector
from banjo.key import Key, KeyType
from banjo.key_msg import read_events, KeyMsg
from banjo.msg import Msg, ExitMsg, NoMsg


alias CmdFn = fn () -> Msg
"""Function that returns a Msg. This is used to represent commands that can be executed in the TUI."""
alias Cmd = Optional[CmdFn]
"""Command that can be executed in the TUI."""


trait Model(Movable):
    fn init(self) -> Cmd:
        """Initializes the model. This is used to set up the initial state of the model."""
        ...

    fn update(mut self, msg: Msg) -> Cmd:
        """Updates the model with the given message. This is used to update the state of the model."""
        ...

    fn view(self) -> String:
        """Returns the view of the model. This is used to render the model to the terminal."""
        ...


async fn view(tui: TUI) -> None:
    """View loop for the TUI. This is responsible for rendering the view to the terminal.

    Args:
        tui: The TUI instance.
    """
    while True:
        if tui.done:
            break
        tui.renderer.write(tui.model.view())
        sleep(tui.renderer.framerate)


fn handle_msg(mut tui: TUI, msg: Msg) -> None:
    """Handles messages from the TUI.

    Args:
        tui: The TUI instance.
        msg: The message to handle.
    """
    if cmd := tui.model.update(msg):
        handle_msg(tui, cmd.value()())
    return


async fn update(mut tui: TUI) -> None:
    """Update loop for the TUI. This is responsible for handling input and updating the model."""

    var selector = SelectSelector()

    try:
        selector.register(stdin.value, EVENT_READ)
    except e:
        print("Error registering stdin.", e, file=stderr)
        tui.done = True
        return

    while not tui.done:
        try:
            var reader_status = selector.select()[0][1]
            if not reader_status & EVENT_READ:
                continue
        except e:
            print("Error selecting stdin.", e, file=stderr)

        if cmd := tui.model.update(read_events()):
            var msg = cmd.value()()
            if msg.isa[ExitMsg]():
                tui.done = True
                return

            if not msg.isa[NoMsg]():
                handle_msg(tui, msg)


struct TUI[T: Model]:
    """Orchestrates the core logic update and view render loops."""

    var model: T
    """Model containing the state for the TUI."""
    var renderer: Renderer
    """Renderer for the TUI. Controls the framerate and rendering of the TUI."""
    var done: Bool
    """Flag indicating if the TUI is done running. This is used to stop the TUI loop."""

    fn __init__(
        out self,
        owned model: T,
        renderer: Renderer = Renderer(),
    ):
        self.model = model^
        self.renderer = renderer
        self.done = False

    fn run(mut self) raises:
        with TTY[Mode.CBREAK]():
            var tg = TaskGroup()
            tg.create_task(view(self))
            tg.create_task(update(self))
            tg.wait()
