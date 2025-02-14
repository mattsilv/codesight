"""Tests for the ignore module."""

from pathlib import Path

from pathspec import PathSpec
from pathspec.patterns.gitwildmatch import GitWildMatchPattern

from codesight.config import CodeSightConfig
from codesight.ignore import parse_gitignore, should_ignore


def test_parse_gitignore(tmp_path: Path) -> None:
    """Test basic gitignore parsing."""
    gitignore = tmp_path / ".gitignore"
    gitignore.write_text("*.pyc\n/build/\n")

    spec = parse_gitignore(tmp_path)
    assert spec.match_file("test.pyc")
    assert not spec.match_file("test.py")


def test_should_ignore() -> None:
    """Test file ignore logic with basic include/exclude patterns."""
    spec = PathSpec.from_lines(GitWildMatchPattern, ["*.pyc"])

    config = CodeSightConfig(
        include_extensions=[".py", ".md"],
        include_files=[".env", "special.txt"],
        truncate_py_literals=5,
    )

    # Test core behavior
    assert should_ignore(Path("test.pyc"), config, spec)  # Ignored by gitignore
    assert not should_ignore(Path("test.py"), config, spec)  # Not ignored (allowed extension)
    assert not should_ignore(Path(".env"), config, spec)  # Explicitly included
    assert should_ignore(Path("style.css"), config, spec)  # Not in include_extensions
