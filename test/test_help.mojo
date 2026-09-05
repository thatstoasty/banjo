from std.testing import TestSuite, assert_equal, assert_true, assert_false

from termctl.event.event import Char, Down, Up

from banjo.components.help import HelpView
from banjo.components.key import Binding, Help, press


def _bindings() raises -> List[Binding]:
    return [
        Binding([press(Up())], Help("↑/k", "up")),
        Binding([press(Down())], Help("↓/j", "down")),
        Binding([press(Char("q"))], Help("q", "quit")),
    ]


def test_short_view_joins_entries() raises:
    var h = HelpView()
    assert_equal(h.short_view(_bindings()), "↑/k up • ↓/j down • q quit")


def test_short_view_is_empty_without_bindings() raises:
    var h = HelpView()
    assert_equal(h.short_view(List[Binding]()), "")


def test_short_view_skips_disabled_bindings() raises:
    var h = HelpView()
    var bindings = _bindings()
    bindings[1].set_enabled(False)
    # No leading or doubled separator where the disabled entry was.
    assert_equal(h.short_view(bindings), "↑/k up • q quit")


def test_short_view_skips_leading_disabled_binding() raises:
    var h = HelpView()
    var bindings = _bindings()
    bindings[0].set_enabled(False)
    assert_equal(h.short_view(bindings), "↓/j down • q quit")


def test_short_view_all_disabled_is_empty() raises:
    var h = HelpView()
    var bindings = _bindings()
    for i in range(len(bindings)):
        bindings[i].set_enabled(False)
    assert_equal(h.short_view(bindings), "")


def test_short_view_truncates_with_ellipsis() raises:
    var h = HelpView(width=20)
    var out = h.short_view(_bindings())
    assert_true("…" in out)
    assert_true("↑/k up" in out)
    assert_false("quit" in out)


def test_short_view_untruncated_when_it_fits() raises:
    var h = HelpView(width=200)
    assert_equal(h.short_view(_bindings()), "↑/k up • ↓/j down • q quit")


def test_full_view_builds_columns() raises:
    var h = HelpView()
    var groups = List[List[Binding]]()
    groups.append([Binding([press(Up())], Help("↑/k", "up")), Binding([press(Down())], Help("↓/j", "down"))])
    groups.append([Binding([press(Char("q"))], Help("q", "quit"))])

    var lines = h.full_view(groups).splitlines()
    # Two rows, because the tallest column has two bindings.
    assert_equal(len(lines), 2)
    assert_true("up" in String(lines[0]))
    assert_true("quit" in String(lines[0]))
    assert_true("down" in String(lines[1]))


def test_full_view_drops_empty_columns() raises:
    var h = HelpView()
    var groups = List[List[Binding]]()
    groups.append([Binding([press(Up())], Help("↑/k", "up"))])

    var disabled = Binding([press(Char("q"))], Help("q", "quit"))
    disabled.set_enabled(False)
    groups.append([disabled^])

    var out = h.full_view(groups)
    assert_true("up" in out)
    assert_false("quit" in out)


def test_full_view_is_empty_without_groups() raises:
    var h = HelpView()
    assert_equal(h.full_view(List[List[Binding]]()), "")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
