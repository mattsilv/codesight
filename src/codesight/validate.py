"""Configuration validation for CodeSight.

Example valid configuration:
```toml
# File extensions to include (must start with '.')
include_extensions = [".py", ".md", ".rst"]

# Files to exclude (supports glob patterns)
exclude_files = ["*.pyc", "node_modules/*"]

# Files to always include
include_files = ["README.md", "pyproject.toml"]

# Maximum elements in Python literals
truncate_py_literals = 5

# Project type templates
[templates.python]
exclude_extensions = [".pyc", ".pyo"]
key_directories = ["src", "tests"]
file_docs = { "pyproject.toml" = "Project configuration" }
```
"""

import logging
from typing import Any, Callable

logger = logging.getLogger(__name__)

REQUIRED_CONFIG_KEYS = {
    "include_extensions",
    "exclude_files",
    "include_files",
    "exclude_patterns",
}

# Default configuration values
DEFAULT_INCLUDE_EXTENSIONS: list[str] = [".py", ".md", ".rst"]
DEFAULT_EXCLUDE_FILES: list[str] = ["*.pyc", "node_modules/*"]
DEFAULT_INCLUDE_FILES: list[str] = ["README.md", "pyproject.toml"]
DEFAULT_EXCLUDE_PATTERNS: list[str] = []

# Default configuration
DEFAULT_CONFIG = {
    "truncate_py_literals": 5,
}


def validate_template(name: str, template: dict[str, Any]) -> None:
    """Validate a template configuration.

    Args:
        name: Template name (e.g. 'python', 'javascript')
        template: Template configuration dictionary

    Raises:
        ValueError: With detailed message if template configuration is invalid

    Example template:
        {
            "exclude_extensions": [".pyc", ".pyo"],
            "key_directories": ["src", "tests"],
            "file_docs": {"README.md": "Project documentation"}
        }
    """
    valid_keys = {"exclude_extensions", "key_directories", "file_docs"}
    invalid_keys = set(template.keys()) - valid_keys
    if invalid_keys:
        raise ValueError(
            f"Invalid keys in template '{name}': {invalid_keys}\n"
            f"Valid keys are: {', '.join(sorted(valid_keys))}"
        )

    if "exclude_extensions" in template:
        if not isinstance(template["exclude_extensions"], list):
            raise ValueError(
                f"Template '{name}': exclude_extensions must be a list\n"
                'Example: exclude_extensions = [".pyc", ".pyo"]'
            )
        for ext in template["exclude_extensions"]:
            if not isinstance(ext, str) or not ext.startswith("."):
                raise ValueError(
                    f"Template '{name}': Invalid extension format: {ext}\n"
                    "Extensions must be strings starting with '.', e.g. '.py'"
                )

    if "key_directories" in template:
        if not isinstance(template["key_directories"], list):
            raise ValueError(
                f"Template '{name}': key_directories must be a list\n"
                'Example: key_directories = ["src", "tests"]'
            )
        for dir_name in template["key_directories"]:
            if not isinstance(dir_name, str):
                raise ValueError(
                    f"Template '{name}': Invalid directory name: {dir_name}\n"
                    "Directory names must be strings"
                )

    if "file_docs" in template:
        if not isinstance(template["file_docs"], dict):
            raise ValueError(
                f"Template '{name}': file_docs must be a dictionary\n"
                'Example: file_docs = {"README.md": "Project documentation"}'
            )
        for file_path, doc in template["file_docs"].items():
            if not isinstance(file_path, str) or not isinstance(doc, str):
                raise ValueError(
                    f"Template '{name}': Invalid file documentation entry: {file_path}\n"
                    "Both file paths and descriptions must be strings"
                )


def _validate_list_field(
    config: dict[str, Any],
    field_name: str,
    example: str,
    item_validator: Callable[[Any], bool] | None = None,
) -> None:
    """Validate a list field in the configuration.

    Args:
        config: Configuration dictionary
        field_name: Name of the field to validate
        example: Example of valid configuration
        item_validator: Optional function to validate individual items
    """
    if not isinstance(config.get(field_name), list):
        raise ValueError(f"'{field_name}' must be a list\n" f"Example: {example}")

    if item_validator and field_name in config:
        for item in config[field_name]:
            if not item_validator(item):
                raise ValueError(f"Invalid item in {field_name}: {item}\n" f"Example: {example}")


def _validate_extension(ext: Any) -> bool:
    """Validate a file extension."""
    return isinstance(ext, str) and ext.startswith(".")


def _validate_required_keys(config: dict[str, Any]) -> None:
    """Validate that all required keys are present."""
    required_keys = {
        "include_extensions",
        "exclude_files",
        "include_files",
        "exclude_patterns",
    }
    missing_keys = required_keys - set(config.keys())
    if missing_keys:
        raise ValueError(
            f"Missing required configuration keys: {', '.join(sorted(missing_keys))}\n"
            "Required keys are:\n"
            '- include_extensions: List of file extensions (e.g. [".py", ".md"])\n'
            '- exclude_files: List of files to exclude (e.g. ["*.pyc"])\n'
            '- include_files: List of files to include (e.g. ["README.md"])\n'
            '- exclude_patterns: List of patterns to exclude (e.g. ["*.pyc"])'
        )


def _validate_truncate_py_literals(config: dict[str, Any]) -> None:
    """Validate truncate_py_literals field."""
    if not isinstance(config.get("truncate_py_literals"), int):
        raise ValueError(
            "'truncate_py_literals' must be an integer\n" "Example: truncate_py_literals = 5"
        )


def _validate_templates(config: dict[str, Any]) -> None:
    """Validate templates configuration if present."""
    if "templates" in config:
        if not isinstance(config["templates"], dict):
            raise ValueError(
                "'templates' must be a dictionary of project type templates\n"
                "Example: [templates.python]\n"
                'exclude_extensions = [".pyc"]\n'
                'key_directories = ["src", "tests"]'
            )
        for template_name, template_config in config["templates"].items():
            logger.debug("Validating template: %s", template_name)
            validate_template(template_name, template_config)


def validate_config(config: dict[str, Any]) -> dict[str, Any]:
    """Validate the configuration dictionary.

    Args:
        config: Configuration dictionary to validate

    Returns:
        Validated configuration dictionary

    Raises:
        ValueError: If configuration is invalid
    """
    # Check required keys
    _validate_required_keys(config)

    # Validate types and values
    for key in REQUIRED_CONFIG_KEYS:
        value = config.get(key, [])
        if not isinstance(value, list):
            raise ValueError(f"{key} must be a list")
        if not all(isinstance(item, str) for item in value):
            raise ValueError(f"All items in {key} must be strings")

    # Validate extension format
    for ext in config.get("include_extensions", []):
        if not isinstance(ext, str) or not ext.startswith("."):
            raise ValueError(f"Extension must be a string starting with dot: {ext}")

    # Merge with defaults
    result = DEFAULT_CONFIG.copy()
    result.update(config)
    return result
