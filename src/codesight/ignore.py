"""Functions for handling file ignore patterns."""

import logging
from pathlib import Path
from typing import Any

import pathspec

logger = logging.getLogger(__name__)


def parse_gitignore(root_folder: Path) -> pathspec.PathSpec:
    """Parse .gitignore file and return a PathSpec object."""
    gitignore_path = root_folder / ".gitignore"
    patterns = []

    if gitignore_path.exists():
        with open(gitignore_path) as f:
            patterns = [line.strip() for line in f if line.strip() and not line.startswith("#")]

    # Add common patterns if not already present
    common_patterns = [
        ".git/",
        "__pycache__/",
        "*.pyc",
        "*.pyo",
        "*.pyd",
        "*.so",
        ".pytest_cache/",
        ".coverage",
        ".venv/",
        ".env/",
        "venv/",
        "env/",
        "dist/",
        "build/",
        "*.egg-info/",
        ".tox/",
        ".mypy_cache/",
        ".ruff_cache/",
        "node_modules/",
    ]
    for pattern in common_patterns:
        if pattern not in patterns:
            patterns.append(pattern)

    return pathspec.PathSpec.from_lines("gitwildmatch", patterns)


def should_ignore(path: Path, config: dict[str, Any], gitignore_spec: pathspec.PathSpec) -> bool:
    """Check if a file should be ignored based on configuration and gitignore patterns."""
    str_path = str(path)

    # Always include certain files
    if str_path in config.get("include_files", []):
        return False

    # Check exclude patterns first
    if any(pattern in str_path for pattern in config.get("exclude_files", [])):
        return True

    # Check gitignore patterns
    if gitignore_spec.match_file(str_path):
        return True

    # Check key directories if specified
    key_dirs = config.get("key_directories", [])
    if key_dirs and not any(dir_name in str_path.split("/") for dir_name in key_dirs):
        return True

    # Only include files with specified extensions
    if path.suffix not in config.get("include_extensions", []):
        return True

    return False
