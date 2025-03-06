from utils import Variant
from time import sleep
from collections import Optional, Dict
from runtime.asyncrt import TaskGroup
from banjo.termios import Termios, tcgetattr, tcsetattr, set_cbreak, WhenOption, STDIN
from banjo.tty import TTY, Mode
from banjo.renderer import Renderer
from banjo.select import SelectSelector, EVENT_READ, stdin_select
from banjo.key import Key, KeyType, read_events, KeyMsg
from banjo.msg import Msg, ExitMsg


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


async fn view(tui: TUI):
    while True:
        if tui.done:
            break
        tui.renderer.write(tui.model.view())
        sleep(tui.renderer.framerate)


async fn update(mut tui: TUI):
    while True:
        if not stdin_select() & EVENT_READ:
            continue

        # TODO: This feels janky. I want to continue the while loop if there are no events to read.
        tui.msgs.append(read_events())
        for msg in tui.msgs:
            cmd = tui.model.update(msg[])
            if cmd:
                var msg = cmd.value()()
                if msg.isa[ExitMsg]():
                    tui.done = True
                    return
                tui.msgs.append(msg)


struct TUI[T: Model]:
    var model: T
    var renderer: Renderer
    var running: Bool
    var fps: Float64
    var msgs: List[Msg]
    var done: Bool

    fn __init__(
        mut self,
        model: T,
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
        with TTY[Mode.CBREAK]():
            var tg = TaskGroup()
            tg.create_task(view(self))
            tg.create_task(update(self))
            tg.wait()
