"""Functions for handling project structure and file organization."""

import logging
from pathlib import Path
from typing import Any

import pathspec

from .ignore import should_ignore

logger = logging.getLogger(__name__)


def generate_folder_structure(
    root_folder: Path,
    gitignore_spec: pathspec.PathSpec,
    config: dict[str, Any],
) -> str:
    """Generate a tree-like folder structure of the project."""
    structure = ["# Project Structure\n```"]

    def should_include_path(path: Path) -> bool:
        """Check if path should be included in structure."""
        if not path.exists():
            return False
        # Skip .git directory and its contents
        if ".git" in path.parts:
            return False
        if path.name.startswith(".") and path.name != ".gitignore":  # Allow .gitignore
            return False
        relative_path = path.relative_to(root_folder)
        return not should_ignore(relative_path, config, gitignore_spec)

    def add_to_structure(path: Path, prefix: str = "") -> None:
        """Recursively add directories to structure."""
        # Skip hidden directories and .git
        if (
            path != root_folder
            and path.is_dir()
            and (path.name.startswith(".") or ".git" in path.parts)
        ):
            return

        # Always show directories (except hidden ones)
        if path != root_folder:
            if path.is_dir():
                structure.append(f"{prefix}📁 {path.name}/")
            elif path.is_file() and should_include_path(path):
                # Add file with appropriate emoji based on type
                if path.suffix in [".py", ".pyi"]:
                    icon = "🐍"  # Python files
                elif path.suffix in [".md", ".rst"]:
                    icon = "📝"  # Documentation
                elif path.suffix in [".toml", ".json", ".yaml", ".yml"]:
                    icon = "⚙️"  # Config files
                elif path.suffix in [".js", ".ts"]:
                    icon = "📜"  # JavaScript/TypeScript
                else:
                    icon = "📄"  # Other files
                structure.append(f"{prefix}  {icon} {path.name}")

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
            MAX_FILES_TO_SHOW = 4  # Show ... when we have 5 or more files

            for item in files[:MAX_FILES_TO_SHOW]:
                add_to_structure(item, prefix + "  ")

            if len(files) >= 5:
                structure.append(f"{prefix}  ... ({len(files) - MAX_FILES_TO_SHOW} more files)")

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

    # Core project files (group 1)
    core_files = {
        "README.md",
        "pyproject.toml",
        "LICENSE",
        "CHANGELOG.md",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
    }
    if file_path.name in core_files:
        return 1

    # Configuration and hidden files (group 2)
    is_hidden = file_path.name.startswith(".")
    is_config = file_path.name.endswith("config.py") or file_path.name.endswith(".ini")
    if is_hidden or is_config:
        return 2

    # Entry points (group 3)
    if file_path.name == "__init__.py":
        return 3
    if file_path.name == "main.py" and not any(part in ["core", "lib"] for part in path_parts):
        return 3

    # Core source code (group 4)
    if any(part in ["core", "lib", "src"] for part in path_parts):
        if not any(part.startswith("test") for part in path_parts):
            return 4

    # Tests (group 5)
    if "test" in file_path.name or "tests" in path_parts:
        return 5

    # Documentation and examples (group 6)
    if any(part in ["docs", "examples", "samples", "meta"] for part in path_parts):
        return 6

    # Build artifacts (group 7)
    if any(part in ["dist", "build", "target", "out", "bin"] for part in path_parts):
        return 7

    # Other files (group 8)
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
