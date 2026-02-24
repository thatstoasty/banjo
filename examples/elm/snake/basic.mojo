from mist.terminal.tty import TTY, Mode
from mist.event.read import EventReader
from snake.app import Model, handle_event


fn main() raises:
    var snake = Model()
    var reader = EventReader()
    with TTY[Mode.RAW]():
        while not snake.done:
            snake.renderer.write(snake.view())
            var msg = handle_event(reader.read())
            if msg:
                while True:
                    msg = snake.update(msg.value())
                    if not msg:
                        break
