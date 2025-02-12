"""Configuration management for CodeSight."""

import logging
from pathlib import Path
from typing import Any, TypedDict

import toml

logger = logging.getLogger(__name__)


class CodeSightConfig(TypedDict):
    """Type definition for CodeSight configuration."""

    include_extensions: list[str]
    exclude_files: list[str]
    include_files: list[str]
    exclude_patterns: list[str]
    truncate_py_literals: int


DEFAULT_CONFIG: CodeSightConfig = {
    "include_extensions": [".py", ".md", ".rst", ".toml"],
    "exclude_files": [".gitignore", "*.pyc", "node_modules/*"],
    "include_files": ["README.md", "pyproject.toml"],
    "exclude_patterns": [],
    "truncate_py_literals": 5,
}

REQUIRED_CONFIG_KEYS = {
    "include_extensions",
    "exclude_files",
    "include_files",
    "exclude_patterns",
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
