from std.time import sleep
from std.utils.variant import Variant
from termctl.terminal.tty import TTY, Mode
from termctl.event.read import EventReader
from termctl.event.event import KeyType,KeyEvent, Event, Char, Enter, Up, Down
import mog
from mog import Position, Profile
from banjo.app import Program


trait MsgType(Writable, Equatable):
    ...


@fieldwise_init
struct Exit(TrivialRegisterPassable, MsgType):
    pass


@fieldwise_init
struct Increment(TrivialRegisterPassable, MsgType):
    pass


@fieldwise_init
struct Decrement(TrivialRegisterPassable, MsgType):
    pass


@fieldwise_init
struct Spin(TrivialRegisterPassable, MsgType):
    """Advances the loading indicator one frame."""

    pass


@fieldwise_init
struct Loaded(TrivialRegisterPassable, MsgType):
    """A background task's result, on its way into the model."""

    var session: Int


@fieldwise_init
struct State(TrivialRegisterPassable, MsgType):
    var value: UInt8
    comptime START = Self(0)
    comptime MENU = Self(1)
    comptime END = Self(2)


@fieldwise_init
struct Msg(ImplicitlyCopyable):
    var value: Variant[KeyEvent, Exit, Increment, Decrement, Spin, Loaded, State]
    """Internal value representing the message. It can be one of the following types: ExitMsg, KeyMsg, FocusMsg, BlurMsg, UnknownInputByteMsg, GeneralMsg, or NoMsg."""

    def isa[T: Copyable](self) -> Bool:
        """Checks if the message is of type T.

        Parameters:
            T: The type to check against. It must be a Movable and Copyable type.

        Returns:
            True if the message is of type T, False otherwise.
        """
        return self.value.isa[T]()

    def __getitem_param__[T: Copyable](ref self) -> ref[origin_of(self.value)._get_owned_interior["value"]] T:
        """Gets the value of the message as type T.

        Parameters:
            T: The type to get the value as. It must be a Movable and Copyable type.

        Returns:
            The value of the message as type T.
        """
        return self.value[T]


def handle_event(event: Event) raises -> Optional[Msg]:
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
comptime SPIN_TIMER = 0
"""Tag for the timer that advances the loading indicator."""
comptime SPINNER = StaticString("|/-\\")
"""Frames of the loading indicator."""


@fieldwise_init
struct Model(Program):
    comptime Msg = Msg

    var last_key: String
    var index: Int
    var state: State
    var done: Bool
    """Flag indicating if the TUI is done running. This is used to stop the TUI loop."""
    var session: Optional[Int]
    """Session id, once the background task reports it."""
    var spin: Int
    """Frame counter for the loading indicator."""

    def __init__(out self):
        self.last_key = ""
        self.index = 0
        self.state = State.START
        self.done = False
        self.session = None
        self.spin = 0

    @staticmethod
    def on_event(event: Event) raises -> Optional[Msg]:
        """Translates a terminal event into a message.

        Args:
            event: The event read from the terminal.

        Returns:
            The message to apply, or None to ignore the event.

        Raises:
            Error: If the event cannot be interpreted.
        """
        return handle_event(event)

    def on_tick(mut self, tag: Int) raises -> Optional[Msg]:
        """Decides what each registered timer means right now.

        Once the session has landed there is nothing left to animate, so this
        goes quiet and the runtime stops rebuilding an unchanged frame.

        Args:
            tag: The tag the timer was registered with.

        Returns:
            The message to apply, or None to let this tick pass.
        """
        if tag == SPIN_TIMER and not self.session:
            return Msg(Spin())
        return None

    def on_result(mut self, value: Int) raises -> Optional[Msg]:
        """Turns the background task's result into a message.

        Args:
            value: The session id the task reported.

        Returns:
            The message carrying it into the model.
        """
        return Msg(Loaded(value))

    def is_done(self) -> Bool:
        """Reports whether the app has been quit.

        Returns:
            True once the user has pressed q.
        """
        return self.done

    def update(mut self, msg: Msg) raises -> Optional[Msg]:
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
        elif msg.isa[Spin]():
            self.spin += 1
            return
        elif msg.isa[Loaded]():
            self.session = msg[Loaded].session
            return
        elif msg.isa[KeyEvent]():
            self.last_key = String(msg[KeyEvent])

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

    def session_view(self) -> String:
        """Renders the session id, or the indicator while it is still loading.

        Returns:
            A one-line status string.
        """
        if self.session:
            return String("Session: ", self.session.value())
        if self.spin == 0:
            # No spin timer has ticked, so nothing is loading -- this app was
            # started without a background task. Say nothing rather than
            # showing an indicator that will never resolve.
            return String()
        return String(SPINNER[byte = self.spin % 4], " connecting...")

    def view(self) raises -> String:
        if self.state == State.START:
            return BORDER.render(String("Press Enter to continue\nor\nQ to quit.\n", self.session_view()))
        elif self.state == State.MENU:
            var cursor_a: String = "> " if self.index == 0 else "  "
            var cursor_b: String = "> " if self.index == 1 else "  "
            var lhs = LEFT.render("Options:" + "\n" + cursor_a + "1. Option A\n" + cursor_b + "2. Option B\n")
            var rhs = RIGHT.render(String("Last Key: ", self.last_key, "\n", self.session_view()))
            return BORDER.render(mog.join_horizontal(Position.CENTER, lhs, rhs))
        elif self.state == State.END:
            var option = "Option A" if self.index == 0 else "Option B"
            return BORDER.render("You selected", OPTION.render(option), "\nPress Q to quit.")

        return "Somehow reached an invalid state, please exit the program."
