from std.testing import TestSuite, assert_equal, assert_true
from std.utils.variant import Variant

from termctl.event.event import Event, KeyCode, KeyEvent, KeyModifiers

from banjo.app import Program, dispatch


@fieldwise_init
struct Quit(TrivialRegisterPassable):
    pass


@fieldwise_init
struct Step(TrivialRegisterPassable):
    pass


@fieldwise_init
struct Up(TrivialRegisterPassable):
    pass


@fieldwise_init
struct Spin(TrivialRegisterPassable):
    pass


@fieldwise_init
struct Loaded(TrivialRegisterPassable):
    var session: Int


@fieldwise_init
struct Phase(TrivialRegisterPassable):
    var value: UInt8


@fieldwise_init
struct Msg(ImplicitlyCopyable):
    # Mirrors the elm sample's message and model on purpose. Mojo 1.1
    # miscopied a `P.Msg` when `dispatch` copied one in generic code, and
    # whether it did depended on the layout of both the message and the
    # model: smaller shapes -- `KeyEvent` with just two other cases, say --
    # came through intact. This shape crashed the old `dispatch` outright.
    var value: Variant[KeyEvent, Quit, Step, Up, Spin, Loaded, Phase]


struct Counter(Program):
    comptime Msg = Msg

    var last_key: String
    var index: Int
    var phase: Phase
    var done: Bool
    var session: Optional[Int]
    var steps: Int
    var updates: Int

    def __init__(out self):
        self.last_key = ""
        self.index = 0
        self.phase = Phase(0)
        self.done = False
        self.session = None
        self.steps = 0
        self.updates = 0

    @staticmethod
    def on_event(event: Event) raises -> Optional[Msg]:
        return None

    def on_tick(mut self, tag: Int) raises -> Optional[Msg]:
        return None

    def on_result(mut self, value: Int) raises -> Optional[Msg]:
        return None

    def update(mut self, msg: Msg) raises -> Optional[Msg]:
        self.updates += 1
        if msg.value.isa[Quit]():
            self.done = True
        elif msg.value.isa[Step]():
            self.steps += 1
            if self.steps < 3:
                return Msg(Step())
        elif msg.value.isa[KeyEvent]():
            return Msg(Quit())
        return None

    def view(self) raises -> String:
        return String()

    def is_done(self) -> Bool:
        return self.done


def test_dispatch_delivers_the_message() raises:
    var app = Counter()
    dispatch(app, Msg(Quit()))
    assert_true(app.done)
    assert_equal(app.updates, 1)


def test_dispatch_delivers_a_key_and_its_follow_up() raises:
    var app = Counter()
    dispatch(app, Msg(KeyEvent(KeyCode.from_string("q"), KeyModifiers.NONE)))
    assert_true(app.done)
    assert_equal(app.updates, 2)


def test_dispatch_runs_follow_ups_to_completion() raises:
    var app = Counter()
    dispatch(app, Msg(Step()))
    assert_equal(app.steps, 3)
    assert_equal(app.updates, 3)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
