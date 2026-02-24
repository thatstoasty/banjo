from mist.terminal.tty import TTY, Mode
from mist.event.read import EventReader
from sample.app import Model, handle_event

fn main() raises:
    var tui = Model()
    var reader = EventReader()
    with TTY[Mode.RAW]():
        while not tui.done:
            tui.renderer.write(tui.view())
            var msg = handle_event(reader.read())
            if msg:
                while True:
                    msg = tui.update(msg.value())
                    if not msg:
                        break
