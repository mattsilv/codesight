"""Configuration management for CodeSight."""

import logging
from pathlib import Path
from typing import Any, TypedDict

import toml

logger = logging.getLogger(__name__)


class CodeSightConfig(TypedDict):
    """Type definition for CodeSight configuration."""

    include_extensions: list[str]  # File extensions to include
    include_files: list[str]  # Files to explicitly include
    truncate_py_literals: int  # Max elements in Python literals


DEFAULT_CONFIG: CodeSightConfig = {
    # Common development file types
    "include_extensions": [
        ".py",  # Python source
        ".js",  # JavaScript source
        ".ts",  # TypeScript source
        ".jsx",  # React components
        ".tsx",  # TypeScript React
        ".md",  # Documentation
        ".rst",  # Python docs
        ".yaml",  # Configuration
        ".yml",  # Configuration
        ".toml",  # Configuration
        ".json",  # Configuration/data
    ],
    # Important config files that might start with a dot
    "include_files": [
        ".pre-commit-config.yaml",
        ".flake8",
        ".eslintrc",
        ".prettierrc",
        "package.json",
        "pyproject.toml",
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
    ],
    # Default truncation for large data structures
    "truncate_py_literals": 5,
}


def merge_configs(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    """Merge two configurations, with override taking precedence."""
    result = base.copy()
    result.update(override)
    return result


def load_config(config_path: Path) -> dict[str, Any]:
    """Load configuration from a file."""
    if not config_path.exists():
        raise FileNotFoundError(f"Configuration file not found: {config_path}")

    if config_path.suffix == ".toml":
        return toml.load(config_path)
    raise ValueError(f"Unsupported config file format: {config_path.suffix}")
