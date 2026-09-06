from std.testing import TestSuite, assert_equal, assert_true, assert_false

from banjo.renderer import Renderer


comptime CLEAR_TO_EOL = "\x1b[0K"
"""What the renderer emits to wipe the rest of a line."""
comptime ERASE_BELOW = "\x1b[J"
"""What the renderer emits to wipe lines a shrinking frame left behind."""


def _rendered_at(frames: List[String], width: UInt16, height: UInt16) raises -> String:
    """Renders frames at a forced size and returns every byte written.

    The temporary file the renderer writes to is not a terminal, so measuring
    it leaves the dimensions alone -- which is what lets a test set them.

    Args:
        frames: The frames to write, in order.
        width: Columns to render into. Zero means unknown.
        height: Rows to render into. Zero means unknown.

    Returns:
        Everything the renderer emitted.

    Raises:
        Error: If the temporary file cannot be written or read.
    """
    var path = String("/tmp/banjo_test_renderer_sized.txt")
    var handle = open(path, "w")
    var renderer = Renderer(FileDescriptor(handle._get_raw_fd()), 60)
    renderer.width = width
    renderer.height = height
    for ref frame in frames:
        renderer.write(frame)
    handle.close()

    var reader = open(path, "r")
    var out = reader.read()
    reader.close()
    return out^


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


def test_a_file_is_not_a_terminal() raises:
    # Measuring a non-terminal must leave the dimensions alone rather than
    # guess, which is what keeps truncation off when the size is unknown.
    var path = String("/tmp/banjo_test_renderer_notty.txt")
    var handle = open(path, "w")
    var renderer = Renderer(FileDescriptor(handle._get_raw_fd()), 60)

    assert_equal(renderer.width, 0)
    assert_false(renderer.refresh_size())
    assert_equal(renderer.width, 0)
    assert_equal(renderer.height, 0)
    handle.close()


def test_long_lines_are_truncated_to_the_width() raises:
    # Without this a line wider than the terminal wraps and corrupts the frame.
    var long = String()
    for i in range(120):
        long.write_string(String(i % 10))

    var frames: List[String] = [long^]
    var out = _rendered_at(frames, 20, 0)

    for ref line in out.splitlines():
        var text = String(line).replace(CLEAR_TO_EOL, "").replace("\r", "")
        assert_true(text.count_codepoints() <= 20)


def test_frames_taller_than_the_terminal_keep_the_last_lines() raises:
    # The cursor cannot be driven into scrollback, so the top is dropped.
    var tall = String()
    for i in range(40):
        tall.write_string(String("line", i))
        if i < 39:
            tall.write_string("\n")

    var frames: List[String] = [tall^]
    var out = _rendered_at(frames, 0, 10)

    assert_true("line39" in out)
    assert_true("line30" in out)
    assert_false("line29" in out)


def test_unknown_width_does_not_truncate() raises:
    var long = String()
    for i in range(120):
        long.write_string(String(i % 10))

    var frames: List[String] = [long.copy()]
    var out = _rendered_at(frames, 0, 0)
    assert_true(long in out)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
