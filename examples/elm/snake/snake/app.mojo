from utils.variant import Variant
from sys import stdout
from mist.terminal.tty import TTY, Mode
from mist.event.read import EventReader
from mist.event.event import KeyEvent, Event, Char, Enter, Up, Down, Left, Right
import mog
from mog import Position, Profile, join_vertical, join_horizontal
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

    fn is_opposite(self, b: Direction) -> Bool:
        return (
            (self == Direction.UP and b == Direction.DOWN)
            or (self == Direction.DOWN and b == Direction.UP)
            or (self == Direction.LEFT and b == Direction.RIGHT)
            or (self == Direction.RIGHT and b == Direction.LEFT)
        )


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


@fieldwise_init
struct Snake(Movable):
    var points: List[Point]
    var direction: Direction
    var next_direction: Direction

    fn __init__(out self, cx: Int, cy: Int):
        self.points = [Point(cx - 2, cy), Point(cx - 1, cy), Point(cx, cy)]
        self.direction = Direction.RIGHT
        self.next_direction = Direction.RIGHT

    fn has(self, point: Point) -> Bool:
        for segment in self.points:
            if segment == point:
                return True
        return False


@fieldwise_init
struct GameState(Movable):
    var score: Int
    var turns: Int
    var seed: Int

    fn reset(mut self):
        self.score = 0
        self.turns = 0


@fieldwise_init
struct Model(Movable):
    var width: Int
    var height: Int
    var phase: Phase
    var snake: Snake
    var food: Point
    var game: GameState
    var done: Bool
    var renderer: Renderer
    var board_style: mog.Style

    fn __init__(out self):
        self.width = 22
        self.height = 14
        self.phase = Phase.START
        self.snake = Snake(self.width // 2, self.height // 2)
        self.food = Point(0, 0)
        self.game = GameState(score=0, turns=0, seed=7)
        self.done = False
        self.renderer = Renderer(stdout, 24)
        self.board_style = mog.Style(
            Profile.ANSI,
            foreground=mog.Color(7),
            border=mog.ROUNDED_BORDER,
        ).width(self.width * 2).height(self.height)

    fn reset_board(mut self):
        self.snake = Snake(self.width // 2, self.height // 2)
        self.game.reset()
        self.place_food()

    fn place_food(mut self):
        var open_cells = self.width * self.height - len(self.snake.points)
        if open_cells <= 0:
            self.phase = Phase.WON
            return

        self.game.seed = (self.game.seed * 1103515245 + 12345) % 2147483647
        var target = (self.game.seed + self.game.turns * 31 + self.game.score * 17) % open_cells

        var count = 0
        var y = 0
        while y < self.height:
            var x = 0
            while x < self.width:
                var cell = Point(x, y)
                if not self.snake.has(cell):
                    if count == target:
                        self.food = cell
                        return
                    count += 1
                x += 1
            y += 1

    fn advance_snake(mut self):
        if self.phase != Phase.RUNNING:
            return

        self.snake.direction = self.snake.next_direction
        var head = self.snake.points[len(self.snake.points) - 1]
        var next_head = head

        if self.snake.direction == Direction.UP:
            next_head.y -= 1
        elif self.snake.direction == Direction.DOWN:
            next_head.y += 1
        elif self.snake.direction == Direction.LEFT:
            next_head.x -= 1
        else:
            next_head.x += 1

        if next_head.x < 0 or next_head.x >= self.width or next_head.y < 0 or next_head.y >= self.height:
            self.phase = Phase.GAME_OVER
            return

        var i = 0
        while i < len(self.snake.points):
            if self.snake.points[i] == next_head:
                self.phase = Phase.GAME_OVER
                return
            i += 1

        var growing = next_head == self.food
        var new_snake = List[Point]()
        if growing:
            var j = 0
            while j < len(self.snake.points):
                new_snake.append(self.snake.points[j])
                j += 1
        else:
            var j = 1
            while j < len(self.snake.points):
                new_snake.append(self.snake.points[j])
                j += 1

        new_snake.append(next_head)
        self.snake = Snake(new_snake^, self.snake.direction, self.snake.next_direction)
        self.game.turns += 1

        if growing:
            self.game.score += 1
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
            ref wanted = msg[Direction]
            if self.phase == Phase.RUNNING and not self.snake.direction.is_opposite(wanted):
                self.snake.next_direction = wanted
            return Msg(Step())

        if msg.isa[Step]():
            self.advance_snake()
            return

        return

    fn board_cell(self, x: Int, y: Int) -> String:
        var p = Point(x, y)
        if p == self.food and self.phase == Phase.RUNNING:
            return "●"

        var last = len(self.snake.points) - 1
        if self.snake.points[last] == p:
            return "█"

        var i = 0
        while i < last:
            if self.snake.points[i] == p:
                return "▓"
            i += 1

        return "·"

    fn board_view(self) -> String:
        var out = String(capacity=self.width * self.height * 2)
        var y = 0
        while y < self.height:
            x = 0
            while x < self.width:
                out.write_string(self.board_cell(x, y))
                out.write_string(" ")
                x += 1
            y += 1

        return self.board_style.render(out)

    fn view(self) -> String:
        comptime HELP = "Controls: W/A/S/D or H/J/K/L (Up/Down arrows supported), Space/Enter to start, R restart, Q quit"
        if self.phase == Phase.START:
            return PANEL.render(
                join_vertical(
                    Position.LEFT,
                    TITLE.render("Snake (Elm-style update/view in Mojo)"),
                    "\n",
                    HELP,
                    "\nPress Enter or Space to begin.",
                )
            )

        var body = join_vertical(
            Position.LEFT,
            TITLE.render("Snake"),
            String("Score: ", self.game.score, "   Length: ", len(self.snake.points), "   Turns: ", self.game.turns),
            "\n",
            self.board_view(),
            "\n",
            HELP,
        )

        if self.phase == Phase.GAME_OVER:
            body.write_string("\n\n")
            body.write_string(ALERT.render("Game Over. Press R (or Enter) to play again."))
        elif self.phase == Phase.WON:
            body.write_string("\n\n")
            body.write_string(SUCCESS.render("You won. Press R (or Enter) to play again."))

        return PANEL.render(body)
