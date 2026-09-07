from std.testing import TestSuite, assert_equal, assert_true, assert_false

from termctl.event.event import Backspace, Char, Delete, End, Home, KeyCode, KeyEvent, KeyModifiers, Left, Right

from banjo.components.text_input import TextInput


def _key(code: KeyCode, modifiers: KeyModifiers = KeyModifiers.NONE) -> KeyEvent:
    return KeyEvent(code, modifiers)


def _typed(text: String) raises -> TextInput:
    var input = TextInput()
    for codepoint in text.codepoint_slices():
        _ = input.update(_key(Char(codepoint)))
    return input^


def test_typing_appends() raises:
    var input = _typed(String("abc"))
    assert_equal(input.value, "abc")
    assert_equal(input.cursor, 3)


def test_backspace_deletes_before_cursor() raises:
    var input = _typed(String("abc"))
    assert_true(input.update(_key(Backspace())))
    assert_equal(input.value, "ab")
    assert_equal(input.cursor, 2)


def test_backspace_at_start_is_a_no_op() raises:
    var input = TextInput()
    assert_false(input.update(_key(Backspace())))
    assert_equal(input.value, "")


def test_cursor_movement_and_insertion_in_middle() raises:
    var input = _typed(String("ac"))
    assert_true(input.update(_key(Left())))
    assert_equal(input.cursor, 1)
    _ = input.update(_key(Char("b")))
    assert_equal(input.value, "abc")
    assert_equal(input.cursor, 2)


def test_delete_removes_under_cursor() raises:
    var input = _typed(String("abc"))
    _ = input.update(_key(Home()))
    assert_true(input.update(_key(Delete())))
    assert_equal(input.value, "bc")
    assert_equal(input.cursor, 0)


def test_delete_at_end_is_a_no_op() raises:
    var input = _typed(String("ab"))
    assert_false(input.update(_key(Delete())))
    assert_equal(input.value, "ab")


def test_home_and_end() raises:
    var input = _typed(String("hello"))
    assert_true(input.update(_key(Home())))
    assert_equal(input.cursor, 0)
    assert_false(input.update(_key(Home())))
    assert_true(input.update(_key(End())))
    assert_equal(input.cursor, 5)


def test_cursor_clamps_at_both_ends() raises:
    var input = _typed(String("ab"))
    assert_false(input.update(_key(Right())))
    _ = input.update(_key(Home()))
    assert_false(input.update(_key(Left())))


def test_ctrl_u_clears() raises:
    var input = _typed(String("hello"))
    assert_true(input.update(_key(Char("u"), KeyModifiers.CONTROL)))
    assert_equal(input.value, "")
    assert_equal(input.cursor, 0)


def test_control_chords_are_not_typed() raises:
    var input = TextInput()
    # Left for the application to interpret, not inserted as text.
    assert_false(input.update(_key(Char("a"), KeyModifiers.CONTROL)))
    assert_equal(input.value, "")


def test_multibyte_cursor_steps_once_per_character() raises:
    var input = _typed(String("héllo"))
    assert_equal(input.length(), 5)
    assert_equal(input.cursor, 5)
    _ = input.update(_key(Left()))
    _ = input.update(_key(Left()))
    _ = input.update(_key(Left()))
    assert_equal(input.cursor, 2)
    _ = input.update(_key(Backspace()))
    assert_equal(input.value, "hllo")


def test_cursor_steps_over_a_grapheme_cluster_once() raises:
    # "e" plus a combining acute is two codepoints but one character on
    # screen, so the cursor must treat it as one position.
    var input = TextInput()
    input.set_value(String("e\u0301x"))
    assert_equal(input.length(), 2)
    assert_equal(input.cursor, 2)
    _ = input.update(_key(Left()))
    assert_equal(input.cursor, 1)


def test_backspace_deletes_a_whole_cluster() raises:
    var input = TextInput()
    input.set_value(String("a👩‍👩‍👧‍👦"))
    assert_equal(input.length(), 2)
    assert_true(input.update(_key(Backspace())))
    assert_equal(input.value, "a")
    assert_equal(input.cursor, 1)


def test_typing_a_combining_mark_joins_the_character_before_it() raises:
    # Each codepoint arrives as its own key event, but the accent merges into
    # the "e", so the cursor must not advance past one character.
    var input = _typed(String("e\u0301"))
    assert_equal(input.value, "e\u0301")
    assert_equal(input.length(), 1)
    assert_equal(input.cursor, 1)


def test_delete_removes_a_whole_cluster_under_the_cursor() raises:
    var input = TextInput()
    input.set_value(String("🇬🇧z"))
    _ = input.update(_key(Home()))
    assert_true(input.update(_key(Delete())))
    assert_equal(input.value, "z")


def test_view_shows_prompt_and_cursor() raises:
    var input = _typed(String("ab"))
    assert_equal(input.view(), "> ab▏")
    _ = input.update(_key(Home()))
    assert_equal(input.view(), "> ▏ab")


def test_view_shows_placeholder_when_empty() raises:
    var input = TextInput()
    input.placeholder = String("Filter...")
    assert_equal(input.view(), "> ▏Filter...")


def test_view_scrolls_to_keep_cursor_visible() raises:
    var input = _typed(String("abcdefghij"))
    input.width = 4
    var out = input.view()
    assert_true("j" in out)
    assert_false("a" in out)

    _ = input.update(_key(Home()))
    var start = input.view()
    assert_true("a" in start)
    assert_false("j" in start)


def test_window_holds_still_while_the_cursor_moves() raises:
    # The stored offset is what makes this work: the window stays put and the
    # cursor moves inside it, rather than the text scrolling under a pinned
    # cursor. Deriving the window afresh each render loses this.
    var input = TextInput()
    input.prompt = String("")
    input.width = 5
    for codepoint in String("abcdefghij").codepoint_slices():
        _ = input.update(_key(Char(codepoint)))

    assert_equal(input.view(), "fghij▏")
    _ = input.update(_key(Left()))
    assert_equal(input.view(), "fghi▏j")
    _ = input.update(_key(Left()))
    assert_equal(input.view(), "fgh▏ij")
    _ = input.update(_key(Left()))
    assert_equal(input.view(), "fg▏hij")


def test_view_copes_with_a_stale_offset() raises:
    # Width changed since update last ran, so the stored offset is wrong.
    # view must still show the cursor, without writing anything back.
    var input = _typed(String("abcdefghij"))
    assert_equal(input.offset, 0)
    input.width = 4

    var out = input.view()
    assert_true("j" in out)
    assert_equal(input.offset, 0)


def test_set_value_and_reset() raises:
    var input = TextInput()
    input.set_value(String("hello"))
    assert_equal(input.value, "hello")
    assert_equal(input.cursor, 5)
    input.reset()
    assert_equal(input.value, "")
    assert_equal(input.cursor, 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
