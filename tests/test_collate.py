"""Tests for code collation."""

from pathlib import Path

from codesight.collate import estimate_token_length, gather_and_collate
from codesight.config import CodeSightConfig


def test_estimate_token_length() -> None:
    """Test token length estimation."""
    assert estimate_token_length("Hello world") is not None
    assert estimate_token_length("") == 0


def test_gather_and_collate(tmp_path: Path) -> None:
    """Test basic file gathering and collation."""
    # Create a test file
    test_file = tmp_path / "test.py"
    test_file.write_text('print("Hello world")')

    config = CodeSightConfig(
        include_extensions=[".py"],
        include_files=["README.md"],
        truncate_py_literals=5,
    )

    # Test basic collation
    content, tokens, stats = gather_and_collate(tmp_path, config)

    # Basic assertions
    assert isinstance(content, str)
    assert isinstance(tokens, (int, type(None)))
    assert isinstance(stats, dict)
    assert "test.py" in stats
