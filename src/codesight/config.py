"""Configuration management for CodeSight."""

import logging
from pathlib import Path
from typing import Any, Dict, Optional, TypedDict, cast

import toml

from .validate import validate_config

logger = logging.getLogger(__name__)


class TemplateConfig(TypedDict, total=False):
    """Type definition for template configuration."""

    exclude_extensions: list[str]
    key_directories: list[str]
    file_docs: dict[str, str]


class CodeSightConfig(TypedDict):
    """Type definition for CodeSight configuration."""

    include_extensions: list[str]
    exclude_files: list[str]
    include_files: list[str]
    truncate_py_literals: int
    exclude_patterns: list[str]
    key_directories: list[str]
    file_docs: dict[str, str]
    templates: dict[str, TemplateConfig]


DEFAULT_CONFIG: CodeSightConfig = {
    "include_extensions": [".py", ".md", ".rst", ".sql", ".toml"],
    "exclude_files": [".gitignore"],  # Always exclude .gitignore from final output
    "include_files": [
        "pyproject.toml",
        "README.md",
        ".github",
        ".flake8",
    ],  # Include README.md by default
    "exclude_patterns": [],
    "truncate_py_literals": 5,
    "key_directories": [],  # Directories to focus on, empty means scan everything
    "file_docs": {},  # Documentation for specific files, format: {"path": "doc"}
    "templates": {
        "python": {
            "exclude_extensions": [".csv", ".pkl", ".db"],
            "key_directories": ["src", "tests"],
            "file_docs": {
                "pyproject.toml": "Project configuration and dependencies",
                "README.md": "Project documentation and usage guide",
            },
        },
        "javascript": {
            "exclude_extensions": [".map", ".lock"],
            "key_directories": ["src", "test"],
            "file_docs": {
                "package.json": "Project configuration and dependencies",
                "README.md": "Project documentation and usage guide",
            },
        },
    },
}

REQUIRED_CONFIG_KEYS = {
    "include_extensions",
    "exclude_files",
    "include_files",
    "truncate_py_literals",
}


def parse_user_config(config_path: str) -> Dict[str, Any]:
    """Parse user configuration file."""
    path = Path(config_path)
    if not path.exists():
        raise FileNotFoundError(f"Configuration file not found: {path}")

    if path.suffix == ".toml":
        try:
            config = toml.load(path)
            logger.debug("Successfully loaded configuration from %s", path)
            return config
        except Exception as e:
            raise ValueError(f"Failed to parse TOML configuration: {e}")
    raise ValueError(f"Unsupported config file format: {path.suffix}")


def merge_configs(base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
    """Merge override config into base config."""
    for key, value in override.items():
        if isinstance(value, dict) and key in base and isinstance(base[key], dict):
            merge_configs(base[key], value)
        else:
            base[key] = value
    return base


def load_config(
    project_type: Optional[str] = None,
    user_config: Optional[dict[str, Any]] = None,
) -> CodeSightConfig:
    """Load configuration, merging defaults with user config.

    Args:
        project_type: Optional project type to load template for
        user_config: Optional user configuration dictionary

    Returns:
        Merged configuration dictionary
    """
    # Start with a copy of the default config
    config = cast(dict[str, Any], DEFAULT_CONFIG.copy())

    # Apply project type template if specified
    if project_type and project_type in config["templates"]:
        template = config["templates"][project_type]
        config = merge_configs(config, cast(dict[str, Any], template))

    # Apply user config if provided
    if user_config:
        config = merge_configs(config, user_config)

    # Validate final config
    validate_config(config)
    return cast(CodeSightConfig, config)


def auto_detect_project_type(root_folder: Path) -> str:
    """Detect Python vs. JavaScript or default to unopinionated if ambiguous."""
    if (root_folder / "pyproject.toml").exists():
        return "python"
    elif (root_folder / "package.json").exists():
        return "javascript"
    return "unopinionated"
