import banjo
from banjo.program import TUI, Model, Cmd
from banjo.msg import exit_msg, GeneralMsg, Msg, ExitMsg, KeyMsg
from banjo.key import KeyType
from banjo.renderer import Renderer
import mog
from mog import Position


@value
@register_passable("trivial")
struct State(Writable, Stringable):
    var value: UInt8
    alias START = Self(0)
    alias MENU = Self(1)
    alias END = Self(2)

    fn __str__(self) -> String:
        if self == State.START:
            return "START"
        elif self == State.MENU:
            return "MENU"
        elif self == State.END:
            return "END"
        return "Invalid state."

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        writer.write("State(value=", self.value, ")")

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value


fn change_state[state: State]() -> Cmd:
    fn inner() -> Msg:
        return Msg(GeneralMsg(String("StateMsg=", state)))

    return Cmd(inner)


fn change_state_to_menu() -> Msg:
    return Msg(GeneralMsg("StateMsg=State.MENU"))


fn change_state_to_end() -> Msg:
    return Msg(GeneralMsg("StateMsg=State.END"))


@value
struct BaseModel(Model):
    var last_key: String
    var index: Int
    var state: State

    fn __init__(out self):
        self.last_key = ""
        self.index = 0
        self.state = State.START

    fn init(self) -> Cmd:
        return None

    fn update(mut self, msg: Msg) -> Cmd:
        if msg.isa[ExitMsg]():
            return

        if msg.isa[GeneralMsg]():
            if msg[GeneralMsg].value == "StateMsg=State.MENU":
                self.state = State.MENU
                return
            elif msg[GeneralMsg].value == "StateMsg=State.END":
                self.state = State.END
                return

        if self.state == State.START:
            if msg.isa[KeyMsg]():
                if String(msg[KeyMsg]) == "q":
                    return exit_msg
                elif msg[KeyMsg] == KeyType.Enter:
                    # return change_state[State.MENU]()
                    return change_state_to_menu
                return
            return

        elif self.state == State.MENU:
            if msg.isa[KeyMsg]():
                self.last_key = String(msg[KeyMsg])
                if self.last_key == "q":
                    return exit_msg
                elif msg[KeyMsg] == KeyType.Up:
                    if self.index == 1:
                        self.index -= 1
                    return
                elif msg[KeyMsg] == KeyType.Down:
                    if self.index == 0:
                        self.index += 1
                    return
                elif msg[KeyMsg] == KeyType.Enter:
                    return change_state_to_end
                    # return change_state[State.END]()
                return
            else:
                return

        elif self.state == State.END:
            if msg.isa[KeyMsg]():
                self.last_key = String(msg[KeyMsg])
                if self.last_key == "q":
                    return exit_msg

        return

    fn view(self) -> String:
        alias border = mog.Style(mog.ANSI).border_foreground(mog.Color(5)).border(mog.ROUNDED_BORDER).padding(
            0, 1
        ).width(50).height(5).alignment(Position.CENTER, Position.CENTER)

        if self.state == State.START:
            return border.render("Press Enter to continue\nor\nQ to quit.")
        elif self.state == State.MENU:
            alias left = mog.Style(mog.ANSI).border(mog.ROUNDED_BORDER).border_foreground(mog.Color(8)).padding(
                0, 1
            ).width(20).height(5)
            alias right = left.alignment(Position.CENTER, Position.CENTER)
            var cursor_a: String = "> " if self.index == 0 else "  "
            var cursor_b: String = "> " if self.index == 1 else "  "
            var lhs = left.render("Options:" + "\n" + cursor_a + "1. Option A\n" + cursor_b + "2. Option B\n")
            var rhs = right.render("Last Key: " + self.last_key)
            return border.render(mog.join_horizontal(Position.CENTER, lhs, rhs))
        elif self.state == State.END:
            alias option_style = mog.Style(mog.ANSI).foreground(mog.Color(2))
            var option = "Option A" if self.index == 0 else "Option B"
            return border.render("You selected", option_style.render(option), "\nPress Q to quit.")

        return "Somehow reached an invalid state, please exit the program."


fn main() raises:
    var program = banjo.TUI(BaseModel(), renderer=Renderer(24))
    program.run()
