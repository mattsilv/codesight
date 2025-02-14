"""Functions for file structure and organization."""

import logging
from pathlib import Path

import pathspec

from codesight.config import CodeSightConfig

from .ignore import should_ignore

logger = logging.getLogger(__name__)

# Maximum number of files to show per directory
MAX_FILES_IN_DIR = 10

# Core source code directories
CORE_DIRS = {"src", "lib", "core"}

# Test directories and indicators
TEST_INDICATORS = {"test", "tests", "test_"}

# Documentation directories
DOC_DIRS = {"docs", "doc", "documentation", "examples", "meta"}

# Build artifact directories
BUILD_DIRS = {"dist", "build", "target", "out"}

# Core project files
CORE_FILES = {
    "README.md",
    "README.rst",
    "pyproject.toml",
    "setup.py",
    "package.json",
    "LICENSE",
    "CHANGELOG.md",
}


def _is_core_file(file_name: str) -> bool:
    """Check if file is a core project file."""
    return file_name in CORE_FILES


def _is_config_file(file_name: str) -> bool:
    """Check if file is a config file."""
    return (
        file_name.startswith(".") or file_name.endswith("config.py") or file_name.endswith(".ini")
    )


def _is_entry_point(file_name: str, path_parts: list[str]) -> bool:
    """Check if file is an entry point."""
    return (
        file_name == "__init__.py"
        or file_name == "main.py"
        and not any(part in CORE_DIRS for part in path_parts)
    )


def _is_core_source(path_parts: list[str]) -> bool:
    """Check if file is in core source directories."""
    return any(part in CORE_DIRS for part in path_parts) and not any(
        part.startswith("test") for part in path_parts
    )


def _is_test_file(file_name: str, path_parts: list[str]) -> bool:
    """Check if file is a test file."""
    return any(ind in file_name or ind in path_parts for ind in TEST_INDICATORS)


def _is_documentation(path_parts: list[str]) -> bool:
    """Check if file is documentation."""
    return any(part in DOC_DIRS for part in path_parts)


def _is_build_artifact(path_parts: list[str]) -> bool:
    """Check if file is a build artifact."""
    return any(part in BUILD_DIRS for part in path_parts)


def generate_folder_structure(
    root_folder: Path,
    gitignore_spec: pathspec.PathSpec,
    config: CodeSightConfig,
) -> str:
    """Generate a tree-like folder structure of the project."""
    structure = ["```"]

    def should_include_path(path: Path) -> bool:
        """Check if path should be included in structure."""
        relative_path = path.relative_to(root_folder)
        return not should_ignore(relative_path, config, gitignore_spec)

    def add_to_structure(path: Path, prefix: str = "") -> None:
        """Recursively add directories to structure."""
        if path == root_folder:
            structure.append(path.name or str(path))
        else:
            structure.append(f"{prefix}└── {path.name}")

        if path.is_dir():
            # Sort directories first, then files
            items = sorted(path.iterdir(), key=lambda x: (not x.is_dir(), x.name.lower()))

            # Filter out hidden directories and .git
            items = [
                item
                for item in items
                if not (item.is_dir() and (item.name.startswith(".") or ".git" in item.parts))
            ]

            # Process directories
            dirs = [item for item in items if item.is_dir()]
            for item in dirs:
                add_to_structure(item, prefix + "  ")

            # Process files
            files = [item for item in items if item.is_file() and should_include_path(item)]

            for item in files[:MAX_FILES_IN_DIR]:
                add_to_structure(item, prefix + "  ")

            if len(files) >= MAX_FILES_IN_DIR + 1:
                structure.append(f"{prefix}  ... ({len(files) - MAX_FILES_IN_DIR} more files)")

    # Start from root
    add_to_structure(root_folder)
    structure.append("```\n")
    return "\n".join(structure)


def get_file_group(file_path: Path, root: Path) -> int:
    """Get the priority group number for a file.

    Files are grouped into categories for sorting, with lower numbers indicating higher priority:
    1. Core project files (README, pyproject.toml, LICENSE, etc.)
    2. Configuration and hidden files (.env, config.py, etc.)
    3. Entry points (__init__.py, main.py outside core)
    4. Core source code (src/, lib/, core/)
    5. Tests (test_*.py, tests/)
    6. Documentation and examples (docs/, examples/, meta/)
    7. Build artifacts (dist/, build/, target/)
    8. Other files

    Args:
        file_path: Path to the file
        root: Root directory of the project

    Returns:
        int: Group number from 1 (highest priority) to 8 (lowest priority)
    """
    relative_path = str(file_path.relative_to(root))
    path_parts = relative_path.split("/")

    # Check each group in priority order
    if _is_core_file(file_path.name):
        return 1
    if _is_config_file(file_path.name):
        return 2
    if _is_entry_point(file_name=file_path.name, path_parts=path_parts):
        return 3
    if _is_core_source(path_parts):
        return 4
    if _is_test_file(file_path.name, path_parts):
        return 5
    if _is_documentation(path_parts):
        return 6
    if _is_build_artifact(path_parts):
        return 7
    return 8


def sort_files(files: list[Path], root_folder: Path) -> list[Path]:
    """Sort files in a logical order for processing.

    Files are sorted by:
    1. Group number (from get_file_group)
    2. Directory depth (shallower files first)
    3. Path name alphabetically
    """
    return sorted(
        files,
        key=lambda f: (
            get_file_group(f, root_folder),
            len(str(f.relative_to(root_folder)).split("/")),
            str(f.relative_to(root_folder)),
        ),
    )
