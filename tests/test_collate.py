"""Tests for the collate module."""

from pathlib import Path
from typing import Any

import pathspec
import pytest

from codesight.collate import (
    estimate_token_length,
    gather_and_collate,
    parse_gitignore,
    process_python_file,
    should_ignore,
    validate_config,
)

# Constants for test assertions
EXPECTED_FILE_COUNT = 2
EXPECTED_STATS_COUNT = 2
EXPECTED_ENCODING_FILE_COUNT = 2
EXPECTED_MULTIPLE_FILES_COUNT = 2


def create_test_file(tmp_path: Path, filename: str, content: str, encoding: str = "utf-8") -> Path:
    """Create test files with specific encodings."""
    file_path = tmp_path / filename
    with open(file_path, "w", encoding=encoding) as f:
        f.write(content)
    return file_path


def test_estimate_token_length() -> None:
    """Test token length estimation."""
    text = "Hello, world!"
    token_count = estimate_token_length(text)
    assert token_count is not None
    assert isinstance(token_count, int)
    assert token_count > 0

    # Test with different models
    assert estimate_token_length(text, model="gpt-4") is not None
    assert estimate_token_length(text, model="gpt-3.5-turbo") is not None

    # Test with invalid model
    assert estimate_token_length(text, model="invalid-model") is None


def test_validate_config() -> None:
    """Test configuration validation."""
    valid_config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "exclude_files": [".gitignore"],
        "include_files": ["README.md"],
        "truncate_py_literals": 5,
    }
    validate_config(valid_config)  # Should not raise

    # Test missing required keys
    invalid_config: dict[str, Any] = {"exclude_files": []}
    with pytest.raises(ValueError, match="Missing required configuration keys"):
        validate_config(invalid_config)

    # Test invalid types
    invalid_type_config = {
        "include_extensions": "not_a_list",  # Should be a list
        "exclude_files": [],
        "include_files": [],
        "truncate_py_literals": 5,
    }
    with pytest.raises(ValueError, match="include_extensions"):
        validate_config(invalid_type_config)


def test_gather_and_collate_basic(tmp_path: Path) -> None:
    """Test basic file gathering and collation."""
    # Create test files
    create_test_file(tmp_path, "test.py", "print('hello')")
    create_test_file(tmp_path, "README.md", "# Test")
    create_test_file(tmp_path, "ignore.pyc", "binary")

    config: dict[str, Any] = {
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
    assert len(file_stats) == EXPECTED_FILE_COUNT
    assert token_count is not None and token_count > 0


def test_gather_and_collate_with_structure(tmp_path: Path) -> None:
    """Test file gathering with folder structure generation."""
    # Create test directory structure
    (tmp_path / "src").mkdir()
    (tmp_path / "tests").mkdir()
    create_test_file(tmp_path / "src", "main.py", "def main(): pass")
    create_test_file(tmp_path / "tests", "test_main.py", "def test_main(): pass")

    config: dict[str, Any] = {
        "include_extensions": [".py"],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
        "truncate_py_literals": 5,
    }

    result, _, _ = gather_and_collate(tmp_path, config)

    # Check folder structure is included
    assert "# Project Structure" in result
    assert "📁 src/" in result
    assert "📁 tests/" in result
    assert "🐍 main.py" in result
    assert "🐍 test_main.py" in result


def test_gather_and_collate_with_file_encodings(tmp_path: Path) -> None:
    """Test handling of files with different encodings."""
    # Create files with different encodings
    create_test_file(tmp_path, "utf8.txt", "Hello, UTF-8!", "utf-8")
    create_test_file(tmp_path, "latin1.txt", "Hello, Latin-1!", "latin-1")

    config: dict[str, Any] = {
        "include_extensions": [".txt"],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
        "truncate_py_literals": 5,
    }

    result, _, file_stats = gather_and_collate(tmp_path, config)

    # Check both files were processed
    assert "utf8.txt" in result
    assert "Hello, UTF-8!" in result
    assert "latin1.txt" in result
    assert "Hello, Latin-1!" in result
    assert len(file_stats) == EXPECTED_ENCODING_FILE_COUNT


def test_gather_and_collate_with_gitignore(tmp_path: Path) -> None:
    """Test file gathering with gitignore patterns."""
    # Create .gitignore
    create_test_file(tmp_path, ".gitignore", "*.log\n/build/")

    # Create test files
    create_test_file(tmp_path, "app.py", "print('app')")
    create_test_file(tmp_path, "debug.log", "log content")
    (tmp_path / "build").mkdir()
    create_test_file(tmp_path / "build", "output.txt", "build output")

    config: dict[str, Any] = {
        "include_extensions": [".py", ".txt", ".log"],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
        "truncate_py_literals": 5,
    }

    result, _, _ = gather_and_collate(tmp_path, config)

    assert "app.py" in result
    assert "debug.log" not in result  # Should be ignored by gitignore
    assert "build/output.txt" not in result  # Should be ignored by gitignore


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

    config: dict[str, Any] = {
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
    invalid_config: dict[str, Any] = {"exclude_files": []}  # Missing other required keys

    try:
        gather_and_collate(test_dir, invalid_config)
        raise AssertionError("Should raise ValueError")
    except ValueError as e:
        assert "Missing required configuration keys" in str(e)


def test_should_ignore() -> None:
    """Test file ignore logic."""
    config: dict[str, Any] = {
        "exclude_files": ["secret.txt"],
        "include_extensions": [".py"],
        "include_files": ["README.md"],
    }
    gitignore_spec = pathspec.PathSpec([])

    assert should_ignore(Path("secret.txt"), config, gitignore_spec)
    assert should_ignore(Path("test.pyc"), config, gitignore_spec)
    assert not should_ignore(Path("test.py"), config, gitignore_spec)
    assert not should_ignore(Path("README.md"), config, gitignore_spec)


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


def test_gather_and_collate_empty_dir(tmp_path: Path) -> None:
    """Test gathering and collating from an empty directory."""
    config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "exclude_files": [],
        "include_files": [],
        "truncate_py_literals": 5,
    }
    gitignore_patterns = parse_gitignore(tmp_path)
    collated, token_count, file_stats = gather_and_collate(tmp_path, config, gitignore_patterns)
    assert collated
    assert token_count is not None
    assert isinstance(file_stats, dict)


def test_gather_and_collate_single_file(tmp_path: Path) -> None:
    """Test gathering and collating a single file."""
    config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "exclude_files": [],
        "include_files": [],
        "truncate_py_literals": 5,
    }
    create_test_file(tmp_path, "test.py", "print('hello')")
    gitignore_patterns = parse_gitignore(tmp_path)
    collated, token_count, file_stats = gather_and_collate(tmp_path, config, gitignore_patterns)
    assert "test.py" in collated
    assert token_count is not None
    assert len(file_stats) == 1


def test_gather_and_collate_multiple_files(tmp_path: Path) -> None:
    """Test gathering and collating multiple files."""
    config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "exclude_files": [],
        "include_files": [],
        "truncate_py_literals": 5,
    }
    create_test_file(tmp_path, "test1.py", "print('hello')")
    create_test_file(tmp_path, "test2.py", "print('world')")
    collated, token_count, file_stats = gather_and_collate(tmp_path, config)
    assert "test1.py" in collated
    assert "test2.py" in collated
    assert token_count is not None
    assert len(file_stats) == EXPECTED_MULTIPLE_FILES_COUNT


def test_gather_and_collate_nested_dirs(tmp_path: Path) -> None:
    """Test gathering and collating files from nested directories."""
    config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "exclude_files": [],
        "include_files": [],
        "truncate_py_literals": 5,
    }
    (tmp_path / "src").mkdir()
    create_test_file(tmp_path / "src", "main.py", "print('hello')")
    gitignore_patterns = parse_gitignore(tmp_path)
    collated, token_count, file_stats = gather_and_collate(tmp_path, config, gitignore_patterns)
    assert "src/main.py" in collated
    assert token_count is not None
    assert len(file_stats) == 1


def test_gather_and_collate_with_invalid_file(tmp_path: Path) -> None:
    """Test gathering and collating with an invalid file type."""
    config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "exclude_files": [],
        "include_files": [],
        "truncate_py_literals": 5,
    }
    create_test_file(tmp_path, "test.py", "print('hello')")
    create_test_file(tmp_path, "invalid.txt", "invalid")
    gitignore_patterns = parse_gitignore(tmp_path)
    collated, token_count, file_stats = gather_and_collate(tmp_path, config, gitignore_patterns)
    assert "test.py" in collated
    assert "invalid.txt" not in collated
    assert token_count is not None
    assert len(file_stats) == 1


def test_gather_and_collate_with_invalid_encoding(tmp_path: Path) -> None:
    """Test gathering and collating a file with non-UTF-8 encoding."""
    config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "exclude_files": [],
        "include_files": [],
        "truncate_py_literals": 5,
    }
    create_test_file(tmp_path, "test.py", "print('hello')", encoding="latin-1")
    gitignore_patterns = parse_gitignore(tmp_path)
    collated, token_count, file_stats = gather_and_collate(tmp_path, config, gitignore_patterns)
    assert "test.py" in collated
    assert token_count is not None
    assert len(file_stats) == 1
