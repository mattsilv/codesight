"""Tests for the transform module."""

from codesight.transform import process_python_file


def test_process_python_file() -> None:
    """Test Python file processing with truncation."""
    content = """
data = [1, 2, 3, 4, 5, 6, 7, 8]
small = [1, 2]
nested = {'a': [1, 2, 3, 4, 5, 6]}
"""
    processed, was_processed = process_python_file(content, 3)
    assert was_processed
    assert "[1, 2]" in processed  # Small list unchanged
    assert "data = [1, 2, 3]" in processed  # Large list truncated
    assert "'a': [1, 2, 3]" in processed  # Nested list truncated


def test_process_python_file_syntax_error() -> None:
    """Test handling of Python files with syntax errors."""
    content = "def invalid_python("  # Missing closing parenthesis
    processed, was_processed = process_python_file(content)
    assert not was_processed
    assert processed == content  # Original content returned unchanged
