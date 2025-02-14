"""Tests for file structure and organization."""

from pathlib import Path

from pathspec import PathSpec
from pathspec.patterns.gitwildmatch import GitWildMatchPattern

from codesight.config import CodeSightConfig
from codesight.structure import generate_folder_structure


def test_folder_structure() -> None:
    """Test that folder structure generation works."""
    # Create a simple test config
    config = CodeSightConfig(
        include_extensions=[".py"],
        include_files=["README.md"],
        truncate_py_literals=5,
    )

    # Create an empty gitignore spec
    gitignore_spec = PathSpec.from_lines(GitWildMatchPattern, [])

    # Generate structure
    structure = generate_folder_structure(Path.cwd(), gitignore_spec, config)

    # Test only essential requirements
    assert isinstance(structure, str)  # Returns a string
    assert structure.startswith("```")  # Has a code block
    assert structure.endswith("```\n")  # Ends properly
