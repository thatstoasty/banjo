from time import sleep
from utils.variant import Variant
from sys import stdout
from runtime.asyncrt import TaskGroup
from mist.terminal.tty import TTY, Mode
from mist.event.read import EventReader
from mist.event.event import KeyEvent, Event, Char, Enter, Up, Down, Left, Right
import mog
from mog import Position, Profile
from banjo.renderer import Renderer


@fieldwise_init
@register_passable("trivial")
struct Exit(ImplicitlyCopyable):
    var dummy: Bool

    fn __init__(out self):
        self.dummy = True


@fieldwise_init
@register_passable("trivial")
struct Start(ImplicitlyCopyable):
    var dummy: Bool

    fn __init__(out self):
        self.dummy = True


@fieldwise_init
@register_passable("trivial")
struct Restart(ImplicitlyCopyable):
    var dummy: Bool

    fn __init__(out self):
        self.dummy = True


@fieldwise_init
@register_passable("trivial")
struct Step(ImplicitlyCopyable):
    var dummy: Bool

    fn __init__(out self):
        self.dummy = True


@fieldwise_init
@register_passable("trivial")
struct Point(ImplicitlyCopyable, Equatable):
    var x: Int
    var y: Int

    fn __eq__(self, other: Self) -> Bool:
        return self.x == other.x and self.y == other.y


@fieldwise_init
@register_passable("trivial")
struct Direction(ImplicitlyCopyable, Equatable):
    var value: UInt8
    comptime UP = Self(0)
    comptime DOWN = Self(1)
    comptime LEFT = Self(2)
    comptime RIGHT = Self(3)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value


@fieldwise_init
@register_passable("trivial")
struct Phase(ImplicitlyCopyable, Equatable):
    var value: UInt8
    comptime START = Self(0)
    comptime RUNNING = Self(1)
    comptime GAME_OVER = Self(2)
    comptime WON = Self(3)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value


@fieldwise_init
struct Msg(ImplicitlyCopyable):
    var value: Variant[KeyEvent, Exit, Start, Restart, Step, Direction]

    fn isa[T: Copyable](self) -> Bool:
        return self.value.isa[T]()

    fn __getitem__[T: Copyable](ref self) -> ref [origin_of(self.value)] T:
        return self.value[T]


fn handle_event(event: Event) raises -> Optional[Msg]:
    if not event.isa[KeyEvent]():
        return

    var key = event[KeyEvent]
    if key.code.isa[Char]():
        ref ch = key.code[Char]
        if ch == "q" or ch == "Q":
            return Msg(Exit())
        elif ch == "r" or ch == "R":
            return Msg(Restart())
        elif ch == " " or ch == "\r":
            return Msg(Start())
        elif ch == "w" or ch == "W" or ch == "k" or ch == "K":
            return Msg(Direction.UP)
        elif ch == "s" or ch == "S" or ch == "j" or ch == "J":
            return Msg(Direction.DOWN)
        elif ch == "a" or ch == "A" or ch == "h" or ch == "H":
            return Msg(Direction.LEFT)
        elif ch == "d" or ch == "D" or ch == "l" or ch == "L":
            return Msg(Direction.RIGHT)
        return

    if key.code.isa[Up]():
        return Msg(Direction.UP)
    elif key.code.isa[Down]():
        return Msg(Direction.DOWN)
    elif key.code.isa[Left]():
        return Msg(Direction.LEFT)
    elif key.code.isa[Right]():
        return Msg(Direction.RIGHT)
    elif key.code.isa[Enter]():
        return Msg(Start())

    return


comptime PANEL = mog.Style(
    Profile.ANSI,
    width=66,
    padding=mog.Padding(1, 0),
    alignment=mog.Alignment(Position.LEFT),
    border=mog.ROUNDED_BORDER,
).border_foreground(mog.Color(6))

comptime TITLE = mog.Style(Profile.ANSI, foreground=mog.Color(2))
comptime ALERT = mog.Style(Profile.ANSI, foreground=mog.Color(1))
comptime SUCCESS = mog.Style(Profile.ANSI, foreground=mog.Color(10))


async fn view(model: Model) -> None:
    """View loop for the TUI. This is responsible for rendering the view to the terminal.

    Args:
        model: The TUI instance.
    """
    var renderer = model.renderer.copy()
    while not model.done:
        renderer.write(model.view())


async fn update(mut model: Model) -> None:
    """Update loop for the TUI. This is responsible for handling input and updating the model.

    Args:
        model: The TUI instance.
    """
    try:
        var reader = EventReader()
        while not model.done:
            var msg = handle_event(reader.read())
            if msg:
                while True:
                    msg = model.update(msg.value())
                    if not msg:
                        break
    except e:
        print(e)
        return


async fn tick(mut model: Model) -> None:
    while not model.done:
        sleep(1.0)
        if model.phase != Phase.RUNNING:
            continue

        var msg = Optional[Msg](Msg(Step()))
        while True:
            msg = model.update(msg.value())
            if not msg:
                break


@fieldwise_init
struct Model(Movable):
    var width: Int
    var height: Int
    var phase: Phase
    var snake: List[Point]
    var direction: Direction
    var next_direction: Direction
    var food: Point
    var score: Int
    var turns: Int
    var seed: Int
    var done: Bool
    var renderer: Renderer

    fn __init__(out self):
        self.width = 22
        self.height = 14
        self.phase = Phase.START
        self.snake = List[Point]()
        self.direction = Direction.RIGHT
        self.next_direction = Direction.RIGHT
        self.food = Point(0, 0)
        self.score = 0
        self.turns = 0
        self.seed = 7
        self.done = False
        self.renderer = Renderer(stdout, 24)
        self.reset_board()

    fn reset_board(mut self):
        var cx = self.width // 2
        var cy = self.height // 2
        self.snake = List[Point]()
        self.snake.append(Point(cx - 2, cy))
        self.snake.append(Point(cx - 1, cy))
        self.snake.append(Point(cx, cy))
        self.direction = Direction.RIGHT
        self.next_direction = Direction.RIGHT
        self.score = 0
        self.turns = 0
        self.place_food()

    fn is_opposite(self, a: Direction, b: Direction) -> Bool:
        return (
            (a == Direction.UP and b == Direction.DOWN)
            or (a == Direction.DOWN and b == Direction.UP)
            or (a == Direction.LEFT and b == Direction.RIGHT)
            or (a == Direction.RIGHT and b == Direction.LEFT)
        )

    fn snake_has(self, point: Point) -> Bool:
        for segment in self.snake:
            if segment == point:
                return True
        return False

    fn place_food(mut self):
        var open_cells = self.width * self.height - len(self.snake)
        if open_cells <= 0:
            self.phase = Phase.WON
            return

        self.seed = (self.seed * 1103515245 + 12345) % 2147483647
        var target = (self.seed + self.turns * 31 + self.score * 17) % open_cells

        var count = 0
        var y = 0
        while y < self.height:
            var x = 0
            while x < self.width:
                var cell = Point(x, y)
                if not self.snake_has(cell):
                    if count == target:
                        self.food = cell
                        return
                    count += 1
                x += 1
            y += 1

    fn advance_snake(mut self):
        if self.phase != Phase.RUNNING:
            return

        self.direction = self.next_direction
        var head = self.snake[len(self.snake) - 1]
        var next_head = head

        if self.direction == Direction.UP:
            next_head.y -= 1
        elif self.direction == Direction.DOWN:
            next_head.y += 1
        elif self.direction == Direction.LEFT:
            next_head.x -= 1
        else:
            next_head.x += 1

        if next_head.x < 0 or next_head.x >= self.width or next_head.y < 0 or next_head.y >= self.height:
            self.phase = Phase.GAME_OVER
            return

        var i = 0
        while i < len(self.snake):
            if self.snake[i] == next_head:
                self.phase = Phase.GAME_OVER
                return
            i += 1

        var growing = next_head == self.food
        var new_snake = List[Point]()
        if growing:
            var j = 0
            while j < len(self.snake):
                new_snake.append(self.snake[j])
                j += 1
        else:
            var j = 1
            while j < len(self.snake):
                new_snake.append(self.snake[j])
                j += 1

        new_snake.append(next_head)
        self.snake = new_snake^
        self.turns += 1

        if growing:
            self.score += 1
            self.place_food()

    fn update(mut self, msg: Msg) -> Optional[Msg]:
        if msg.isa[Exit]():
            self.done = True
            return

        if msg.isa[Restart]():
            self.reset_board()
            self.phase = Phase.RUNNING
            return

        if msg.isa[Start]():
            if self.phase == Phase.START or self.phase == Phase.GAME_OVER or self.phase == Phase.WON:
                self.reset_board()
                self.phase = Phase.RUNNING
            return

        if msg.isa[Direction]():
            var wanted = msg[Direction]
            if self.phase == Phase.RUNNING and not self.is_opposite(self.direction, wanted):
                self.next_direction = wanted
            return

        if msg.isa[Step]():
            self.advance_snake()
            return

        return

    fn board_cell(self, x: Int, y: Int) -> String:
        var p = Point(x, y)
        if p == self.food and self.phase == Phase.RUNNING:
            return "●"

        var last = len(self.snake) - 1
        if self.snake[last] == p:
            return "█"

        var i = 0
        while i < last:
            if self.snake[i] == p:
                return "▓"
            i += 1

        return "·"

    fn board_view(self) -> String:
        var out = String()
        out.write_string("┌")
        var x = 0
        while x < self.width:
            out.write_string("──")
            x += 1
        out.write_string("┐\n")

        var y = 0
        while y < self.height:
            out.write_string("│")
            x = 0
            while x < self.width:
                out.write_string(self.board_cell(x, y))
                out.write_string(" ")
                x += 1
            out.write_string("│\n")
            y += 1

        out.write_string("└")
        x = 0
        while x < self.width:
            out.write_string("──")
            x += 1
        out.write_string("┘")
        return out

    fn status_line(self) -> String:
        return "Score: " + String(self.score) + "   Length: " + String(len(self.snake)) + "   Turns: " + String(self.turns)

    fn help_line(self) -> String:
        return "Controls: W/A/S/D or H/J/K/L (Up/Down arrows supported), Space/Enter to start, R restart, Q quit"

    fn view(self) -> String:
        if self.phase == Phase.START:
            return PANEL.render(
                TITLE.render("Snake (Elm-style update/view in Mojo)"),
                "\n\n",
                self.help_line(),
                "\n\nPress Enter or Space to begin.",
            )

        var body = String()
        body.write_string(TITLE.render("Snake"))
        body.write_string("\n")
        body.write_string(self.status_line())
        body.write_string("\n\n")
        body.write_string(self.board_view())
        body.write_string("\n\n")
        body.write_string(self.help_line())

        if self.phase == Phase.GAME_OVER:
            body.write_string("\n\n")
            body.write_string(ALERT.render("Game Over. Press R (or Enter) to play again."))
        elif self.phase == Phase.WON:
            body.write_string("\n\n")
            body.write_string(SUCCESS.render("You won. Press R (or Enter) to play again."))

        return PANEL.render(body)


fn main() raises:
    var tui = Model()
    # var reader = EventReader()

    var tg = TaskGroup()
    with TTY[Mode.RAW]():
        tg.create_task(view(tui))
        tg.create_task(update(tui))
        tg.create_task(tick(tui))
        tg.wait()


        # while not snake.done:
        #     snake.renderer.write(snake.view())

        #     var msg = handle_event(reader.read())
        #     if msg:
        #         while True:
        #             msg = snake.update(msg.value())
        #             if not msg:
        #                 break
