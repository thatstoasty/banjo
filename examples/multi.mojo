import banjo
from banjo.program import TUI, Model, Cmd, Msg, ExitMsg, KeyMsg
from banjo.msg import exit_msg
from banjo.key import KeyType
import mog
from mog import Position


@value
@register_passable("trivial")
struct State:
    var value: UInt8
    alias START = Self(0)
    alias MENU = Self(1)
    alias END = Self(2)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value


@value
struct BaseModel(Model):
    var last_key: String
    var index: Int
    var state: State

    fn __init__(out self):
        self.last_key = ""
        self.index = 0
        self.state = State.MENU

    fn init(self) -> Cmd:
        return None

    fn update(mut self, msg: Msg) -> Cmd:
        if self.state == State.START:
            if msg.isa[KeyMsg]():
                self.last_key = String(msg[KeyMsg])
                if self.last_key == "q":
                    return Cmd(exit_msg)
                elif msg[KeyMsg] == KeyType.Enter:
                    self.state = State.MENU
            return
        elif self.state == State.MENU:
            if msg.isa[ExitMsg]():
                return
            elif msg.isa[KeyMsg]():
                self.last_key = String(msg[KeyMsg])
                if self.last_key == "q":
                    return Cmd(exit_msg)
                elif msg[KeyMsg] == KeyType.Up:
                    if self.index == 1:
                        self.index -= 1
                elif msg[KeyMsg] == KeyType.Down:
                    if self.index == 0:
                        self.index += 1
                elif msg[KeyMsg] == KeyType.Enter:
                    self.state = State.END
                return
            else:
                return
        elif self.state == State.END:
            if msg.isa[KeyMsg]():
                self.last_key = String(msg[KeyMsg])
                if self.last_key == "q":
                    return Cmd(exit_msg)

        return

    fn view(self) -> String:
        alias border = mog.Style(mog.ASCII).border(mog.ROUNDED_BORDER).padding(0, 1).width(50).height(5).alignment(
            Position.CENTER, Position.CENTER
        )

        if self.state == State.START:
            return border.render("Press Enter to continue\nor\nQ to quit.")
        elif self.state == State.MENU:
            alias left = mog.Style(mog.ASCII).border(mog.ROUNDED_BORDER).padding(0, 1).width(20).height(5)
            alias right = left.alignment(Position.CENTER, Position.CENTER)
            var cursor_a: String = "> " if self.index == 0 else "  "
            var cursor_b: String = "> " if self.index == 1 else "  "
            var lhs = left.render("Options:" + "\n" + cursor_a + "1. Option A\n" + cursor_b + "2. Option B\n")
            var rhs = right.render("Last Key: " + self.last_key)
            return border.render(mog.join_horizontal(Position.CENTER, lhs, rhs))
        elif self.state == State.END:
            return border.render("Press Q to quit.")

        return "Somehow reached an invalid state, please exit the program."


fn main() raises:
    var program = banjo.TUI(BaseModel())
    program.run()
