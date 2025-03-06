import banjo
from banjo.program import TUI, Model, Cmd, Msg, ExitMsg, KeyMsg, exit_msg
import mog
from mog import Position


@value
struct BaseModel(Model):
    var last_key: String
    var iterations: Int
    var index: Int

    fn __init__(out self):
        self.last_key = ""
        self.iterations = 0
        self.index = 0

    fn init(self) -> Cmd:
        return None

    fn update(mut self, msg: Msg) -> Cmd:
        if msg.isa[ExitMsg]():
            self.iterations += 1
            return
        elif msg.isa[KeyMsg]():
            self.last_key = String(msg[KeyMsg].key)

            if self.last_key == "q":
                return Cmd(exit_msg)
            elif self.last_key == "up":
                if self.index == 1:
                    self.index -= 1
            elif self.last_key == "down":
                if self.index == 0:
                    self.index += 1
            return
        else:
            self.iterations -= 1
            return

    fn view(self) -> String:
        alias left = mog.Style(mog.ASCII).border(mog.ROUNDED_BORDER).padding_left(1).padding_right(1).width(20).height(
            5
        )
        alias right = left.alignment(Position.CENTER, Position.CENTER)
        var cursor_a: String = "> " if self.index == 0 else "  "
        var cursor_b: String = "> " if self.index == 1 else "  "
        var lhs = left.render("Options:" + "\n" + cursor_a + "1. Option A\n" + cursor_b + "2. Option B\n")
        var rhs = right.render("Last Key: " + self.last_key)
        return mog.join_horizontal(Position.CENTER, lhs, rhs)


fn main() raises:
    var program = banjo.TUI(BaseModel())
    program.run()
