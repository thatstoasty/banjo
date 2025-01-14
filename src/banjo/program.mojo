from utils import Variant
from time import sleep
from collections import Optional, Dict
from runtime.asyncrt import TaskGroup
from .termios import Termios, tcgetattr, tcsetattr, set_cbreak, TCSADRAIN, STDIN
import mog
from .renderer import Renderer
from .select import SelectSelector, EVENT_READ, stdin_select
from .key import Key, KeyType, read_events, KeyMsg


alias CmdFn = fn () -> Msg
alias Cmd = Optional[CmdFn]


trait Model(CollectionElement):
    fn init(self) -> Cmd:
        ...

    # # Temporary? update's function signature doesn't work unless I define __moveinit__ as part of the trait even though it implements Movable.
    # fn __moveinit__(out self, owned existing: Self):
    #     ...

    fn update(mut self, msg: Msg) -> Cmd:
        ...

    fn view(self) -> String:
        ...


trait IsMsg(CollectionElement):
    ...


# @value
# struct Msg():
#     var type: String
#     var value: String


@value
struct ExitMsg(IsMsg):
    pass


fn exit_msg() -> Msg:
    return ExitMsg()


alias Msg = Variant[ExitMsg, KeyMsg, NoneType]


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
            var k = str(msg[KeyMsg].key)
            self.last_key = k

            if k == "q":
                return Cmd(exit_msg)
            elif k == "up":
                if self.index == 1:
                    self.index -= 1
            elif k == "down":
                if self.index == 0:
                    self.index += 1

            return None
        else:
            self.iterations -= 1
            return None

    fn view(self) -> String:
        alias left = mog.Style(mog.ASCII).border(mog.ROUNDED_BORDER).padding_left(1).padding_right(1).width(20).height(
            5
        )
        alias right = mog.Style(mog.ASCII).border(mog.ROUNDED_BORDER).padding_left(1).padding_right(1).width(20).height(
            6
        ).alignment(mog.center, mog.center)
        var cursor_a: String = "> " if self.index == 0 else "  "
        var cursor_b: String = "> " if self.index == 1 else "  "
        var lhs = left.render("Options:" + "\n" + cursor_a + "1. Option A\n" + cursor_b + "2. Option B\n")
        var rhs = right.render("Last Key: " + self.last_key)
        return mog.join_horizontal(mog.center, lhs, rhs)


struct TUI:
    var model: BaseModel
    var renderer: Renderer
    var running: Bool
    var fps: Float64
    var msgs: List[Msg]
    var done: Bool

    fn __init__(
        mut self,
        model: BaseModel,
        fps: Float64 = 60,
        renderer: Renderer = Renderer(60),
        running: Bool = True,
    ):
        self.model = model
        self.fps = fps
        self.renderer = renderer
        self.running = running
        self.msgs = List[Msg]()
        self.done = False

    fn run(mut self) raises:
        var old_settings: Termios
        try:
            old_settings = tcgetattr(STDIN)
            _ = set_cbreak(STDIN)
        except e:
            return

        @parameter
        async fn view():
            while True:
                if self.done:
                    break
                self.renderer.write(self.model.view())
                sleep(self.renderer.framerate)

        @parameter
        async fn update():
            # var selector = SelectSelector()

            # try:
            #     selector.register(0, EVENT_READ)
            # except:
            #     print("register failed")
            #     return

            while True:
                var ready = stdin_select()
                # var ready = selector.select(EVENT_READ)

                # TODO: This feels janky. I want to continue the while loop if there are no events to read.
                var key_msg: Optional[KeyMsg] = None
                for pair in ready:
                    if pair[][1] & EVENT_READ:
                        key_msg = KeyMsg(read_events())

                if not key_msg:
                    continue

                self.msgs.append(key_msg.value())
                for msg in self.msgs:
                    cmd = self.model.update(msg[])
                    if cmd:
                        var msg = cmd.value()()
                        if msg.isa[ExitMsg]():
                            self.done = True
                            return
                        self.msgs.append(msg)

        var tg = TaskGroup()
        tg.create_task(view())
        tg.create_task(update())

        tg.wait()

        # restore terminal settings
        try:
            tcsetattr(STDIN, TCSADRAIN, old_settings)
        except:
            return

        print("done")
