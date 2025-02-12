"""Tests for the ignore module."""

from pathlib import Path
from typing import Any

import pathspec

from codesight.ignore import parse_gitignore, should_ignore


def test_parse_gitignore(tmp_path: Path) -> None:
    """Test parsing of .gitignore file."""
    gitignore = tmp_path / ".gitignore"
    gitignore.write_text(
        """
# Comment line
*.pyc
/build/
/meta/
node_modules/
*.log
!important.log
/dist/**/*.js
"""
    )

    spec = parse_gitignore(tmp_path)

    # Test file patterns
    assert spec.match_file("test.pyc")
    assert spec.match_file("subfolder/test.pyc")
    assert not spec.match_file("test.py")

    # Test directory patterns
    assert spec.match_file("build/output.txt")
    assert spec.match_file("meta/notes.md")
    assert not spec.match_file("src/meta/file.txt")  # /meta/ only matches at root

    # Test nested patterns
    assert spec.match_file("node_modules/package.json")
    assert spec.match_file("subfolder/node_modules/package.json")

    # Test negation
    assert spec.match_file("debug.log")
    assert not spec.match_file("important.log")

    # Test deep glob patterns
    assert spec.match_file("dist/bundle/main.js")
    assert not spec.match_file("src/main.js")

    # Test with no .gitignore
    empty_dir = tmp_path / "empty"
    empty_dir.mkdir()
    empty_spec = parse_gitignore(empty_dir)
    assert not empty_spec.match_file("any_file.txt")


def test_should_ignore() -> None:
    """Test file ignore logic with both gitignore and config patterns."""
    gitignore = """
/meta/
*.pyc
/dist/
"""
    spec = pathspec.PathSpec.from_lines(
        pathspec.patterns.GitWildMatchPattern, gitignore.splitlines()
    )

    config: dict[str, Any] = {
        "exclude_files": ["secrets.txt"],
        "include_extensions": [".py", ".md"],
        "include_files": ["meta/README.md", "dist/important.py"],
    }

    # Test gitignore patterns
    assert should_ignore(Path("meta/file.txt"), config, spec)
    assert should_ignore(Path("lib/test.pyc"), config, spec)
    assert should_ignore(Path("dist/bundle.js"), config, spec)

    # Test explicitly included files override gitignore
    assert not should_ignore(Path("meta/README.md"), config, spec)
    assert not should_ignore(Path("dist/important.py"), config, spec)

    # Test config patterns
    assert should_ignore(Path("secrets.txt"), config, spec)
    assert not should_ignore(Path("src/main.py"), config, spec)
    assert should_ignore(Path("src/styles.css"), config, spec)  # Not in include_extensions

    # Test hidden files/folders
    assert should_ignore(Path(".env"), config, spec)
    assert should_ignore(Path(".git/config"), config, spec)

    # Test included files in hidden folders
    config_with_git = {**config, "include_files": [".git/README.md"]}
    assert not should_ignore(Path(".git/README.md"), config_with_git, spec)
