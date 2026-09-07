from std.runtime.asyncrt import TaskGroup
from std.testing import TestSuite, assert_equal, assert_false, assert_true

from banjo.task import Mailbox


async def _send_int[o: MutOrigin](box: Pointer[Mailbox[Int], o], value: Int) -> None:
    box[].post(value)


async def _send_string[o: MutOrigin](box: Pointer[Mailbox[String], o], text: String) -> None:
    # Built on the worker's thread and owned by the reader's, which is the
    # whole point: the payload is not a word, it has heap storage.
    var built = String("[", text, "] from a worker")
    box[].post(built^)


async def _send_rows[o: MutOrigin](box: Pointer[Mailbox[List[String]], o]) -> None:
    var rows = List[String]()
    for i in range(5):
        rows.append(String("row ", i))
    box[].post(rows^)


def test_nothing_pending_before_a_post() raises:
    var box = Mailbox[Int]()
    assert_false(box.take().__bool__())


def test_an_int_crosses_the_thread_boundary() raises:
    var box = Mailbox[Int]()
    var group = TaskGroup()
    group.create_task(_send_int(Pointer(to=box), 1274))

    var got = Optional[Int](None)
    while not got:
        got = box.take()
    group.wait()

    assert_equal(got.value(), 1274)
    _ = box^


def test_a_string_crosses_the_thread_boundary() raises:
    var box = Mailbox[String]()
    var group = TaskGroup()
    group.create_task(_send_string(Pointer(to=box), String("hello")))

    var got = Optional[String](None)
    while not got:
        got = box.take()
    group.wait()

    assert_equal(got.value(), "[hello] from a worker")
    _ = box^


def test_a_collection_crosses_the_thread_boundary() raises:
    var box = Mailbox[List[String]]()
    var group = TaskGroup()
    group.create_task(_send_rows(Pointer(to=box)))

    var got = Optional[List[String]](None)
    while not got:
        got = box.take()
    group.wait()

    assert_equal(len(got.value()), 5)
    assert_equal(got.value()[4], "row 4")
    _ = box^


def test_a_value_is_delivered_exactly_once() raises:
    var box = Mailbox[Int]()
    var group = TaskGroup()
    group.create_task(_send_int(Pointer(to=box), 7))

    var got = Optional[Int](None)
    while not got:
        got = box.take()
    group.wait()

    assert_false(box.take().__bool__())
    _ = box^


def test_cancelling_is_visible_to_the_task() raises:
    var box = Mailbox[Int]()
    assert_false(box.is_cancelled())
    box.cancel()
    assert_true(box.is_cancelled())
    _ = box^


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
