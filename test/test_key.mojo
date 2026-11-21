from std.testing import TestSuite, assert_true, assert_false, assert_equal

from termctl.event.event import KeyCode, KeyEvent, KeyModifiers

from banjo.components.key import Binding, Help, matches, press


def _binding() raises -> Binding:
    return Binding([press(KeyCode.from_string("k")), press(KeyCode.up)], Help("up/k", "move up"))


def test_matches_any_bound_key() raises:
    var b = _binding()
    assert_true(matches(KeyEvent(KeyCode.from_string("k"), KeyModifiers.NONE), b))
    assert_true(matches(KeyEvent(KeyCode.up, KeyModifiers.NONE), b))


def test_ignores_unbound_key() raises:
    var b = _binding()
    assert_false(matches(KeyEvent(KeyCode.from_string("j"), KeyModifiers.NONE), b))
    assert_false(matches(KeyEvent(KeyCode.down, KeyModifiers.NONE), b))


def test_modifiers_must_agree() raises:
    var b = _binding()
    # A bare `k` binding must not fire on ctrl+k.
    assert_false(matches(KeyEvent(KeyCode.from_string("k"), KeyModifiers.CONTROL), b))

    var ctrl_c = Binding([press(KeyCode.from_string("c"), KeyModifiers.CONTROL)], Help("ctrl+c", "quit"))
    assert_true(matches(KeyEvent(KeyCode.from_string("c"), KeyModifiers.CONTROL), ctrl_c))
    assert_false(matches(KeyEvent(KeyCode.from_string("c"), KeyModifiers.NONE), ctrl_c))


def test_case_is_normalized() raises:
    # shift+g and G are the same keystroke; binding either way matches both.
    var shifted = Binding([press(KeyCode.from_string("G"))], Help("G", "go to end"))
    assert_true(matches(KeyEvent(KeyCode.from_string("G"), KeyModifiers.NONE), shifted))
    assert_true(matches(KeyEvent(KeyCode.from_string("g"), KeyModifiers.SHIFT), shifted))
    assert_false(matches(KeyEvent(KeyCode.from_string("g"), KeyModifiers.NONE), shifted))


def test_disabled_binding_never_fires() raises:
    var b = _binding()
    b.set_enabled(False)
    assert_false(b.enabled())
    assert_false(matches(KeyEvent(KeyCode.from_string("k"), KeyModifiers.NONE), b))

    b.set_enabled(True)
    assert_true(matches(KeyEvent(KeyCode.from_string("k"), KeyModifiers.NONE), b))


def test_unbound_binding_is_inert() raises:
    var b = _binding()
    b.unbind()
    assert_false(b.enabled())
    assert_false(matches(KeyEvent(KeyCode.from_string("k"), KeyModifiers.NONE), b))
    assert_equal(b.help.key, "")
    assert_equal(b.help.desc, "")


def test_binding_with_no_keys_is_disabled() raises:
    # Matches Go: a binding with no keystrokes is inert, not universal.
    var b = Binding(List[KeyEvent](), Help("", ""))
    assert_false(b.enabled())


def test_set_keys_and_help() raises:
    var b = _binding()
    b.set_keys([press(KeyCode.from_string("w"))])
    assert_false(matches(KeyEvent(KeyCode.from_string("k"), KeyModifiers.NONE), b))
    assert_true(matches(KeyEvent(KeyCode.from_string("w"), KeyModifiers.NONE), b))

    b.set_help("w", "move up")
    assert_equal(b.help.key, "w")
    assert_equal(b.help.desc, "move up")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
