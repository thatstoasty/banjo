from sys import stderr
from time import sleep

from banjo.key import Key, KeyType
from banjo.key_msg import KeyMsg, read_events
from banjo.msg import ExitMsg, Msg, NoMsg
from banjo.multiplex.select import Event, SelectSelector
from banjo.renderer import Renderer
from mist.terminal.tty import TTY, Mode
from runtime.asyncrt import TaskGroup


comptime CmdFn = fn () -> Msg
"""Function that returns a Msg. This is used to represent commands that can be executed in the TUI."""
comptime Cmd = Optional[CmdFn]
"""Command that can be executed in the TUI."""


trait Model(Movable):
    """Trait for the model in the TUI. This defines the interface that all models must implement."""

    fn init(self) -> Cmd:
        """Initializes the model. This is used to set up the initial state of the model.

        Returns:
            A command that can be executed in the TUI, or None if no command is needed.
        """
        ...

    fn update(mut self, msg: Msg) -> Cmd:
        """Updates the model with the given message. This is used to update the state of the model.

        Args:
            msg: The message to update the model with. This can be a key press, focus change, etc.

        Returns:
            A command that can be executed in the TUI, or None if no command is needed.
        """
        ...

    fn view(self) -> String:
        """Returns the view of the model. This is used to render the model to the terminal.

        Returns:
            The view of the model as a string.
        """
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
        sleep(1 / tui.renderer.framerate)


fn handle_msg(mut tui: TUI, msg: Msg) -> None:
    """Handles messages from the TUI.

    Args:
        tui: The TUI instance.
        msg: The message to handle.
    """
    if cmd := tui.model.update(msg):
        handle_msg(tui, cmd.value()())
    return


async fn update(mut tui: TUI, tty: TTY) -> None:
    """Update loop for the TUI. This is responsible for handling input and updating the model.

    Args:
        tui: The TUI instance.
        tty: The TTY instance for reading input.
    """
    var selector = SelectSelector()
    selector.register(tty.fd, Event.READ)

    while not tui.done:
        var status: Optional[Event]
        try:
            # First checks if the file descriptor is ready.
            # If so, checks if the response is either `Event.READ` or `Event.READ_WRITE`
            status = selector.select().get(tty.fd.value)
        except e:
            print("Error selecting stdin.", e, file=stderr)
            tui.done = True
            return

        if not status:
            continue

        # We just checked that the optional is not None, so we can safely check the value.
        if not status.unsafe_value() & Event.READ:
            continue

        if cmd := tui.model.update(read_events()):
            var msg = cmd.value()()
            if msg.isa[ExitMsg]():
                tui.done = True
                return

            if not msg.isa[NoMsg]():
                handle_msg(tui, msg)


struct TUI[T: Model]:
    """Orchestrates the core logic update and view render loops.

    Parameters:
        T: The type of the model that implements the `Model` trait.
    """

    var model: T
    """Model containing the state for the TUI."""
    var renderer: Renderer
    """Renderer for the TUI. Controls the framerate and rendering of the TUI."""
    var done: Bool
    """Flag indicating if the TUI is done running. This is used to stop the TUI loop."""

    fn __init__(
        out self,
        var model: T,
        renderer: Renderer = Renderer(24),
    ):
        """Initializes the TUI with a model and a renderer.

        Args:
            model: The model to use for the TUI.
            renderer: The renderer to use for the TUI. Defaults to a Renderer with a framerate of 24.
        """
        self.model = model^
        self.renderer = renderer
        self.done = False

    fn run(mut self) raises:
        """Runs the TUI. This starts the view and update loops."""
        # TODO (Mikhail): This should be RAW mode, but it breaks the TUI.
        # I must have some other issue that causes unblocking reads to be problematic.
        with TTY[Mode.CBREAK]() as tty:
            var tg = TaskGroup()
            tg.create_task(view(self))
            tg.create_task(update(self, tty))
            tg.wait()
