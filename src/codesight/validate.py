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
from typing import Any, Dict

logger = logging.getLogger(__name__)


def validate_template(name: str, template: Dict[str, Any]) -> None:
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


def validate_config(config: Dict[str, Any]) -> None:
    """Validate configuration structure and values.

    Args:
        config: Configuration dictionary to validate

    Raises:
        ValueError: With detailed message if configuration is invalid

    Required configuration keys:
        - include_extensions: List of file extensions to include (e.g. [".py", ".md"])
        - exclude_files: List of files or patterns to exclude (e.g. ["*.pyc"])
        - include_files: List of files to always include (e.g. ["README.md"])
        - truncate_py_literals: Integer for max elements in Python literals

    Optional configuration keys:
        - templates: Dictionary of project type templates
        - exclude_patterns: Additional glob patterns to exclude
        - key_directories: List of important directories to focus on
    """
    required_keys = {"include_extensions", "exclude_files", "include_files", "truncate_py_literals"}
    missing_keys = required_keys - set(config.keys())
    if missing_keys:
        raise ValueError(
            f"Missing required configuration keys: {', '.join(sorted(missing_keys))}\n"
            "Required keys are:\n"
            '- include_extensions: List of file extensions (e.g. [".py", ".md"])\n'
            '- exclude_files: List of files to exclude (e.g. ["*.pyc"])\n'
            '- include_files: List of files to include (e.g. ["README.md"])\n'
            "- truncate_py_literals: Max elements in Python literals (e.g. 5)"
        )

    if not isinstance(config.get("include_extensions"), list):
        raise ValueError(
            "'include_extensions' must be a list of file extensions\n"
            'Example: include_extensions = [".py", ".md", ".rst"]'
        )

    if not isinstance(config.get("exclude_files"), list):
        raise ValueError(
            "'exclude_files' must be a list of file patterns\n"
            'Example: exclude_files = ["*.pyc", "node_modules/*"]'
        )

    if not isinstance(config.get("include_files"), list):
        raise ValueError(
            "'include_files' must be a list of file paths\n"
            'Example: include_files = ["README.md", "pyproject.toml"]'
        )

    if not isinstance(config.get("truncate_py_literals"), int):
        raise ValueError(
            "'truncate_py_literals' must be an integer\n" "Example: truncate_py_literals = 5"
        )

    for ext in config.get("include_extensions", []):
        if not isinstance(ext, str) or not ext.startswith("."):
            raise ValueError(
                f"Invalid extension format: {ext}\n"
                "Extensions must be strings starting with '.', e.g. '.py'"
            )

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
