"""Tests for the ignore module."""

from pathlib import Path
from typing import Any

from pathspec import PathSpec
from pathspec.patterns.gitwildmatch import GitWildMatchPattern

from codesight.ignore import parse_gitignore, should_ignore


def test_parse_gitignore(tmp_path: Path) -> None:
    """Test basic gitignore parsing."""
    gitignore = tmp_path / ".gitignore"
    gitignore.write_text("*.pyc\n/build/\n")

    spec = parse_gitignore(tmp_path)

    # Test basic patterns
    assert spec.match_file("test.pyc")  # Matches wildcard
    assert spec.match_file("build/output.txt")  # Matches directory
    assert not spec.match_file("test.py")  # Doesn't match other files

    # Test with no .gitignore
    empty_dir = tmp_path / "empty"
    empty_dir.mkdir()
    empty_spec = parse_gitignore(empty_dir)
    assert not empty_spec.match_file("test.pyc")  # No patterns means no ignores


def test_should_ignore() -> None:
    """Test file ignore logic with both gitignore and config patterns."""
    # Create a gitignore spec that ignores *.pyc files
    spec = PathSpec.from_lines(GitWildMatchPattern, ["*.pyc"])

    # Test core behavior: simple include/exclude logic
    config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "include_files": [".env", "special.txt"],  # Explicitly include these files
        "truncate_py_literals": 5,
    }

    # 1. Test gitignore patterns
    assert should_ignore(Path("test.pyc"), config, spec)  # Ignored by gitignore
    assert not should_ignore(Path("test.py"), config, spec)  # Not ignored (has allowed extension)

    # 2. Test extension-based ignoring
    assert not should_ignore(Path("main.py"), config, spec)  # .py is included
    assert should_ignore(Path("style.css"), config, spec)  # .css not in include_extensions

    # 3. Test explicit includes override everything
    assert not should_ignore(Path(".env"), config, spec)  # Explicitly included
    assert not should_ignore(
        Path("special.txt"), config, spec
    )  # Explicitly included despite extension
