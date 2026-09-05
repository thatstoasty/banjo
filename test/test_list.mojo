from std.testing import TestSuite, assert_equal, assert_true, assert_false

from termctl.event.event import Char, KeyCode, KeyEvent, KeyModifiers, Down, End, Home, Up

from banjo.components.list import Direction, ListItem, ListState, ListView


def _key(code: KeyCode) -> KeyEvent:
    return KeyEvent(code, KeyModifiers.NONE)


def _items(count: Int) raises -> List[ListItem]:
    var items = List[ListItem]()
    for i in range(count):
        items.append(ListItem(String("item ", i)))
    return items^


def _view(count: Int) raises -> ListView:
    return ListView(_items(count))


# ---- ListItem ----


def test_item_height_counts_lines() raises:
    assert_equal(ListItem(String("one")).height(), 1)
    assert_equal(ListItem(String("one\ntwo")).height(), 2)
    assert_equal(ListItem(String("one\ntwo\nthree")).height(), 3)


# ---- ListState selection ----


def test_select_next_starts_at_first() raises:
    var s = ListState()
    s.select_next(5)
    assert_equal(s.selected.value(), 0)


def test_select_previous_starts_at_last() raises:
    var s = ListState()
    s.select_previous(5)
    assert_equal(s.selected.value(), 4)


def test_selection_clamps_at_both_ends() raises:
    var s = ListState()
    s.select_last(5)
    assert_equal(s.selected.value(), 4)
    s.select_next(5)
    assert_equal(s.selected.value(), 4)

    s.select_first(5)
    assert_equal(s.selected.value(), 0)
    s.select_previous(5)
    assert_equal(s.selected.value(), 0)


def test_clearing_selection_rewinds_offset() raises:
    var s = ListState()
    s.offset = 3
    s.select(None)
    assert_false(s.selected.__bool__())
    assert_equal(s.offset, 0)


def test_scroll_by_amount_clamps() raises:
    var s = ListState()
    s.select(0)
    s.scroll_down_by(3, 5)
    assert_equal(s.selected.value(), 3)
    s.scroll_down_by(99, 5)
    assert_equal(s.selected.value(), 4)
    s.scroll_up_by(2, 5)
    assert_equal(s.selected.value(), 2)
    s.scroll_up_by(99, 5)
    assert_equal(s.selected.value(), 0)


def test_empty_list_selection_is_a_no_op() raises:
    var s = ListState()
    s.select_next(0)
    assert_false(s.selected.__bool__())
    s.select_last(0)
    assert_false(s.selected.__bool__())


# ---- scrolling ----


def test_offset_follows_selection_downward() raises:
    var v = _view(10)
    var s = ListState()
    s.select(0)

    # Four visible rows; selecting item 5 must scroll it into view.
    v.scroll_into_view(4, s)
    assert_equal(s.offset, 0)

    s.select(5)
    v.scroll_into_view(4, s)
    var out = v.render(4, s)
    assert_true("item 5" in out)
    assert_false("item 0" in out)
    assert_equal(s.offset, 2)


def test_offset_follows_selection_upward() raises:
    var v = _view(10)
    var s = ListState()
    s.select(9)
    v.scroll_into_view(4, s)
    assert_equal(s.offset, 6)

    s.select(1)
    v.scroll_into_view(4, s)
    var out = v.render(4, s)
    assert_true("item 1" in out)
    assert_false("item 9" in out)


def test_scroll_padding_keeps_context_visible() raises:
    var v = _view(10)
    v.scroll_padding = 1
    var s = ListState()
    s.select(0)
    v.scroll_into_view(4, s)

    # With one row of padding, selecting 3 must also show 4.
    s.select(3)
    v.scroll_into_view(4, s)
    var out = v.render(4, s)
    assert_true("item 3" in out)
    assert_true("item 4" in out)


def test_render_clamps_out_of_range_selection() raises:
    var v = _view(3)
    var s = ListState()
    s.selected = 99
    # render is pure, so it must cope with an out-of-range selection without
    # fixing it; scroll_into_view is what actually clamps the state.
    var out = v.render(5, s)
    assert_true("item 2" in out)
    assert_equal(s.selected.value(), 99)

    v.scroll_into_view(5, s)
    assert_equal(s.selected.value(), 2)


def test_empty_list_renders_nothing() raises:
    var v = ListView(List[ListItem]())
    var s = ListState()
    assert_equal(v.render(5, s), "")


def test_zero_height_renders_nothing() raises:
    var v = _view(5)
    var s = ListState()
    assert_equal(v.render(0, s), "")


def test_render_does_not_mutate_state() raises:
    var v = _view(10)
    var s = ListState()
    s.select(9)
    _ = v.render(4, s)
    # Pure: the offset is unchanged until scroll_into_view is called.
    assert_equal(s.offset, 0)
    v.scroll_into_view(4, s)
    assert_equal(s.offset, 6)


# ---- rendering ----


def test_all_items_fit_when_height_allows() raises:
    var v = _view(3)
    var s = ListState()
    var out = v.render(10, s)
    assert_equal(len(out.splitlines()), 3)


def test_highlight_symbol_marks_only_the_selection() raises:
    var v = _view(3)
    v.highlight_symbol = String("> ")
    var s = ListState()
    s.select(1)

    var lines = v.render(10, s).splitlines()
    assert_equal(String(lines[0]), "  item 0")
    assert_equal(String(lines[1]), "> item 1")
    assert_equal(String(lines[2]), "  item 2")


def test_highlight_symbol_on_multiline_item() raises:
    var items = List[ListItem]()
    items.append(ListItem(String("a\nb")))
    items.append(ListItem(String("c")))
    var v = ListView(items^)
    v.highlight_symbol = String("> ")
    var s = ListState()
    s.select(0)

    # By default the symbol marks the first line only.
    var lines = v.render(10, s).splitlines()
    assert_equal(String(lines[0]), "> a")
    assert_equal(String(lines[1]), "  b")

    v.repeat_highlight_symbol = True
    var repeated = v.render(10, s).splitlines()
    assert_equal(String(repeated[0]), "> a")
    assert_equal(String(repeated[1]), "> b")


def test_multiline_items_consume_their_height() raises:
    var items = List[ListItem]()
    items.append(ListItem(String("a\na")))
    items.append(ListItem(String("b\nb")))
    items.append(ListItem(String("c\nc")))
    var v = ListView(items^)
    var s = ListState()

    # Height four fits exactly two two-line items.
    var out = v.render(4, s)
    assert_true("a" in out)
    assert_true("b" in out)
    assert_false("c" in out)


def test_bottom_to_top_reverses_rows() raises:
    var v = _view(3)
    v.direction = Direction.BOTTOM_TO_TOP
    var s = ListState()
    var lines = v.render(10, s).splitlines()
    assert_equal(String(lines[0]), "item 2")
    assert_equal(String(lines[2]), "item 0")


# ---- key handling ----


def test_update_moves_selection() raises:
    var v = _view(5)
    var s = ListState()

    assert_true(v.update(_key(Down()), s, 10))
    assert_equal(s.selected.value(), 0)
    assert_true(v.update(_key(Down()), s, 10))
    assert_equal(s.selected.value(), 1)
    assert_true(v.update(_key(Char("j")), s, 10))
    assert_equal(s.selected.value(), 2)

    assert_true(v.update(_key(Up()), s, 10))
    assert_equal(s.selected.value(), 1)
    assert_true(v.update(_key(End()), s, 10))
    assert_equal(s.selected.value(), 4)
    assert_true(v.update(_key(Home()), s, 10))
    assert_equal(s.selected.value(), 0)


def test_update_reports_no_change() raises:
    var v = _view(5)
    var s = ListState()
    s.select(0)

    # Already at the top; moving up changes nothing.
    assert_false(v.update(_key(Up()), s, 10))
    # An unbound key changes nothing.
    assert_false(v.update(_key(Char("z")), s, 10))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
