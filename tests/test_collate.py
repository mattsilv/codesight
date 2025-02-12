"""Tests for the collate module."""

from pathlib import Path

from codesight.collate import estimate_token_length, gather_and_collate
from codesight.transform import process_python_file
from tests.constants import DEFAULT_ENCODING


def create_test_file(
    tmp_path: Path, filename: str, content: str, encoding: str = DEFAULT_ENCODING
) -> Path:
    """Create a test file with the given content and encoding."""
    file_path = tmp_path / filename
    file_path.write_text(content, encoding=encoding)
    return file_path


def test_estimate_token_length() -> None:
    """Test token length estimation."""
    text = "Hello, world!"
    assert estimate_token_length(text) is not None
    assert estimate_token_length(text, model="invalid-model") is None


def test_gather_and_collate_basic(tmp_path: Path) -> None:
    """Test basic file gathering with different file types."""
    create_test_file(tmp_path, "test.py", "print('hello')")
    create_test_file(tmp_path, "README.md", "# Test")
    create_test_file(tmp_path, ".gitignore", "*.pyc")

    config = {
        "include_extensions": [".py", ".md"],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
    }

    result = gather_and_collate(tmp_path, config)
    assert result is not None
    content, _, stats = result

    assert "test.py" in content
    assert "README.md" in content
    assert ".gitignore" not in content
    assert len(stats) == 2


def test_process_python_file() -> None:
    """Test Python file processing."""
    content = "data = [1, 2, 3, 4, 5]"
    processed, was_processed = process_python_file(content, 3)
    assert was_processed
    assert "[1, 2, 3]" in processed
