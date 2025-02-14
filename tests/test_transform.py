"""Tests for code transformation."""

from codesight.transform import process_python_file


def test_process_python_file() -> None:
    """Test Python file processing with basic cases."""
    # Test basic truncation
    code = """
x = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
y = {"a": 1, "b": 2, "c": 3, "d": 4, "e": 5, "f": 6}
"""
    result, was_processed = process_python_file(code, truncate_size=3)
    assert was_processed  # File was processed successfully
    assert "[1, 2, 3]" in result
    assert "{'a': 1, 'b': 2, 'c': 3}" in result

    # Test code without literals is processed but unchanged (ignoring quote style)
    code = """
def hello():
    print('Hello, world!')
"""
    result, was_processed = process_python_file(code, truncate_size=3)
    assert was_processed  # File was processed successfully
    assert result.strip() == code.strip()  # Content is unchanged
