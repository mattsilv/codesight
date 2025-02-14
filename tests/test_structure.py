"""Tests for file structure and organization."""

from pathlib import Path
from typing import Any

from pathspec import PathSpec
from pathspec.patterns.gitwildmatch import GitWildMatchPattern

from codesight.structure import generate_folder_structure


def test_folder_structure() -> None:
    """Test that folder structure generation works with basic config."""
    root = Path.cwd()
    config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "include_files": ["README.md"],
        "truncate_py_literals": 5,
    }

    gitignore_spec = PathSpec.from_lines(GitWildMatchPattern, [])
    structure = generate_folder_structure(root, gitignore_spec, config)

    # Test basic structure requirements
    assert isinstance(structure, str)
    assert structure.strip()  # Not empty
    assert "# Project Structure" in structure
    assert "```" in structure  # Has code block
    assert "src/" in structure or "tests/" in structure  # Has some directories
