from mist.transform.ansi import string_width
from mist.transform import truncate
from termctl.terminal.sgr import CSI
from termctl.terminal.cursor import move_cursor_sequence, ERASE_DISPLAY, cursor_up_sequence
from termctl.terminal.screen import CLEAR_LINE_RIGHT
from termctl.terminal.size import terminal_size

comptime DEFAULT_FPS = 60.0
comptime MAX_FPS = 120.0

# TODO: Add these to mist
comptime EraseScreenBelow = CSI + "J"
comptime EraseScreenAbove = CSI + "1J"
comptime EraseEntireScreen = CSI + "2J"
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
    var lines_rendered: UInt16
    var alt_lines_rendered: UInt16
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
    var width: UInt16
    var height: UInt16

    # lines explicitly set not to render
    # var ignoreLines: map[int]struct{

    def __init__(out self, writer: FileDescriptor, fps: Int):
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

    def execute(mut self, seq: StringSpan):
        """Executes the given sequence on the terminal."""
        self.writer.write(seq)

    def last_lines_rendered(self) -> UInt16:
        """Returns the number of lines rendered in the last render."""
        if self.alt_screen_active:
            return self.alt_lines_rendered
        return self.lines_rendered

    def refresh_size(mut self) -> Bool:
        """Re-reads the terminal's dimensions from the kernel.

        One `ioctl`, a few hundred nanoseconds, touching neither the terminal
        nor the input stream. That is cheap enough to do every frame, which is
        why resizing needs no `SIGWINCH` handler: the next paint simply
        measures again. A descriptor that is not a terminal leaves the
        dimensions at zero, which disables truncation and the height clamp
        rather than guessing at a size.

        Returns:
            True if the dimensions changed, meaning the frame must be repainted
            even if its content did not change.
        """
        var measured = terminal_size(self.writer)
        if not measured:
            return False

        ref size = measured.value()
        if size.columns == self.width and size.rows == self.height:
            return False

        self.width = size.columns
        self.height = size.rows
        return True

    # flush renders the buffer.
    def flush(mut self):
        # r.mtx.Lock()
        # defer r.mtx.Unlock()

        # A resize changes how the same content has to be drawn -- what gets
        # truncated, how many lines fit -- so it has to defeat the
        # unchanged-frame shortcut below.
        var resized = self.refresh_size()

        if self.buf.byte_length() == 0:
            # Nothing to do.
            return

        if not resized and self.buf == self.last_render:
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
        if self.height > 0 and UInt16(len(newLines)) > self.height:
            newLines = newLines[len(newLines) - Int(self.height) :]

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
                line = truncate(line, UInt(self.width), "")

            buf.write_string(line)
            if self.width == 0 or string_width(line) < UInt(self.width):
                # Erase whatever the previous frame left to the right of this
                # line, or a frame that shrinks leaves a tail behind: drawing
                # "done" over "downloading" would otherwise read "donewnloading".
                #
                # The check skips a line that exactly fills the terminal, where
                # the cursor has nowhere left to sit and the sequence would
                # affect the last cell instead. An unknown width -- which is
                # the usual case, since nothing measures the terminal yet --
                # cannot hit that, so it always erases.
                buf.write_string(CLEAR_LINE_RIGHT)

            if i < len(newLines) - 1:
                buf.write_string("\r\n")
            i += 1

        # Clearing left over content from last render.
        if self.last_lines_rendered() > UInt16(len(newLines)):
            buf.write_string(EraseScreenBelow)

        if self.alt_screen_active:
            self.alt_lines_rendered = UInt16(len(newLines))
        else:
            self.lines_rendered = UInt16(len(newLines))

        # Make sure the cursor is at the start of the last line to keep rendering
        # behavior consistent.
        if self.alt_screen_active:
            # This case fixes a bug in macOS terminal. In other terminals the
            # other case seems to do the job regardless of whether or not we're
            # using the full terminal window.
            buf.write_string(move_cursor_sequence(0, UInt16(len(newLines))))
        else:
            buf.write("\r")

        self.writer.write(buf)
        self.last_render = self.buf

        # Save previously rendered lines for comparison in the next render. If we
        # don't do this, we can't skip rendering lines that haven't changed.
        self.last_rendered_lines = [String(line) for line in newLines]

        # Rebind rather than clear in place. `newLines` are slices borrowing
        # this buffer and are still live here, so mutating it (`resize(0)`)
        # instead of replacing it pins a fresh allocation every flush -- a leak
        # of ~150KB per frame that only shows up once something renders on a
        # timer rather than per keystroke.
        self.buf = String(capacity=1024)

    def write(mut self, str: StringSpan) -> None:
        """Writes the given input to the terminal and flushes it.

        Pacing is the caller's job -- see `banjo.loop` -- so this paints
        whenever it is called. `flush` still drops a frame identical to the one
        already on screen, so calling this on a timer costs nothing while the
        view is unchanged.

        Args:
            str: The input to write to the terminal.
        """
        self.buf = String(capacity=1024)
        # An empty frame is still a frame. Returning early here would leave the
        # previous one on screen with nothing to replace it.
        if str.byte_length() == 0:
            self.buf.write_string(" ")
        else:
            self.buf.write_string(str)

        self.flush()

    # def write(mut self, str: StringSpan) -> None:
    #     """Writes the given input to the terminal.

    #     Args:
    #         str: The input to write to the terminal.
    #     """
    #     var lines = str.splitlines()
    #     print(move_cursor_sequence(0, len(lines)), ERASE_DISPLAY, "\r\n".join(lines), end="\r\n")
