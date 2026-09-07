from std.testing import TestSuite, assert_equal, assert_true, assert_false

from mog import Profile

from banjo.components.default_item import DefaultItemStyles, default_item


def _styles() raises -> DefaultItemStyles:
    # ASCII keeps the rendered output free of colour codes so it can be asserted on.
    return DefaultItemStyles(Profile.ASCII)


def test_item_has_title_and_description() raises:
    var item = default_item(String("Raspberry"), String("A red berry"), _styles())
    assert_equal(item.height(), 2)
    assert_true("Raspberry" in item.content)
    assert_true("A red berry" in item.content)


def test_item_carries_a_selected_appearance() raises:
    var item = default_item(String("Raspberry"), String("A red berry"), _styles())
    assert_true(item.selected_content.__bool__())
    # The selected variant is marked differently from the normal one; that is
    # the whole reason ListItem stores both.
    assert_true(item.selected_content.value() != item.content)
    assert_true("Raspberry" in item.selected_content.value())


def test_selected_variant_has_the_border_bar() raises:
    var item = default_item(String("Raspberry"), String("A red berry"), _styles())
    assert_true("│" in item.selected_content.value())
    assert_false("│" in item.content)


def test_description_can_be_hidden() raises:
    var item = default_item(String("Raspberry"), String("A red berry"), _styles(), show_description=False)
    assert_equal(item.height(), 1)
    assert_true("Raspberry" in item.content)
    assert_false("A red berry" in item.content)
    assert_true(item.selected_content.__bool__())
    assert_equal(item.selected_content.value().count("\n"), 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
