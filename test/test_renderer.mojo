from std.testing import TestSuite, assert_equal, assert_true, assert_false

from banjo.renderer import Renderer


comptime CLEAR_TO_EOL = "\x1b[0K"
"""What the renderer emits to wipe the rest of a line."""
comptime ERASE_BELOW = "\x1b[J"
"""What the renderer emits to wipe lines a shrinking frame left behind."""


def _rendered(frames: List[String]) raises -> String:
    """Renders frames in order and returns every byte written.

    The renderer writes to a file descriptor, so the frames go to a temporary
    file that is read back. That keeps the test on the real `flush` path rather
    than a reimplementation of it.

    Args:
        frames: The frames to write, in order.

    Returns:
        Everything the renderer emitted.

    Raises:
        Error: If the temporary file cannot be written or read.
    """
    var path = String("/tmp/banjo_test_renderer.txt")
    var handle = open(path, "w")
    var renderer = Renderer(FileDescriptor(handle._get_raw_fd()), 60)
    for ref frame in frames:
        renderer.write(frame)
    handle.close()

    var reader = open(path, "r")
    var out = reader.read()
    reader.close()
    return out^


def test_every_line_is_cleared_to_the_end() raises:
    # Without this a shrinking frame leaves the tail of the previous one on
    # screen: "done" drawn over "downloading" reads "donewnloading".
    var frames: List[String] = [String("downloading"), String("done")]
    var out = _rendered(frames)

    assert_true(CLEAR_TO_EOL in out)
    assert_true(out.count(CLEAR_TO_EOL) >= 2)
    assert_true("downloading" in out)
    assert_true("done" in out)


def test_shorter_frame_clears_before_the_next_write() raises:
    var frames: List[String] = [String("downloading"), String("done")]
    var out = _rendered(frames)

    # The clear must follow the shorter text, not precede it.
    var at = out.find("done")
    assert_true(at >= 0)
    assert_true(CLEAR_TO_EOL in String(out[byte=at:]))


def test_multiline_frames_clear_every_line() raises:
    var frames: List[String] = [String("aaaa\nbbbb\ncccc")]
    var out = _rendered(frames)
    assert_equal(out.count(CLEAR_TO_EOL), 3)


def test_shrinking_line_count_erases_below() raises:
    var frames: List[String] = [String("aaaa\nbbbb\ncccc"), String("xx\nyy")]
    var out = _rendered(frames)
    # Two lines cleared to end of line, plus the vanished third line erased.
    assert_true(ERASE_BELOW in out)


def test_identical_frame_is_not_redrawn() raises:
    var repeated: List[String] = [String("same"), String("same"), String("same")]
    var once: List[String] = [String("same")]
    assert_equal(_rendered(repeated), _rendered(once))


def test_empty_frame_still_paints() raises:
    # An empty view must clear the previous one rather than leave it up.
    var frames: List[String] = [String("something"), String("")]
    var out = _rendered(frames)
    assert_true(out.count(CLEAR_TO_EOL) >= 2)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
