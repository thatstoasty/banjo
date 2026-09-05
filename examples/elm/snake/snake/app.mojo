from std.utils.variant import Variant
from termctl.terminal.tty import TTY, Mode
from termctl.event.read import EventReader
from termctl.event.event import KeyEvent, Event, Char, Enter, Up, Down, Left, Right
import mog
from mog import Position, Profile, join_vertical, join_horizontal
from banjo.app import Program


@fieldwise_init
struct Exit(TrivialRegisterPassable):
    pass


@fieldwise_init
struct Start(TrivialRegisterPassable, Writable):
    pass


@fieldwise_init
struct Restart(TrivialRegisterPassable, Writable):
    pass


@fieldwise_init
struct Step(TrivialRegisterPassable, Writable):
    pass


@fieldwise_init
struct Spin(TrivialRegisterPassable, Writable):
    """Advances the loading indicator one frame."""

    pass


@fieldwise_init
struct Loaded(TrivialRegisterPassable, Writable):
    """A background task's result, on its way into the model."""

    var best: Int


@fieldwise_init
struct Point(TrivialRegisterPassable, Equatable, Writable):
    var x: Int
    var y: Int


@fieldwise_init
struct Direction(TrivialRegisterPassable, Equatable, Writable):
    var value: UInt8
    comptime UP = Self(0)
    comptime DOWN = Self(1)
    comptime LEFT = Self(2)
    comptime RIGHT = Self(3)

    def is_opposite(self, b: Direction) -> Bool:
        return (
            (self == Direction.UP and b == Direction.DOWN)
            or (self == Direction.DOWN and b == Direction.UP)
            or (self == Direction.LEFT and b == Direction.RIGHT)
            or (self == Direction.RIGHT and b == Direction.LEFT)
        )


@fieldwise_init
struct Phase(TrivialRegisterPassable, Equatable, Writable):
    var value: UInt8
    comptime START = Self(0)
    comptime RUNNING = Self(1)
    comptime GAME_OVER = Self(2)
    comptime WON = Self(3)


@fieldwise_init
struct Msg(ImplicitlyCopyable):
    var value: Variant[KeyEvent, Exit, Start, Restart, Step, Spin, Loaded, Direction]

    def isa[T: Copyable](self) -> Bool:
        return self.value.isa[T]()

    def __getitem_param__[T: Copyable](ref self) -> ref[origin_of(self.value)._get_owned_interior["value"]] T:
        return self.value[T]


def handle_event(event: Event) raises -> Optional[Msg]:
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
comptime STEP_TIMER = 0
"""Tag for the timer that advances the snake."""
comptime SPIN_TIMER = 1
"""Tag for the timer that advances the loading indicator."""
comptime SPINNER = StaticString("|/-\\")
"""Frames of the loading indicator."""


@fieldwise_init
struct Snake(Movable, Writable):
    var points: List[Point]
    var direction: Direction
    var next_direction: Direction

    def __init__(out self, cx: Int, cy: Int):
        self.points = [Point(cx - 2, cy), Point(cx - 1, cy), Point(cx, cy)]
        self.direction = Direction.RIGHT
        self.next_direction = Direction.RIGHT

    def has(self, point: Point) -> Bool:
        for segment in self.points:
            if segment == point:
                return True
        return False


@fieldwise_init
struct GameState(Movable, Writable):
    var score: Int
    var turns: Int
    var seed: Int

    def reset(mut self):
        self.score = 0
        self.turns = 0


comptime SnakeMsg = Msg
"""Module-level alias, so `Model.Msg` below does not resolve to itself."""


@fieldwise_init
struct Model(Program):
    comptime Msg = SnakeMsg

    var width: Int
    var height: Int
    var phase: Phase
    var snake: Snake
    var food: Point
    var game: GameState
    var done: Bool
    var best: Optional[Int]
    """Best score, once the background task reports it."""
    var spin: Int
    """Frame counter for the loading indicator."""
    var board_style: mog.Style

    def __init__(out self):
        self.width = 22
        self.height = 14
        self.phase = Phase.START
        self.snake = Snake(self.width // 2, self.height // 2)
        self.food = Point(0, 0)
        self.game = GameState(score=0, turns=0, seed=7)
        self.done = False
        self.best = None
        self.spin = 0
        self.board_style = mog.Style(
            Profile.ANSI,
            foreground=mog.Color(7),
            border=mog.ROUNDED_BORDER,
        ).width(UInt16(self.width * 2)).height(UInt16(self.height))

    @staticmethod
    def on_event(event: Event) raises -> Optional[Msg]:
        """Translates a terminal event into a message.

        Args:
            event: The event read from the terminal.

        Returns:
            The message to apply, or None to ignore the event.

        Raises:
            Error: If the event cannot be interpreted.
        """
        return handle_event(event)

    def on_tick(mut self, tag: Int) raises -> Optional[Msg]:
        """Decides what each registered timer means right now.

        A paused or finished game emits no Step, so the runtime is not told the
        view is dirty and does not rebuild a frame that would be identical.

        Args:
            tag: The tag the timer was registered with.

        Returns:
            The message to apply, or None to let this tick pass.
        """
        if tag == STEP_TIMER:
            if self.phase == Phase.RUNNING:
                return Msg(Step())
            return None

        if tag == SPIN_TIMER:
            if self.best:
                return None
            return Msg(Spin())

        return None

    def on_result(mut self, value: Int) raises -> Optional[Msg]:
        """Turns the background task's result into a message.

        Args:
            value: The best score the task reported.

        Returns:
            The message carrying it into the model.
        """
        return Msg(Loaded(value))

    def is_done(self) -> Bool:
        """Reports whether the game has been quit.

        Returns:
            True once the player has pressed q.
        """
        return self.done

    def reset_board(mut self):
        self.snake = Snake(self.width // 2, self.height // 2)
        self.game.reset()
        self.place_food()

    def place_food(mut self):
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

    def advance_snake(mut self):
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

    def update(mut self, msg: Msg) raises -> Optional[Msg]:
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
            # The turn lands on the next tick. Stepping here instead would tie
            # the snake's speed to how fast the player presses keys.
            return

        if msg.isa[Step]():
            self.advance_snake()
            return

        if msg.isa[Spin]():
            self.spin += 1
            return

        if msg.isa[Loaded]():
            self.best = msg[Loaded].best
            return

        return

    def board_cell(self, x: Int, y: Int) -> String:
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

    def board_view(self) -> String:
        var out = String(capacity=self.width * self.height * 2)
        var y = 0
        while y < self.height:
            var x = 0
            while x < self.width:
                out.write_string(self.board_cell(x, y))
                out.write_string(" ")
                x += 1
            y += 1

        return self.board_style.render(out)

    def best_view(self) -> String:
        """Renders the best score, or the indicator while it is still loading.

        Returns:
            A one-line status string.
        """
        if self.best:
            return String("Best: ", self.best.value())
        if self.spin == 0:
            # No spin timer has ticked, so nothing is loading -- this app was
            # started without a background task. Say nothing rather than
            # showing an indicator that will never resolve.
            return String()
        return String(SPINNER[byte = self.spin % 4], " loading best score...")

    def view(self) raises -> String:
        comptime HELP = "Controls: W/A/S/D or H/J/K/L (Up/Down arrows supported), Space/Enter to start, R restart, Q quit"
        if self.phase == Phase.START:
            return PANEL.render(
                join_vertical(
                    Position.LEFT,
                    TITLE.render("Snake (Elm-style update/view in Mojo)"),
                    "\n",
                    HELP,
                    "\nPress Enter or Space to begin.",
                    self.best_view(),
                )
            )

        var body = join_vertical(
            Position.LEFT,
            TITLE.render("Snake"),
            String(
                "Score: ",
                self.game.score,
                "   Length: ",
                len(self.snake.points),
                "   Turns: ",
                self.game.turns,
                "   ",
                self.best_view(),
            ),
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
