from time import sleep
from utils.variant import Variant
from sys import stdout
from mist.terminal.tty import TTY, Mode
from mist.event.read import EventReader
from mist.event.event import KeyType,KeyEvent, Event, Char, Enter, Up, Down
import mog
from mog import Position, Profile
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
struct State(ImplicitlyCopyable, Writable):
    var value: UInt8
    comptime START = Self(0)
    comptime MENU = Self(1)
    comptime END = Self(2)

    fn write_to(self, mut writer: Some[Writer]) -> None:
        writer.write("State(value=", self.value, ")")

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value


@fieldwise_init
struct Msg(ImplicitlyCopyable):
    var value: Variant[KeyEvent, Exit, Increment, Decrement, State]
    """Internal value representing the message. It can be one of the following types: ExitMsg, KeyMsg, FocusMsg, BlurMsg, UnknownInputByteMsg, GeneralMsg, or NoMsg."""

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


comptime LEFT = mog.Style(
    Profile.ANSI,
    width=20,
    height=5,
    border=mog.ROUNDED_BORDER,
    padding=mog.Padding(1, 0),
).border_foreground(mog.Color(8))
comptime RIGHT = LEFT.text_alignment(Position.CENTER)
comptime BORDER = mog.Style(
    Profile.ANSI,
    width=50,
    height=5,
    padding=mog.Padding(1, 0),
    alignment=mog.Alignment(Position.CENTER),
    border=mog.ROUNDED_BORDER,
).border_foreground(mog.Color(5))
comptime OPTION = mog.Style(Profile.ANSI, foreground=mog.Color(2))


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
        if self.state == State.START:
            return BORDER.render("Press Enter to continue\nor\nQ to quit.")
        elif self.state == State.MENU:
            var cursor_a: String = "> " if self.index == 0 else "  "
            var cursor_b: String = "> " if self.index == 1 else "  "
            var lhs = LEFT.render("Options:" + "\n" + cursor_a + "1. Option A\n" + cursor_b + "2. Option B\n")
            var rhs = RIGHT.render("Last Key: " + self.last_key)
            return BORDER.render(mog.join_horizontal(Position.CENTER, lhs, rhs))
        elif self.state == State.END:
            var option = "Option A" if self.index == 0 else "Option B"
            return BORDER.render("You selected", OPTION.render(option), "\nPress Q to quit.")

        return "Somehow reached an invalid state, please exit the program."
