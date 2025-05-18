from utils import Variant
from time import sleep
from collections import Dict
from sys import stderr, stdin
from runtime.asyncrt import TaskGroup
from banjo.termios import Termios, tcgetattr, tcsetattr, set_cbreak, WhenOption
from banjo.terminal.tty import TTY, Mode
from banjo.renderer import Renderer
from banjo.multiplex.select import EVENT_READ, stdin_select
from banjo.multiplex import SelectSelector
from banjo.key import Key, KeyType
from banjo.key_msg import read_events, KeyMsg
from banjo.msg import Msg, ExitMsg, NoMsg


alias CmdFn = fn () -> Msg
alias Cmd = Optional[CmdFn]


trait Model(Movable):
    # fn init(self) -> Cmd:
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


fn handle_msg(mut tui: TUI, msg: Msg) -> None:
    if cmd := tui.model.update(msg):
        handle_msg(tui, cmd.value()())
    return


async fn update(mut tui: TUI):
    var selector = SelectSelector()

    try:
        selector.register(stdin.value, EVENT_READ)
    except e:
        print("Error registering stdin.", e, file=stderr)
        tui.done = True
        return

    while not tui.done:
        try:
            var reader_status = selector.select()[0][1]
            if not reader_status & EVENT_READ:
                continue
        except e:
            print("Error selecting stdin.", e, file=stderr)

        if cmd := tui.model.update(read_events()):
            var msg = cmd.value()()
            if msg.isa[ExitMsg]():
                tui.done = True
                return

            if not msg.isa[NoMsg]():
                handle_msg(tui, msg)
            # if msg.isa[ExitMsg]():
            #     tui.done = True
            #     return

        # tui.msgs.append(read_events())
        # for msg in tui.msgs:
        #     cmd = tui.model.update(msg[])
        #     if cmd:
        #         var msg = cmd.value()()
        #         if msg.isa[ExitMsg]():
        #             tui.done = True
        #             return
        #         tui.msgs.append(msg)


struct TUI[T: Model]:
    var model: T
    var renderer: Renderer
    var running: Bool
    # var msgs: List[Msg]
    var done: Bool

    fn __init__(
        out self,
        owned model: T,
        renderer: Renderer = Renderer(60),
        running: Bool = True,
    ):
        self.model = model^
        self.renderer = renderer
        self.running = running
        # self.msgs = List[Msg]()
        self.done = False

    fn run(mut self) raises:
        with TTY[Mode.CBREAK]():
            var tg = TaskGroup()
            tg.create_task(view(self))
            tg.create_task(update(self))
            tg.wait()
