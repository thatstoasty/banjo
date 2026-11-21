from std.testing import TestSuite, assert_equal, assert_true

from banjo.components.spinner import Frames, Spinner


def test_starts_on_the_first_frame() raises:
    var s = Spinner.LINE
    assert_equal(s.view(), "|")
    assert_equal(s.frame, 0)


def test_advance_cycles_and_wraps() raises:
    var s = Spinner.LINE
    assert_equal(s.view(), "|")
    s.advance()
    assert_equal(s.view(), "/")
    s.advance()
    assert_equal(s.view(), "-")
    s.advance()
    assert_equal(s.view(), "\\")
    s.advance()
    assert_equal(s.view(), "|")


def test_reset_returns_to_the_first_frame() raises:
    var s = Spinner.LINE
    s.advance()
    s.advance()
    s.reset()
    assert_equal(s.view(), "|")


def test_hz_comes_from_the_frame_set() raises:
    assert_equal(Spinner.LINE.hz(), 10.0)
    assert_equal(Spinner.MINI_DOT.hz(), 12.0)
    assert_equal(Spinner.PULSE.hz(), 8.0)


def test_empty_frame_set_is_harmless() raises:
    var s = Spinner(Frames(List[String](), 10.0))
    assert_equal(s.view(), "")
    s.advance()
    assert_equal(s.view(), "")


def test_view_survives_a_shortened_frame_set() raises:
    # The index can outlive the frames it was valid for.
    var s = Spinner(Frames.MOON)
    for _ in range(7):
        s.advance()
    assert_equal(s.frame, 7)
    s.frames = Spinner.LINE.frames
    assert_equal(s.view(), "\\")


def test_frame_sets_are_non_empty() raises:
    assert_true(len(Spinner.LINE.frames) > 0)
    assert_true(len(Spinner.DOT.frames) > 0)
    assert_true(len(Spinner.MINI_DOT.frames) > 0)
    assert_true(len(Spinner.MOON.frames) == 8)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
