"""User-definable key bindings, with the help text that goes with them.

A port of `bubbles/key`, with one deliberate departure: bindings match on
`KeyEvent` values rather than on strings. Go compares `msg.String()` against
`"ctrl+c"` and friends, which means inventing and policing a key vocabulary.
`termctl` already delivers structured key codes and modifiers, so binding
directly on them keeps matching type-checked and drops the vocabulary entirely.

```mojo
@fieldwise_init
struct KeyMap(Copyable):
    var up: Binding
    var down: Binding

    def __init__(out self):
        self.up = Binding([press(Char("k")), press(Up())], Help("up/k", "move up"))
        self.down = Binding([press(Char("j")), press(Down())], Help("down/j", "move down"))

# in update:
if matches(event, keymap.up):
    ...
```
"""

from termctl.event.event import Char, KeyCode, KeyEvent, KeyModifiers


def press(code: KeyCode, modifiers: KeyModifiers = KeyModifiers.NONE) -> KeyEvent:
    """Builds a key event suitable for use in a binding.

    Args:
        code: The key itself.
        modifiers: Modifiers that must be held for the binding to match.

    Returns:
        A key press event.
    """
    return KeyEvent(code, modifiers)


@fieldwise_init
struct Help(Copyable, Writable):
    """The help text for a single binding."""

    var key: String
    """How the keystroke is displayed, for example `up/k`."""
    var desc: String
    """What the keystroke does, for example `move up`."""

    def __init__(out self):
        """Creates empty help text."""
        self.key = String()
        self.desc = String()


struct Binding(Copyable):
    """A set of keystrokes and, optionally, the help text describing them."""

    var keys: List[KeyEvent]
    """Every keystroke that triggers this binding."""
    var help: Help
    """How this binding is described in a help view."""
    var disabled: Bool
    """Whether this binding is currently switched off."""

    def __init__(out self, var keys: List[KeyEvent], var help: Help = Help(), disabled: Bool = False):
        """Creates a binding.

        Args:
            keys: The keystrokes that trigger it.
            help: How to describe it in a help view.
            disabled: Whether it starts switched off.
        """
        self.keys = keys^
        self.help = help^
        self.disabled = disabled

    def set_keys(mut self, var keys: List[KeyEvent]):
        """Replaces the keystrokes that trigger this binding.

        Args:
            keys: The new keystrokes.
        """
        self.keys = keys^

    def set_help(mut self, var key: String, var desc: String):
        """Replaces the help text.

        Args:
            key: How the keystroke is displayed.
            desc: What the keystroke does.
        """
        self.help = Help(key^, desc^)

    def enabled(self) -> Bool:
        """Reports whether this binding can currently fire.

        A binding with no keystrokes is never enabled, matching the Go original
        where an unbound binding is inert rather than universally matching.

        Returns:
            True if the binding is switched on and has at least one keystroke.
        """
        return not self.disabled and len(self.keys) > 0

    def set_enabled(mut self, value: Bool):
        """Switches this binding on or off.

        A disabled binding neither fires nor appears in help.

        Args:
            value: True to enable, False to disable.
        """
        self.disabled = not value

    def unbind(mut self):
        """Strips the keystrokes and help from this binding.

        A step beyond disabling: `set_enabled` is for bindings that come and go
        with application state, whereas this nullifies the binding outright.
        """
        self.keys = List[KeyEvent]()
        self.help = Help()


def _fold_case(event: KeyEvent) raises -> Tuple[KeyCode, KeyModifiers]:
    """Folds a keystroke into a canonical code and modifier pair.

    `G`, `shift+g` and `shift+G` are one keystroke as far as a binding is
    concerned, so all three fold to `G` with Shift held. Without this a binding
    written one way would silently miss the other spellings.

    Note that `KeyEvent.__eq__` cannot be used for this. It is declared
    `raises`, so it does not satisfy the `Equatable` requirement `EventType`
    carries, and `==` on a `KeyEvent` resolves to structural equality instead --
    which compares the raw code and modifiers and folds nothing.

    Args:
        event: The keystroke to fold.

    Returns:
        The canonical key code and modifiers.

    Raises:
        Error: If the shifted codepoint is not valid Unicode.
    """
    var code = event.code
    var modifiers = event.modifiers

    if not code.isa[Char]():
        return (code, modifiers)

    var character = code[Char].char
    if character.is_ascii_upper():
        modifiers.insert(KeyModifiers.SHIFT)
    elif modifiers.contains(KeyModifiers.SHIFT):
        var codepoint = character.to_u32()
        if codepoint >= 97 and codepoint <= 122:
            code = KeyCode(Char(codepoint - 32))

    return (code, modifiers)


def matches(event: KeyEvent, binding: Binding) raises -> Bool:
    """Reports whether a key event triggers a binding.

    Only the key and its modifiers are compared. The event kind is ignored, so
    a held key repeating still fires the binding, and lock state is ignored, so
    Caps Lock does not stop one from matching.

    Args:
        event: The key event that arrived.
        binding: The binding to test against.

    Returns:
        True if the binding is enabled and one of its keystrokes matches.

    Raises:
        Error: Propagated from folding a keystroke.
    """
    if not binding.enabled():
        return False

    var pressed = _fold_case(event)
    for ref candidate in binding.keys:
        var bound = _fold_case(candidate)
        if pressed[0] == bound[0] and pressed[1] == bound[1]:
            return True
    return False
