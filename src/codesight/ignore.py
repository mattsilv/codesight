"""Functions for handling file ignore patterns and gitignore parsing."""

import logging
from pathlib import Path
from typing import Any, Dict

import chardet
import pathspec

logger = logging.getLogger(__name__)


def parse_gitignore(root_folder: Path) -> pathspec.PathSpec:
    """Parse .gitignore patterns from the root folder using standard Git pattern matching."""
    gitignore_path = root_folder / ".gitignore"
    if not gitignore_path.exists():
        logger.debug("No .gitignore file found at %s", gitignore_path)
        return pathspec.PathSpec([])

    try:
        with open(gitignore_path, "r", encoding="utf-8") as f:
            patterns = [line.strip() for line in f if line.strip() and not line.startswith("#")]
    except UnicodeDecodeError:
        logger.warning("Failed to read .gitignore with UTF-8 encoding, attempting detection")
        with open(gitignore_path, "rb") as f:
            content = f.read()
            encoding = chardet.detect(content)["encoding"] or "utf-8"
        with open(gitignore_path, "r", encoding=encoding) as f:
            patterns = [line.strip() for line in f if line.strip() and not line.startswith("#")]
    except Exception as e:
        logger.error("Failed to read .gitignore: %s", e)
        return pathspec.PathSpec([])

    return pathspec.PathSpec.from_lines(pathspec.patterns.GitWildMatchPattern, patterns)


def should_ignore(
    path: Path, config: Dict[str, Any], gitignore_spec: pathspec.PathSpec | None = None
) -> bool:
    """Check if a file should be ignored based on gitignore patterns and configuration."""
    # First check if the file is explicitly included in config
    if str(path) in config.get("include_files", []):
        return False

    # Check if any parent folder starts with a dot (hidden folder)
    for part in path.parts:
        if part.startswith("."):
            # Check if any parent path is included
            for i in range(len(path.parts)):
                if str(Path(*path.parts[: i + 1])) in config.get("include_files", []):
                    return False
            # If not explicitly included, ignore hidden folders
            return True

    # Check gitignore patterns first using standard Git pattern matching
    if gitignore_spec and gitignore_spec.match_file(str(path)):
        return True

    # Check if file matches any exclude patterns from config
    if any(
        pathspec.patterns.GitWildMatchPattern(pattern).match_file(str(path))
        for pattern in config.get("exclude_files", [])
    ):
        return True

    # Check file extension
    if path.suffix and config.get("include_extensions"):
        return path.suffix not in config.get("include_extensions", [])

    return False
