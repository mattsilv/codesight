"""Functions for handling file ignore patterns."""

import logging
from pathlib import Path
from typing import Any

import pathspec

logger = logging.getLogger(__name__)


def parse_gitignore(root_folder: Path) -> pathspec.PathSpec:
    """Parse .gitignore file and return a PathSpec object.
    Uses exact same syntax and behavior as git for consistency.
    """
    gitignore_path = root_folder / ".gitignore"
    patterns = []

    if gitignore_path.exists():
        with open(gitignore_path) as f:
            patterns = [line.strip() for line in f if line.strip() and not line.startswith("#")]

    return pathspec.PathSpec.from_lines("gitwildmatch", patterns)


def should_ignore(path: Path, config: dict[str, Any], gitignore_spec: pathspec.PathSpec) -> bool:
    """Check if a file should be ignored. Simple order of operations:

    1. If file is in include_files list -> INCLUDE
    2. If file is ignored by .gitignore -> IGNORE
    3. If file extension is in include_extensions -> INCLUDE
    4. Otherwise -> IGNORE
    """
    str_path = str(path)

    # 1. Check explicit includes first (overrides everything)
    if str_path in config.get("include_files", []):
        return False

    # 2. Check gitignore patterns
    if gitignore_spec.match_file(str_path):
        return True

    # 3. Check file extension
    if path.suffix in config.get("include_extensions", []):
        return False

    # 4. Default to ignore
    return True
