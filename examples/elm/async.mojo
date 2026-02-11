from time import sleep
from utils.variant import Variant
from sys import stdout
from runtime.asyncrt import TaskGroup
from mist.terminal.tty import TTY, Mode
from mist.event.read import EventReader
from mist.event.event import KeyType,KeyEvent, Event, Char, Enter, Up, Down
import mog
from mog import Position
from banjo.renderer import Renderer


@fieldwise_init
@register_passable("trivial")
struct Exit(ImplicitlyCopyable):
    var dummy: Bool

    fn __init__(out self):
        self.dummy = True


@fieldwise_init
@register_passable("trivial")
struct Increment(ImplicitlyCopyable):
    var dummy: Bool

    fn __init__(out self):
        self.dummy = True


@fieldwise_init
@register_passable("trivial")
struct Decrement(ImplicitlyCopyable):
    var dummy: Bool

    fn __init__(out self):
        self.dummy = True


@fieldwise_init
@register_passable("trivial")
struct State(ImplicitlyCopyable, Writable, Stringable):
    var value: UInt8
    comptime START = Self(0)
    comptime MENU = Self(1)
    comptime END = Self(2)

    fn __str__(self) -> String:
        if self == State.START:
            return "START"
        elif self == State.MENU:
            return "MENU"
        elif self == State.END:
            return "END"
        return "Invalid state."

    fn write_to(self, mut writer: Some[Writer]) -> None:
        writer.write("State(value=", self.value, ")")

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value


@fieldwise_init
struct Msg(ImplicitlyCopyable, Writable):
    var value: Variant[KeyEvent, Exit, Increment, Decrement, State]
    """Internal value representing the message. It can be one of the following types: ExitMsg, KeyMsg, FocusMsg, BlurMsg, UnknownInputByteMsg, GeneralMsg, or NoMsg."""

    @implicit
    fn __init__(out self, value: KeyEvent):
        """Initializes the message with a KeyEvent.

        Args:
            value: The `KeyEvent` to initialize the message with.
        """
        self.value = value.copy()

    @implicit
    fn __init__(out self, value: Exit):
        """Initializes the message with a Exit.

        Args:
            value: The `Exit` to initialize the message with.
        """
        self.value = value

    @implicit
    fn __init__(out self, value: State):
        """Initializes the message with a State.

        Args:
            value: The `State` to initialize the message with.
        """
        self.value = value

    @implicit
    fn __init__(out self, value: Increment):
        """Initializes the message with a Increment.

        Args:
            value: The `Increment` to initialize the message with.
        """
        self.value = value

    @implicit
    fn __init__(out self, value: Decrement):
        """Initializes the message with a Decrement.

        Args:
            value: The `Decrement` to initialize the message with.
        """
        self.value = value

    fn write_to(self, mut writer: Some[Writer]) -> None:
        """Writes the message to the writer.

        Args:
            writer: The writer to write the message to.
        """
        if self.value.isa[KeyEvent]():
            writer.write(self.value[KeyEvent].code[Char])

    fn isa[T: Copyable](self) -> Bool:
        """Checks if the message is of type T.

        Parameters:
            T: The type to check against. It must be a Movable and Copyable type.

        Returns:
            True if the message is of type T, False otherwise.
        """
        return self.value.isa[T]()

    fn __getitem__[T: Copyable](ref self) -> ref [origin_of(self.value)] T:
        """Gets the value of the message as type T.

        Parameters:
            T: The type to get the value as. It must be a Movable and Copyable type.

        Returns:
            The value of the message as type T.
        """
        return self.value[T]


fn handle_event(event: Event) raises -> Optional[Msg]:
    """Handles events from the TUI.

    Args:
        event: The event to handle.

    Returns:
        An optional message to update the model with. This can be None if no update is needed.
    """
    if event.isa[KeyEvent]():
        if event[KeyEvent].code.isa[Char]() and event[KeyEvent].code[Char] == "q":
            return Msg(Exit())
        elif event[KeyEvent].code.isa[Up]():
            return Msg(Decrement())
        elif event[KeyEvent].code.isa[Down]():
            return Msg(Increment())
        else:
            return Msg(event[KeyEvent])
    return


async fn view(mut model: Model) -> None:
    """View loop for the TUI. This is responsible for rendering the view to the terminal.

    Args:
        model: The TUI instance.
    """
    # var i = 0
    while not model.done:
        # print("Rendering view", i)
        model.renderer.write(model.view())
        # print("Render complete", i)
        # sleep(1 / model.renderer.framerate)
        # print("Sleep complete", i)
        # i += 1


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


@fieldwise_init
struct Model(Movable):
    var last_key: String
    var index: Int
    var state: State
    var done: Bool
    """Flag indicating if the TUI is done running. This is used to stop the TUI loop."""
    var renderer: Renderer
    """Renderer for the TUI. Controls the framerate and rendering of the TUI."""

    fn __init__(out self):
        self.last_key = ""
        self.index = 0
        self.state = State.START
        self.done = False
        self.renderer = Renderer(stdout, 24)

    fn update(mut self, msg: Msg) -> Optional[Msg]:
        if msg.isa[Exit]():
            self.done = True
            return
        elif msg.isa[State]():
            if msg[State] == State.MENU:
                self.state = State.MENU
                return
            elif msg[State] == State.END:
                self.state = State.END
                return
        elif msg.isa[KeyEvent]() and msg[KeyEvent].code.isa[Char]():
            self.last_key = String(msg[KeyEvent].code[Char])

        if self.state == State.START:
            # print("In START state")
            if msg.isa[KeyEvent]() and msg[KeyEvent].code.isa[Enter]():
                return Msg(State.MENU)
            return
        elif self.state == State.MENU:
            if msg.isa[Increment]():
                if self.index == 0:
                    self.index += 1
                return
            elif msg.isa[Decrement]():
                if self.index == 1:
                    self.index -= 1
                return
            elif msg.isa[KeyEvent]() and msg[KeyEvent].code.isa[Enter]():
                return Msg(State.END)
            return
        return

    fn view(self) -> String:
        var border = mog.Style(
            width=50,
            height=5,
            padding=mog.Padding(1, 0),
            alignment=mog.Alignment(Position.CENTER),
            border=mog.ROUNDED_BORDER,
        ).set_border_foreground(mog.Color(5))

        if self.state == State.START:
            return border.render("Press Enter to continue\nor\nQ to quit.")
        elif self.state == State.MENU:
            comptime left = mog.Style(
                mog.Profile.ANSI,
                width=20,
                height=5,
                border=mog.ROUNDED_BORDER,
                padding=mog.Padding(1, 0),
            ).set_border_foreground(mog.Color(8))
            comptime right = left.set_text_alignment(Position.CENTER)
            var cursor_a: String = "> " if self.index == 0 else "  "
            var cursor_b: String = "> " if self.index == 1 else "  "
            var lhs = left.render("Options:" + "\n" + cursor_a + "1. Option A\n" + cursor_b + "2. Option B\n")
            var rhs = right.render("Last Key: " + self.last_key)
            return border.render(mog.join_horizontal(Position.CENTER, lhs, rhs))
        elif self.state == State.END:
            comptime option_style = mog.Style(mog.Profile.ANSI, foreground=mog.Color(2))
            var option = "Option A" if self.index == 0 else "Option B"
            return border.render("You selected", option_style.render(option), "\nPress Q to quit.")

        return "Somehow reached an invalid state, please exit the program."


fn main() raises:
    var tui = Model()
    var tg = TaskGroup()
    with TTY[Mode.RAW]():
        tg.create_task(view(tui))
        tg.create_task(update(tui))
        tg.wait()
