from std.testing import TestSuite, assert_equal, assert_true, assert_false

from termctl.event.event import Char, KeyCode, KeyEvent, KeyModifiers, Left, Right

from banjo.components.paginator import Layout, Paginator


def _key(code: KeyCode) -> KeyEvent:
    return KeyEvent(code, KeyModifiers.NONE)


def test_total_pages_from_items_rounds_up() raises:
    var p = Paginator(items=100, per_page=10)
    assert_equal(p.total_pages, 10)
    p = Paginator(items=101, per_page=10)
    assert_equal(p.total_pages, 11)
    p = Paginator(items=1, per_page=10)
    assert_equal(p.total_pages, 1)
    # No items still leaves one page to be on.
    p = Paginator(items=0, per_page=10)
    assert_equal(p.total_pages, 1)


def test_total_pages_given_directly_is_kept() raises:
    var p = Paginator(per_page=10, total_pages=3)
    assert_equal(p.total_pages, 3)
    p = Paginator(total_pages=0)
    assert_equal(p.total_pages, 1)


def test_slice_bounds_clamps_to_length() raises:
    var p = Paginator(items=25, per_page=10)

    var first = p.slice_bounds(25)
    assert_equal(first[0], 0)
    assert_equal(first[1], 10)

    p.page = 2
    var last = p.slice_bounds(25)
    assert_equal(last[0], 20)
    assert_equal(last[1], 25)


def test_items_on_page() raises:
    var p = Paginator(items=25, per_page=10)
    assert_equal(p.items_on_page(25), 10)
    p.page = 2
    assert_equal(p.items_on_page(25), 5)
    assert_equal(p.items_on_page(0), 0)


def test_navigation_clamps_at_both_ends() raises:
    var p = Paginator(items=25, per_page=10)

    assert_true(p.on_first_page())
    p.prev_page()
    assert_equal(p.page, 0)

    p.next_page()
    p.next_page()
    assert_true(p.on_last_page())
    p.next_page()
    assert_equal(p.page, 2)


def test_keys_move_pages() raises:
    var p = Paginator(items=25, per_page=10)

    p.update(_key(Right()))
    assert_equal(p.page, 1)
    p.update(_key(Char("l")))
    assert_equal(p.page, 2)
    p.update(_key(Char("l")))
    assert_equal(p.page, 2)

    p.update(_key(Left()))
    assert_equal(p.page, 1)
    p.update(_key(Char("h")))
    assert_equal(p.page, 0)

    # An unbound key changes nothing.
    p.update(_key(Char("z")))
    assert_equal(p.page, 0)


def test_arabic_view() raises:
    var p = Paginator(items=25, per_page=10)
    assert_equal(p.view(), "1/3")
    p.page = 2
    assert_equal(p.view(), "3/3")


def test_dots_view() raises:
    var p = Paginator(items=25, layout=Layout.DOTS, per_page=10)
    assert_equal(p.view(), "•○○")
    p.page = 1
    assert_equal(p.view(), "○•○")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
