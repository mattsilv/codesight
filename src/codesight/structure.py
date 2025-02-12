"""Functions for handling project structure and file organization."""

import logging
from pathlib import Path
from typing import Any, Dict, List, Set

import pathspec

from .ignore import should_ignore

logger = logging.getLogger(__name__)


def generate_folder_structure(
    root_folder: Path,
    gitignore_spec: pathspec.PathSpec,
    config: Dict[str, Any],
) -> str:
    """Generate a tree-like folder structure of the project."""
    structure = ["# Project Structure\n```"]
    seen_dirs: Set[str] = set()

    def should_include_path(path: Path) -> bool:
        """Check if path should be included in structure."""
        if not path.exists():
            return False
        if path.name.startswith("."):  # Exclude hidden files/directories
            return False
        relative_path = path.relative_to(root_folder)
        if should_ignore(relative_path, config, gitignore_spec):
            return False
        return True

    def add_to_structure(path: Path, prefix: str = "") -> None:
        """Recursively add directories to structure."""
        if not should_include_path(path):
            return

        relative_path = str(path.relative_to(root_folder))
        if relative_path in seen_dirs:
            return
        seen_dirs.add(relative_path)

        if path.is_dir():
            # Skip if it's just a root directory
            if path != root_folder:
                structure.append(f"{prefix}📁 {path.name}/")

            # Sort directories first, then files
            items = sorted(path.iterdir(), key=lambda x: (not x.is_dir(), x.name.lower()))

            # Process directories first
            dirs = [item for item in items if item.is_dir() and should_include_path(item)]
            for item in dirs:
                add_to_structure(item, prefix + "  ")

            # Then show one example file and indicate if there are more
            files = [item for item in items if item.is_file() and should_include_path(item)]
            if files:
                example_file = files[0]
                # Add file with appropriate emoji based on type
                if example_file.suffix in [".py", ".pyi"]:
                    icon = "🐍"  # Python files
                elif example_file.suffix in [".md", ".rst"]:
                    icon = "📝"  # Documentation
                elif example_file.suffix in [".toml", ".json", ".yaml", ".yml"]:
                    icon = "⚙️"  # Config files
                elif example_file.suffix in [".js", ".ts"]:
                    icon = "📜"  # JavaScript/TypeScript
                else:
                    icon = "📄"  # Other files
                structure.append(f"{prefix}  {icon} {example_file.name}")
                if len(files) > 1:
                    structure.append(f"{prefix}  ...")

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


def sort_files(files: List[Path], root_folder: Path) -> List[Path]:
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
