from banjo.key import KeyType
from banjo.msg import ExitMsg, GeneralMsg, KeyMsg, Msg, exit_msg
from banjo.program import TUI, Cmd, Model
from banjo.renderer import Renderer

import banjo


@fieldwise_init
@register_passable("trivial")
struct State(Writable, Stringable):
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


@fieldwise_init
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
        if self.state == State.START:
            return "Press Enter to continue\nor\nQ to quit."
        elif self.state == State.MENU:
            var cursor_a: String = "> " if self.index == 0 else "  "
            var cursor_b: String = "> " if self.index == 1 else "  "
            return (
                "Options:"
                + "\n"
                + cursor_a
                + "1. Option A\n"
                + cursor_b
                + "2. Option B\n"
                + "Last Key: "
                + self.last_key
            )
        elif self.state == State.END:
            var option = "Option A" if self.index == 0 else "Option B"
            return "You selected " + option + "\nPress Q to quit."

        return "Somehow reached an invalid state, please exit the program."


fn main() raises:
    var program = banjo.TUI(BaseModel(), renderer=Renderer(24))
    program.run()
