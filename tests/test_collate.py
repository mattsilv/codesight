"""Tests for the collate module."""

from pathlib import Path
from typing import Any, Dict

from codesight.collate import (
    gather_and_collate,
    parse_gitignore,
    process_python_file,
    should_ignore,
)


def create_test_file(tmp_path: Path, filename: str, content: str, encoding: str = "utf-8") -> Path:
    """Create test files with specific encodings."""
    file_path = tmp_path / filename
    with open(file_path, "w", encoding=encoding) as f:
        f.write(content)
    return file_path


def test_parse_gitignore(tmp_path: Path) -> None:
    """Test parsing of .gitignore file."""
    gitignore = tmp_path / ".gitignore"
    gitignore.write_text(
        """
# Comment line
*.pyc
/build/
"""
    )

    spec = parse_gitignore(tmp_path)
    assert spec.match_file("test.pyc")
    assert spec.match_file("build/output.txt")
    assert not spec.match_file("src/file.py")

    # Test with no .gitignore
    empty_dir = tmp_path / "empty"
    empty_dir.mkdir()
    empty_spec = parse_gitignore(empty_dir)
    assert not empty_spec.match_file("any_file.txt")


def test_file_encodings(tmp_path: Path) -> None:
    """Test handling of files with different encodings."""
    # Create files with different encodings
    create_test_file(tmp_path, "utf8.txt", "Hello, UTF-8!", "utf-8")
    create_test_file(tmp_path, "latin1.txt", "Hello, Latin-1!", "latin-1")

    config: Dict[str, Any] = {
        "include_extensions": [".txt"],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
        "truncate_py_literals": 5,
    }

    # Test gathering files
    result, _, _ = gather_and_collate(tmp_path, config)

    # Check both files were processed
    assert "utf8.txt" in result
    assert "Hello, UTF-8!" in result
    assert "latin1.txt" in result
    assert "Hello, Latin-1!" in result


def test_malformed_config(tmp_path: Path) -> None:
    """Test handling of malformed configuration."""
    # Create a test directory
    test_dir = tmp_path / "test_dir"
    test_dir.mkdir()

    # Test with missing required keys
    invalid_config: Dict[str, Any] = {"exclude_files": []}  # Missing other required keys

    try:
        gather_and_collate(test_dir, invalid_config)
        assert False, "Should raise ValueError"
    except ValueError as e:
        assert "Missing required configuration keys" in str(e)


def test_should_ignore() -> None:
    """Test file ignore logic."""
    config: Dict[str, Any] = {
        "exclude_files": ["secret.txt"],
        "include_extensions": [".py"],
        "include_files": ["README.md"],
    }

    assert should_ignore(Path("secret.txt"), config)
    assert should_ignore(Path("test.pyc"), config)
    assert not should_ignore(Path("test.py"), config)
    assert not should_ignore(Path("README.md"), config)


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


def test_gather_and_collate(tmp_path: Path) -> None:
    """Test full file gathering and collation."""
    # Create test files
    (tmp_path / "test.py").write_text("print('hello')")
    (tmp_path / "README.md").write_text("# Test")
    (tmp_path / "ignore.pyc").write_text("binary")

    config: Dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "exclude_files": ["*.pyc"],
        "include_files": [],
        "exclude_patterns": [],
        "truncate_py_literals": 5,
    }

    result, token_count, file_stats = gather_and_collate(tmp_path, config)

    assert "test.py" in result
    assert "README.md" in result
    assert "print('hello')" in result
    assert "# Test" in result
    assert "ignore.pyc" not in result
    assert len(file_stats) == 2
