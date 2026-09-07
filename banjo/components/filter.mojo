"""Fuzzy matching for filtering a list.

`bubbles` delegates this to `sahilm/fuzzy`. This is a small subsequence matcher
in the same spirit: a target matches when the pattern's characters appear in
order, and matches score better when those characters are adjacent, land at the
start of a word, or land near the start of the target.

Matching is case-insensitive for ASCII. The matched positions come back with
each result, so a caller can highlight them once `mog` grows the equivalent of
lipgloss's `StyleRunes`.

```mojo
for ref hit in rank("bry", names):
    print(names[hit.index], hit.score)
```
"""


comptime _ADJACENT_BONUS = 8
"""Added when a match immediately follows the previous one."""
comptime _WORD_START_BONUS = 6
"""Added when a match begins a word."""
comptime _LEADING_PENALTY = 1
"""Subtracted per character skipped before the first match, up to a limit."""
comptime _MAX_LEADING_PENALTY = 6
"""The most the leading penalty can subtract."""

comptime A_BYTE = Byte(ord("A"))
"""Lower bound of the ASCII uppercase range, which is all that case folding covers."""
comptime Z_BYTE = Byte(ord("Z"))
"""Upper bound of the ASCII uppercase range."""


def _lowered(byte: Byte) -> Byte:
    """Lowercases one ASCII byte, leaving anything else alone.

    Args:
        byte: The byte to lower.

    Returns:
        The lowercased byte.
    """
    if byte >= A_BYTE and byte <= Z_BYTE:
        return byte + 32
    return byte


def _same_folded(left: StringSpan, right: StringSpan) -> Bool:
    """Compares two codepoints, ignoring ASCII case.

    Comparing in place rather than folding whole strings first is what keeps
    matching allocation-free: `rank` walks every target, and folding each one
    would allocate a string per target per query.

    Only ASCII case is folded, so anything multi-byte compares as itself --
    which is also why the two lengths differing means unequal.

    Args:
        left: One codepoint.
        right: The other.

    Returns:
        True if they are the same letter, ignoring ASCII case.
    """
    if left.byte_length() != right.byte_length():
        return False
    if left.byte_length() == 1:
        return _lowered(left.as_bytes()[0]) == _lowered(right.as_bytes()[0])
    return left == right


def _is_word_boundary(previous: StringSpan) -> Bool:
    """Reports whether a character following `previous` starts a word.

    Args:
        previous: The preceding character.

    Returns:
        True if `previous` separates words.
    """
    return previous == " " or previous == "-" or previous == "_" or previous == "/" or previous == "."


@fieldwise_init
struct Match(Copyable):
    """One target that matched the pattern."""

    var index: Int
    """Position of the target in the list that was searched."""
    var score: Int
    """How good the match is. Higher is better."""
    var matched: List[Int]
    """Codepoint positions in the target that the pattern matched."""


def find(pattern: StringSpan, target: StringSpan) -> Optional[Match]:
    """Matches a pattern against one target.

    An empty pattern matches everything with a score of zero, which lets a
    caller treat "no filter typed yet" as "show all" without a special case.

    Args:
        pattern: What the user typed.
        target: The text to match against.

    Returns:
        The match, or None if the pattern does not appear in order.
    """
    return _find(_needle(pattern), target)


def _needle(pattern: StringSpan) -> List[String]:
    """Splits a pattern into the codepoints matching compares against.

    The pattern is a user's query, so this is a handful of allocations. `rank`
    does it once rather than once per target.

    Args:
        pattern: What the user typed.

    Returns:
        One string per codepoint.
    """
    var out = List[String]()
    for codepoint in pattern.codepoint_slices():
        out.append(String(codepoint))
    return out^


def _find(needle: List[String], target: StringSpan) -> Optional[Match]:
    """Matches a prepared pattern against one target.

    Args:
        needle: The pattern's codepoints, from `_needle`.
        target: The text to match against.

    Returns:
        The match, or None if the pattern does not appear in order.
    """
    if len(needle) == 0:
        return Match(0, 0, List[Int]())

    var matched = List[Int]()
    var score = 0
    var n = 0
    var h = 0

    # Only whether the previous codepoint ended a word matters, not what it
    # was -- so keep the answer rather than a copy of the character.
    var after_boundary = False

    for codepoint in target.codepoint_slices():
        if n >= len(needle):
            break

        if _same_folded(codepoint, needle[n]):
            if len(matched) == 0:
                var skipped = h
                if skipped > _MAX_LEADING_PENALTY:
                    skipped = _MAX_LEADING_PENALTY
                score -= skipped * _LEADING_PENALTY
            elif matched[len(matched) - 1] == h - 1:
                score += _ADJACENT_BONUS

            if h > 0 and after_boundary:
                score += _WORD_START_BONUS

            matched.append(h)
            n += 1

        after_boundary = _is_word_boundary(codepoint)
        h += 1

    if n < len(needle):
        return None
    return Match(0, score, matched^)


def rank(pattern: StringSpan, targets: List[String]) -> List[Match]:
    """Matches a pattern against every target, best first.

    Ties keep the original order, so an empty pattern returns the targets
    unchanged rather than in some arbitrary arrangement.

    Args:
        pattern: What the user typed.
        targets: The texts to match against.

    Returns:
        The matches, sorted by descending score.
    """
    var needle = _needle(pattern)

    var hits = List[Match]()
    for i in range(len(targets)):
        var hit = _find(needle, targets[i])
        if hit:
            var m = hit.take()
            m.index = i
            hits.append(m^)

    # Insertion sort, stable, over what is at most a screenful of candidates.
    for i in range(1, len(hits)):
        var j = i
        while j > 0 and hits[j].score > hits[j - 1].score:
            hits.swap_elements(j, j - 1)
            j -= 1

    return hits^
