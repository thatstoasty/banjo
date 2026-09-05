from std.testing import TestSuite, assert_equal, assert_true, assert_false

from termctl.event.event import Char, Down, End, Home, KeyCode, KeyEvent, KeyModifiers, PageDown, Up

from banjo.components.table import Column, Table, TableState


def _key(code: KeyCode) -> KeyEvent:
    return KeyEvent(code, KeyModifiers.NONE)


def _table(rows: Int) raises -> Table:
    var columns: List[Column] = [Column(String("Name"), 8), Column(String("Qty"), 4)]
    var body = List[List[String]]()
    for i in range(rows):
        var cells: List[String] = [String("row", i), String(i * 10)]
        body.append(cells^)
    return Table(columns^, body^)


def test_header_is_padded_to_column_widths() raises:
    var t = _table(3)
    assert_equal(t.header_view(), "Name    Qty ")


def test_cells_are_padded_to_column_widths() raises:
    var t = _table(1)
    var state = TableState()
    var lines = t.render(5, state).splitlines()
    assert_equal(String(lines[0]), "Name    Qty ")
    assert_equal(String(lines[1]), "row0    0   ")


def test_long_cells_are_truncated() raises:
    var columns: List[Column] = [Column(String("Name"), 6)]
    var body = List[List[String]]()
    var cells: List[String] = [String("a-very-long-value")]
    body.append(cells^)
    var t = Table(columns^, body^)

    var state = TableState()
    var lines = t.render(5, state).splitlines()
    assert_equal(String(lines[1]).count_codepoints(), 6)
    assert_true("…" in String(lines[1]))


def test_missing_cells_render_blank() raises:
    var columns: List[Column] = [Column(String("A"), 3), Column(String("B"), 3)]
    var body = List[List[String]]()
    var cells: List[String] = [String("x")]
    body.append(cells^)
    var t = Table(columns^, body^)

    var state = TableState()
    var lines = t.render(5, state).splitlines()
    assert_equal(String(lines[1]), "x     ")


def test_zero_width_columns_are_skipped() raises:
    var columns: List[Column] = [Column(String("A"), 3), Column(String("hidden"), 0)]
    var body = List[List[String]]()
    var cells: List[String] = [String("x"), String("y")]
    body.append(cells^)
    var t = Table(columns^, body^)

    var state = TableState()
    var lines = t.render(5, state).splitlines()
    assert_equal(String(lines[1]), "x  ")


def test_header_can_be_hidden() raises:
    var t = _table(2)
    t.show_header = False
    var lines = t.render(5, TableState()).splitlines()
    assert_equal(len(lines), 2)
    assert_true("row0" in String(lines[0]))


def test_body_is_limited_to_height() raises:
    var t = _table(10)
    # Height counts body rows; the header sits above them.
    assert_equal(len(t.render(3, TableState()).splitlines()), 4)


def test_selection_scrolls_the_body() raises:
    var t = _table(10)
    var state = TableState()
    state.select(0)

    t.scroll_into_view(3, state)
    assert_equal(state.offset, 0)

    state.select(7)
    t.scroll_into_view(3, state)
    assert_equal(state.offset, 5)

    var out = t.render(3, state)
    assert_true("row7" in out)
    assert_false("row0" in out)


def test_render_does_not_mutate_state() raises:
    var t = _table(10)
    var state = TableState()
    state.select(9)
    var out = t.render(3, state)
    assert_true("row9" in out)
    assert_equal(state.offset, 0)


def test_keys_move_the_selection() raises:
    var t = _table(10)
    var state = TableState()

    assert_true(t.update(_key(Down()), state, 3))
    assert_equal(state.selected.value(), 0)
    assert_true(t.update(_key(Char("j")), state, 3))
    assert_equal(state.selected.value(), 1)
    assert_true(t.update(_key(Up()), state, 3))
    assert_equal(state.selected.value(), 0)

    assert_true(t.update(_key(End()), state, 3))
    assert_equal(state.selected.value(), 9)
    assert_true(t.update(_key(Home()), state, 3))
    assert_equal(state.selected.value(), 0)


def test_page_down_moves_by_a_screenful() raises:
    var t = _table(10)
    var state = TableState()
    state.select(0)
    assert_true(t.update(_key(PageDown()), state, 3))
    assert_equal(state.selected.value(), 3)


def test_unbound_key_changes_nothing() raises:
    var t = _table(5)
    var state = TableState()
    state.select(0)
    assert_false(t.update(_key(Char("z")), state, 3))


def test_selected_row_is_reported() raises:
    var t = _table(5)
    var state = TableState()
    assert_false(t.selected_row(state).__bool__())

    state.select(2)
    var row = t.selected_row(state)
    assert_true(row.__bool__())
    assert_equal(row.value()[0], "row2")


def test_empty_table_renders_just_the_header() raises:
    var t = _table(0)
    assert_equal(t.render(5, TableState()), "Name    Qty ")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
