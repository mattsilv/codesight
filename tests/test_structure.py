"""Tests for the structure module."""

from pathlib import Path
from typing import Any, Dict

import pytest
from pathspec import PathSpec
from pathspec.patterns.gitwildmatch import GitWildMatchPattern

from codesight.structure import generate_folder_structure, get_file_group, sort_files


def create_test_files(tmp_path: Path) -> None:
    """Create a test file structure."""
    # Create directories
    (tmp_path / "src").mkdir()
    (tmp_path / "src/lib").mkdir()
    (tmp_path / "tests").mkdir()
    (tmp_path / "docs").mkdir()
    (tmp_path / ".git").mkdir()

    # Create files
    (tmp_path / "README.md").write_text("# Test")
    (tmp_path / "pyproject.toml").write_text("[tool.poetry]")
    (tmp_path / "src/main.py").write_text("print('hello')")
    (tmp_path / "src/lib/utils.py").write_text("def util(): pass")
    (tmp_path / "tests/test_main.py").write_text("def test_main(): pass")
    (tmp_path / "docs/index.md").write_text("# Docs")
    (tmp_path / ".gitignore").write_text("*.pyc")


@pytest.mark.structure
def test_generate_folder_structure(tmp_path: Path) -> None:
    """Test folder structure generation."""
    create_test_files(tmp_path)

    config: Dict[str, Any] = {
        "include_extensions": [".py", ".md", ".toml"],
        "exclude_files": [],
        "include_files": [".gitignore"],
        "exclude_patterns": [],
    }

    gitignore_spec = PathSpec.from_lines(GitWildMatchPattern, [])
    structure = generate_folder_structure(tmp_path, gitignore_spec, config)

    # Check basic structure format
    assert "# Project Structure" in structure
    assert "```" in structure

    # Check directory indicators
    assert "📁 src/" in structure
    assert "📁 tests/" in structure
    assert "📁 docs/" in structure
    assert ".git" not in structure  # Hidden directories should be excluded

    # Check file emojis and ordering
    assert "🐍 main.py" in structure  # Python files
    assert "🐍 utils.py" in structure
    assert "🐍 test_main.py" in structure
    assert "⚙️ pyproject.toml" in structure  # Config files
    assert "📝 index.md" in structure  # Documentation


def test_get_file_group() -> None:
    """Test file grouping logic."""
    root = Path("/test")

    # Test project definition files (group 1)
    assert get_file_group(root / "README.md", root) == 1
    assert get_file_group(root / "pyproject.toml", root) == 1
    assert get_file_group(root / "LICENSE", root) == 1

    # Test config files (group 2)
    assert get_file_group(root / ".env", root) == 2
    assert get_file_group(root / "config.py", root) == 2

    # Test entry points (group 3)
    assert get_file_group(root / "src/main.py", root) == 3
    assert get_file_group(root / "__init__.py", root) == 3

    # Test core source code (group 4)
    assert get_file_group(root / "src/lib/utils.py", root) == 4
    assert get_file_group(root / "src/core/main.py", root) == 4

    # Test test files (group 5)
    assert get_file_group(root / "tests/test_main.py", root) == 5
    assert get_file_group(root / "src/test_utils.py", root) == 5

    # Test documentation (group 6)
    assert get_file_group(root / "docs/guide.md", root) == 6
    assert get_file_group(root / "examples/demo.py", root) == 6

    # Test build outputs (group 7)
    assert get_file_group(root / "dist/main.js", root) == 7
    assert get_file_group(root / "build/lib.py", root) == 7

    # Test other files (group 8)
    assert get_file_group(root / "random.txt", root) == 8


def test_sort_files(tmp_path: Path) -> None:
    """Test file sorting logic."""
    create_test_files(tmp_path)

    # Gather all files
    files = [f for f in tmp_path.rglob("*") if f.is_file()]
    sorted_files = sort_files(files, tmp_path)

    # Convert to relative paths for easier testing
    sorted_paths = [str(f.relative_to(tmp_path)) for f in sorted_files]

    # Check order of key files
    readme_idx = sorted_paths.index("README.md")
    main_idx = sorted_paths.index("src/main.py")
    utils_idx = sorted_paths.index("src/lib/utils.py")
    test_idx = sorted_paths.index("tests/test_main.py")

    # Project files first
    assert readme_idx < main_idx
    # Config before source
    assert sorted_paths.index("pyproject.toml") < utils_idx
    # Source before tests
    assert main_idx < test_idx


def test_folder_structure_with_empty_dirs(tmp_path: Path) -> None:
    """Test folder structure generation with empty directories."""
    # Create empty directories
    (tmp_path / "empty").mkdir()
    (tmp_path / "src").mkdir()
    (tmp_path / "src/empty").mkdir()

    config: Dict[str, Any] = {
        "include_extensions": [".py"],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
    }

    gitignore_spec = PathSpec.from_lines(GitWildMatchPattern, [])
    structure = generate_folder_structure(tmp_path, gitignore_spec, config)

    # Empty directories should still be shown
    assert "📁 empty/" in structure
    assert "📁 src/" in structure


def test_folder_structure_with_many_files(tmp_path: Path) -> None:
    """Test folder structure generation with multiple files in directories."""
    # Create multiple files in a directory
    src_dir = tmp_path / "src"
    src_dir.mkdir()
    for i in range(5):
        (src_dir / f"file{i}.py").write_text(f"# File {i}")

    config: Dict[str, Any] = {
        "include_extensions": [".py"],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
    }

    gitignore_spec = PathSpec.from_lines(GitWildMatchPattern, [])
    structure = generate_folder_structure(tmp_path, gitignore_spec, config)

    # Should show first file and indicate more
    assert "🐍 file0.py" in structure
    assert "..." in structure  # Indicates more files
