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
from std.collections.string.iterators import GraphemeSliceIter


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


def _same_folded(left: ImmStringSpan, right: ImmStringSpan) -> Bool:
    """Compares two grapheme clusters, ignoring ASCII case.

    Comparing in place rather than folding whole strings first is what keeps
    matching allocation-free: `rank` walks every target, and folding each one
    would allocate a string per target per query.

    Only ASCII case is folded, so anything multi-byte compares as itself --
    which is also why the two lengths differing means unequal.

    Args:
        left: One cluster.
        right: The other.

    Returns:
        True if they are the same letter, ignoring ASCII case.
    """
    if left.byte_length() != right.byte_length():
        return False
    if left.byte_length() == 1:
        return _lowered(left.as_bytes()[0]) == _lowered(right.as_bytes()[0])
    return left == right


def _is_word_boundary(previous: ImmStringSpan) -> Bool:
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
    """Grapheme positions in the target that the pattern matched.

    Counted in clusters rather than codepoints or bytes, so a caller can use
    them as column offsets when highlighting what matched.
    """


def find(pattern: ImmStringSpan, target: ImmStringSpan) -> Optional[Match]:
    """Matches a pattern against one target.

    An empty pattern matches everything with a score of zero, which lets a
    caller treat "no filter typed yet" as "show all" without a special case.

    Args:
        pattern: What the user typed.
        target: The text to match against.

    Returns:
        The match, or None if the pattern does not appear in order.
    """
    return _find(pattern.graphemes(), target)


def _find[origin: ImmOrigin, //](var needle: GraphemeSliceIter[origin], target: ImmStringSpan) -> Optional[Match]:
    """Matches a prepared pattern against one target.

    Takes the iterator by value, so matching walks a copy and the caller's own
    position is untouched. `rank` matches one pattern against many targets, and
    a shared iterator would be eaten by the first of them, leaving every later
    target to match against nothing. Copying is free: an iterator is a pointer
    and a length, which is what makes building it once still worth doing.

    Args:
        needle: The pattern's grapheme clusters.
        target: The text to match against.

    Returns:
        The match, or None if the pattern does not appear in order.
    """
    # Held rather than peeked at. The cluster being looked for only changes
    # when one is found, so reading it once per match beats re-reading it on
    # every character of the target -- and `GraphemeSliceIter` has no
    # `peek_next`, which is what makes this the shape to write.
    var wanted = needle.next()
    if not wanted:
        return Match(0, 0, [])

    var matched = List[Int]()
    var score = 0
    var h = 0

    # Only whether the previous cluster ended a word matters, not what it
    # was -- so keep the answer rather than a copy of the character.
    var after_boundary = False

    for grapheme in target.graphemes():
        # Nothing left to look for means the whole pattern has been found.
        if not wanted:
            break

        if _same_folded(grapheme, wanted.value()):
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
            wanted = needle.next()

        after_boundary = _is_word_boundary(grapheme)
        h += 1

    if wanted:
        return None
    return Match(0, score, matched^)


def rank(pattern: ImmStringSpan, targets: List[String]) -> List[Match]:
    """Matches a pattern against every target, best first.

    Ties keep the original order, so an empty pattern returns the targets
    unchanged rather than in some arbitrary arrangement.

    Args:
        pattern: What the user typed.
        targets: The texts to match against.

    Returns:
        The matches, sorted by descending score.
    """
    var needle = pattern.graphemes()

    var hits = List[Match]()
    for i in range(len(targets)):
        var hit = _find(needle.copy(), targets[i])
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
