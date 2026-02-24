from mist.terminal.cursor import move_cursor_sequence, ERASE_DISPLAY, cursor_up_sequence
from mist.terminal.screen import CLEAR_LINE_RIGHT
from mist.transform.ansi import string_width
from mist.transform import truncate
from mist.terminal.sgr import CSI

comptime DEFAULT_FPS = 60.0
comptime MAX_FPS = 120.0

# TODO: Add these to mist
comptime EraseScreenBelow   = CSI + "J"
comptime EraseScreenAbove   = CSI + "1J"
comptime EraseEntireScreen  = CSI + "2J"
comptime EraseEntireDisplay = CSI + "3J"


@fieldwise_init
struct Renderer(Copyable):
    """A simple renderer that prints to the terminal."""
    var writer: FileDescriptor
    var buf: String
    var queued_message_lines: List[String]
    var framerate: Float64
    """The framerate of the renderer in frames per second."""
    # ticker             *time.Ticker
    # var done               chan struct{
    var last_render: String
    var last_rendered_lines: List[String]
    var lines_rendered: Int
    var alt_lines_rendered: Int
    # var useANSICompressor: Bool
    # var once: sync.Once

    # cursor visibility state
    var cursor_hidden: Bool

    # essentially whether or not we're using the full size of the terminal
    var alt_screen_active: Bool

    # whether or not we're currently using bracketed paste
    var bp_active: Bool

    # reporting_focus whether reporting focus events is enabled
    var reporting_focus: Bool

    # renderer dimensions; usually the size of the window
    var width: Int
    var height: Int

	# lines explicitly set not to render
	# var ignoreLines: map[int]struct{

    fn __init__(out self, writer: FileDescriptor, fps: Int):
        var framerate = Float64(fps)
        if framerate < 1:
            framerate = DEFAULT_FPS
        elif framerate > MAX_FPS:
            framerate = MAX_FPS

        self.writer = writer
        self.buf = String(capacity=1024)
        self.framerate = 1.0 / framerate
        self.queued_message_lines = List[String]()
        self.last_render = ""
        self.last_rendered_lines = List[String]()
        self.lines_rendered = 0
        self.alt_lines_rendered = 0
        self.cursor_hidden = False
        self.alt_screen_active = False
        self.bp_active = False
        self.reporting_focus = False
        self.width = 0
        self.height = 0

    fn execute(mut self, seq: StringSlice):
        """Executes the given sequence on the terminal."""
        self.writer.write(seq)

    fn last_lines_rendered(self) -> Int:
        """Returns the number of lines rendered in the last render."""
        if self.alt_screen_active:
            return self.alt_lines_rendered
        return self.lines_rendered

    # flush renders the buffer.
    fn flush(mut self):
        # r.mtx.Lock()
        # defer r.mtx.Unlock()

        if len(self.buf) == 0 or self.buf == self.last_render:
            # Nothing to do.
            return

        # Output buffer.
        var buf = String()

        # Moving to the beginning of the section, that we rendered.
        if self.alt_screen_active:
            buf.write_string(ERASE_DISPLAY)
        elif self.lines_rendered > 1:
            buf.write_string(cursor_up_sequence(self.lines_rendered - 1))

        var new_lines = self.buf.splitlines()
        var newLines = Span(new_lines)

        # If we know the output's height, we can use it to determine how many
        # lines we can render. We drop lines from the top of the render buffer if
        # necessary, as we can't navigate the cursor into the terminal's scrollback
        # buffer.
        if self.height > 0 and len(newLines) > self.height:
            newLines = newLines[len(newLines)-self.height:]

        # var flushQueuedMessages = len(self.queued_message_lines) > 0 and not self.alt_screen_active
        # if flushQueuedMessages:
        #     # Dump the lines we've queued up for printing.
        #     for line in self.queued_message_lines:
        #         buf.write_string(line)
        #         if string_width(line) < self.width:
        #             # We only erase the rest of the line when the line is shorter than
        #             # the width of the terminal. When the cursor reaches the end of
        #             # the line, any escape sequences that follow will only affect the
        #             # last cell of the line.

        #             # Removing previously rendered content at the end of line.
        #             buf.write_string(CLEAR_LINE_RIGHT)
        #         buf.write_string("\r\n")

        #     # Clear the queued message lines.
        #     self.queued_message_lines = List[String]()

        # Paint new lines.
        var i = 0
        while i < len(newLines):
            # Queuing messages triggers repaint -> we don't have access to previous frame content.
            # Previously rendered line is the same.
            # var canSkip = not flushQueuedMessages and len(self.last_rendered_lines) > i and self.last_rendered_lines[i] == newLines[i]
            # # ref ignore = self.ignoreLines[i]
            # # if ignore or canSkip:
            # if canSkip:
            #     # Unless this is the last line, move the cursor down.
            #     if i < len(newLines)-1:
            #         buf.write("\n")
            #     continue

            if i == 0 and self.last_render == "":
                # On first render, reset the cursor to the start of the line
                # before writing anything.
                buf.write("\r")

            var line = String(newLines[i])

            # Truncate lines wider than the width of the window to avoid
            # wrapping, which will mess up rendering. If we don't have the
            # width of the window this will be ignored.
            #
            # Note that on Windows we only get the width of the window on
            # program initialization, so after a resize this won't perform
            # correctly (signal SIGWINCH is not supported on Windows).
            if self.width > 0:
                line = truncate(line, self.width, "")

            buf.write_string(line)
            if string_width(line) < self.width:
                # We only erase the rest of the line when the line is shorter than
                # the width of the terminal. When the cursor reaches the end of
                # the line, any escape sequences that follow will only affect the
                # last cell of the line.

                # Removing previously rendered content at the end of line.
                buf.write_string(CLEAR_LINE_RIGHT)

            if i < len(newLines)-1:
                buf.write_string("\r\n")
            i += 1

        # Clearing left over content from last render.
        if self.last_lines_rendered() > len(newLines):
            buf.write_string(EraseScreenBelow)

        if self.alt_screen_active:
            self.alt_lines_rendered = len(newLines)
        else:
            self.lines_rendered = len(newLines)

        # Make sure the cursor is at the start of the last line to keep rendering
        # behavior consistent.
        if self.alt_screen_active:
            # This case fixes a bug in macOS terminal. In other terminals the
            # other case seems to do the job regardless of whether or not we're
            # using the full terminal window.
            buf.write_string(move_cursor_sequence(0, len(newLines)))
        else:
            buf.write("\r")

        self.writer.write(buf)
        self.last_render = self.buf

        # Save previously rendered lines for comparison in the next render. If we
        # don't do this, we can't skip rendering lines that haven't changed.
        self.last_rendered_lines = [String(line) for line in newLines]
        self.buf = String()

    fn write(mut self, str: StringSlice) -> None:
        """Writes the given input to the terminal.

        Args:
            str: The input to write to the terminal.
        """
        # TODO: Handle fps. Need to figure out how to do it without blocking the thread,
        # since we need to be able to write to the terminal at any time, even if the framerate is low.
        self.buf = String(capacity=1024)
        if len(str) == 0:
            self.buf.write_string(" ")
            return

        self.buf.write_string(str)
        # TODO: Flushing here bc no async flushing via fps yet.
        self.flush()

    # fn write(mut self, str: StringSlice) -> None:
    #     """Writes the given input to the terminal.

    #     Args:
    #         str: The input to write to the terminal.
    #     """
    #     var lines = str.splitlines()
    #     print(move_cursor_sequence(0, len(lines)), ERASE_DISPLAY, "\r\n".join(lines), end="\r\n")
