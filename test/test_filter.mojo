from std.testing import TestSuite, assert_equal, assert_true, assert_false

from banjo.components.filter import find, rank


def _names() raises -> List[String]:
    return [
        String("Apple"),
        String("Blackberry"),
        String("Blueberry"),
        String("Cranberry"),
        String("Date"),
    ]


def test_subsequence_matches() raises:
    assert_true(find("bry", "Blackberry").__bool__())
    assert_true(find("apl", "Apple").__bool__())


def test_non_subsequence_does_not_match() raises:
    assert_false(find("zx", "Apple").__bool__())
    # Order matters: the characters are present but not in sequence.
    assert_false(find("lppa", "Apple").__bool__())


def test_matching_is_case_insensitive() raises:
    assert_true(find("APPLE", "apple").__bool__())
    assert_true(find("apple", "APPLE").__bool__())


def test_empty_pattern_matches_everything() raises:
    var hit = find("", "Apple")
    assert_true(hit.__bool__())
    assert_equal(hit.value().score, 0)
    assert_equal(len(hit.value().matched), 0)


def test_matched_positions_are_reported() raises:
    var hit = find("ale", "Apple")
    assert_true(hit.__bool__())
    # A, then l, then e.
    assert_equal(len(hit.value().matched), 3)
    assert_equal(hit.value().matched[0], 0)


def test_adjacent_matches_score_higher() raises:
    var tight = find("app", "Apple")
    var loose = find("ape", "Apple")
    assert_true(tight.value().score > loose.value().score)


def test_earlier_matches_score_higher() raises:
    var early = find("a", "Apple")
    var late = find("a", "Bananarama")
    assert_true(early.value().score > late.value().score)


def test_rank_returns_only_matches() raises:
    var hits = rank("berry", _names())
    assert_equal(len(hits), 3)
    for ref hit in hits:
        assert_true("berry" in _names()[hit.index])


def test_rank_is_sorted_by_score() raises:
    var hits = rank("berry", _names())
    for i in range(1, len(hits)):
        assert_true(hits[i - 1].score >= hits[i].score)


def test_rank_with_empty_pattern_keeps_order() raises:
    var hits = rank("", _names())
    assert_equal(len(hits), 5)
    for i in range(len(hits)):
        assert_equal(hits[i].index, i)


def test_rank_with_no_matches_is_empty() raises:
    assert_equal(len(rank("zzz", _names())), 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
