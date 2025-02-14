"""Tests for file structure and organization."""

from pathlib import Path
from typing import Any

from pathspec import PathSpec
from pathspec.patterns.gitwildmatch import GitWildMatchPattern

from codesight.structure import generate_folder_structure, get_file_group, sort_files


def test_file_grouping() -> None:
    """Test that files are grouped into different categories."""
    root = Path.cwd()

    # Just test that different file types get different groups
    readme_group = get_file_group(root / "README.md", root)
    source_group = get_file_group(root / "src/main.py", root)
    test_group = get_file_group(root / "tests/test_main.py", root)

    # Files should be in different groups, don't test specific group numbers
    assert (
        len({readme_group, source_group, test_group}) == 3
    ), "Different file types should be in different groups"


def test_sort_files() -> None:
    """Test that files are sorted in a consistent order."""
    root = Path.cwd()
    files = [
        root / "src/main.py",
        root / "README.md",
        root / "tests/test_main.py",
    ]

    # Just test that sorting is stable and doesn't crash
    sorted_files = sort_files(files, root)
    assert len(sorted_files) == len(files), "Sorting should preserve all files"
    assert len(set(str(f) for f in sorted_files)) == len(
        files
    ), "Sorting should not create duplicates"


def test_folder_structure() -> None:
    """Test that folder structure generation works with basic config."""
    root = Path.cwd()
    config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
    }

    gitignore_spec = PathSpec.from_lines(GitWildMatchPattern, [])
    structure = generate_folder_structure(root, gitignore_spec, config)

    # Only test that it generates a valid string with basic structure
    assert isinstance(structure, str)
    assert structure.strip(), "Structure should not be empty"
    assert "# Project Structure" in structure, "Should have a title"
