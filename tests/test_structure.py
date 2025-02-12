"""Tests for the structure module."""

from pathlib import Path
from typing import Any

from pathspec import PathSpec
from pathspec.patterns.gitwildmatch import GitWildMatchPattern

from codesight.structure import generate_folder_structure, get_file_group, sort_files
from tests.constants import (
    BUILD_ARTIFACT_GROUP,
    CONFIG_GROUP,
    CORE_GROUP,
    DOCS_GROUP,
    ENTRY_POINT_GROUP,
    OTHER_GROUP,
    SOURCE_GROUP,
    TEST_GROUP,
)


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


def test_generate_folder_structure(tmp_path: Path) -> None:
    """Test folder structure generation."""
    create_test_files(tmp_path)

    config: dict[str, Any] = {
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
    assert "src/" in structure
    assert "tests/" in structure
    assert "docs/" in structure

    # Check file inclusions/exclusions
    assert "main.py" in structure
    assert "README.md" in structure
    assert ".gitignore" in structure


def test_get_file_group() -> None:
    """Test file grouping logic."""
    root = Path("/test")

    # Test project definition files (group CORE_GROUP)
    assert get_file_group(root / "README.md", root) == CORE_GROUP
    assert get_file_group(root / "pyproject.toml", root) == CORE_GROUP
    assert get_file_group(root / "LICENSE", root) == CORE_GROUP

    # Test config files (group CONFIG_GROUP)
    assert get_file_group(root / ".env", root) == CONFIG_GROUP
    assert get_file_group(root / "config.py", root) == CONFIG_GROUP

    # Test entry points (group ENTRY_POINT_GROUP)
    assert get_file_group(root / "src/main.py", root) == ENTRY_POINT_GROUP
    assert get_file_group(root / "__init__.py", root) == ENTRY_POINT_GROUP

    # Test core source code (group SOURCE_GROUP)
    assert get_file_group(root / "src/lib/utils.py", root) == SOURCE_GROUP
    assert get_file_group(root / "src/core/main.py", root) == SOURCE_GROUP

    # Test test files (group TEST_GROUP)
    assert get_file_group(root / "tests/test_main.py", root) == TEST_GROUP
    assert get_file_group(root / "src/test_utils.py", root) == TEST_GROUP

    # Test documentation (group DOCS_GROUP)
    assert get_file_group(root / "docs/guide.md", root) == DOCS_GROUP
    assert get_file_group(root / "examples/demo.py", root) == DOCS_GROUP

    # Test build outputs (group BUILD_ARTIFACT_GROUP)
    assert get_file_group(root / "dist/main.js", root) == BUILD_ARTIFACT_GROUP
    assert get_file_group(root / "build/lib.py", root) == BUILD_ARTIFACT_GROUP

    # Test other files (group OTHER_GROUP)
    assert get_file_group(root / "random.txt", root) == OTHER_GROUP


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

    config: dict[str, Any] = {
        "include_extensions": [".py"],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
    }

    gitignore_spec = PathSpec.from_lines(GitWildMatchPattern, [])
    structure = generate_folder_structure(tmp_path, gitignore_spec, config)

    # Empty directories should still be shown
    assert "empty/" in structure
    assert "src/" in structure


def test_folder_structure_with_many_files(tmp_path: Path) -> None:
    """Test folder structure generation with multiple files in directories."""
    # Create multiple files in a directory
    src_dir = tmp_path / "src"
    src_dir.mkdir()
    for i in range(5):
        (src_dir / f"file{i}.py").write_text(f"# File {i}")

    config: dict[str, Any] = {
        "include_extensions": [".py"],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
    }

    gitignore_spec = PathSpec.from_lines(GitWildMatchPattern, [])
    structure = generate_folder_structure(tmp_path, gitignore_spec, config)

    # Should show first file and indicate more
    assert "file0.py" in structure
    assert "..." in structure  # Indicates more files
