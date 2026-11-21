from std.testing import TestSuite, assert_equal, assert_true

from banjo.components.progress import ProgressBar


def _plain(width: Int) raises -> ProgressBar:
    var bar = ProgressBar(width=width)
    bar.show_percentage = False
    return bar^


def test_empty_and_full() raises:
    var bar = _plain(10)
    assert_equal(bar.view(0.0), "░░░░░░░░░░")
    assert_equal(bar.view(1.0), "██████████")


def test_half() raises:
    assert_equal(_plain(10).view(0.5), "█████░░░░░")


def test_total_width_is_respected() raises:
    var bar = _plain(20)
    for i in range(11):
        assert_equal(bar.view(Float64(i) / 10.0).count_codepoints(), 20)


def test_out_of_range_values_are_clamped() raises:
    var bar = _plain(10)
    assert_equal(bar.view(-5.0), "░░░░░░░░░░")
    assert_equal(bar.view(42.0), "██████████")


def test_percentage_is_appended() raises:
    var bar = ProgressBar(width=14)
    assert_equal(bar.view(0.5), "█████░░░░░ 50%")


def test_percentage_narrows_the_bar() raises:
    var with_text = ProgressBar(width=14)
    var without = _plain(14)
    # Same total width; the bar itself is shorter when the text is shown.
    assert_equal(with_text.view(1.0).count_codepoints(), 14)
    assert_equal(without.view(1.0).count_codepoints(), 14)
    assert_true(with_text.view(1.0).count("█") < without.view(1.0).count("█"))


def test_percentage_rounds() raises:
    var bar = ProgressBar(width=20)
    assert_true(" 33%" in bar.view(1.0 / 3.0))
    assert_true(" 67%" in bar.view(2.0 / 3.0))


def test_custom_characters() raises:
    var bar = _plain(6)
    bar.full_char = String("=")
    bar.empty_char = String("-")
    assert_equal(bar.view(0.5), "===---")


def test_zero_width_is_harmless() raises:
    assert_equal(_plain(0).view(0.5), "")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
