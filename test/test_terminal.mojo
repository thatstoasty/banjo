from std.testing import TestSuite, assert_equal


def test_dummy() raises:
    """A placeholder so this suite has something to run."""
    assert_equal(1, 1)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
