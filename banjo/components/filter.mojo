"""Fuzzy matching for filtering a list.

`bubbles` delegates this to `sahilm/fuzzy`. This is a small subsequence matcher
in the same spirit: a target matches when the pattern's characters appear in
order, and matches score better when those characters are adjacent, land at the
start of a word, or land near the start of the target.

Matching is case-insensitive for ASCII. The matched positions come back with
each result, so a caller can highlight them once `mog` grows the equivalent of
lipgloss's `StyleRunes`.

```mojo
for ref hit in rank(String("bry"), names):
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


def _fold(text: StringSpan) -> List[String]:
    """Splits text into codepoints, lowercasing ASCII letters.

    Args:
        text: The text to split.

    Returns:
        One lowercased string per codepoint.
    """
    var out = List[String]()
    for codepoint in text.codepoint_slices():
        var s = String(codepoint)
        if s.byte_length() == 1:
            var b = s.as_bytes()[0]
            if b >= UInt8(ord("A")) and b <= UInt8(ord("Z")):
                s = String(chr(Int(b) + 32))
        out.append(s^)
    return out^


def _is_word_boundary(previous: StringSpan) -> Bool:
    """Reports whether a character following `previous` starts a word.

    Args:
        previous: The preceding character.

    Returns:
        True if `previous` separates words.
    """
    return previous == " " or previous == "-" or previous == "_" or previous == "/" or previous == "."


@fieldwise_init
struct Match(Copyable, Movable):
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
    var needle = _fold(pattern)
    var haystack = _fold(target)

    if len(needle) == 0:
        return Match(0, 0, List[Int]())

    var matched = List[Int]()
    var score = 0
    var n = 0

    for h in range(len(haystack)):
        if n >= len(needle):
            break
        if haystack[h] != needle[n]:
            continue

        if len(matched) == 0:
            var skipped = h
            if skipped > _MAX_LEADING_PENALTY:
                skipped = _MAX_LEADING_PENALTY
            score -= skipped * _LEADING_PENALTY
        elif matched[len(matched) - 1] == h - 1:
            score += _ADJACENT_BONUS

        if h > 0 and _is_word_boundary(haystack[h - 1]):
            score += _WORD_START_BONUS

        matched.append(h)
        n += 1

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
    var hits = List[Match]()
    for i in range(len(targets)):
        var hit = find(pattern, targets[i])
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
