"""Configuration validation for CodeSight."""

import logging
from typing import Any, Dict

logger = logging.getLogger(__name__)


def validate_template(name: str, template: Dict[str, Any]) -> None:
    """Validate a template configuration.

    Args:
        name: Template name (e.g. 'python', 'javascript')
        template: Template configuration dictionary

    Raises:
        ValueError: If template configuration is invalid
    """
    # Check for valid keys in template
    valid_keys = {"exclude_extensions", "key_directories", "file_docs"}
    invalid_keys = set(template.keys()) - valid_keys
    if invalid_keys:
        raise ValueError(f"Invalid keys in template '{name}': {invalid_keys}")

    # Validate types
    if "exclude_extensions" in template:
        if not isinstance(template["exclude_extensions"], list):
            raise ValueError(f"Template '{name}': exclude_extensions must be a list")
        for ext in template["exclude_extensions"]:
            if not isinstance(ext, str) or not ext.startswith("."):
                raise ValueError(f"Template '{name}': Invalid extension format: {ext}")

    if "key_directories" in template:
        if not isinstance(template["key_directories"], list):
            raise ValueError(f"Template '{name}': key_directories must be a list")
        for dir_name in template["key_directories"]:
            if not isinstance(dir_name, str):
                raise ValueError(f"Template '{name}': Invalid directory name: {dir_name}")

    if "file_docs" in template:
        if not isinstance(template["file_docs"], dict):
            raise ValueError(f"Template '{name}': file_docs must be a dictionary")
        for file_path, doc in template["file_docs"].items():
            if not isinstance(file_path, str) or not isinstance(doc, str):
                raise ValueError(
                    f"Template '{name}': Invalid file documentation entry: {file_path}"
                )


def validate_config(config: Dict[str, Any]) -> None:
    """Validate configuration structure and values.

    Args:
        config: Configuration dictionary to validate

    Raises:
        ValueError: If configuration is invalid
    """
    # Check required keys
    required_keys = {
        "include_extensions",
        "exclude_files",
        "include_files",
        "truncate_py_literals",
    }
    missing_keys = required_keys - set(config.keys())
    if missing_keys:
        raise ValueError(f"Missing required configuration keys: {missing_keys}")

    # Validate types
    if not isinstance(config["include_extensions"], list):
        raise ValueError("'include_extensions' must be a list")
    if not isinstance(config["exclude_files"], list):
        raise ValueError("'exclude_files' must be a list")
    if not isinstance(config["include_files"], list):
        raise ValueError("'include_files' must be a list")
    if not isinstance(config["truncate_py_literals"], int):
        raise ValueError("'truncate_py_literals' must be an integer")

    # Validate extension format
    for ext in config["include_extensions"]:
        if not isinstance(ext, str) or not ext.startswith("."):
            raise ValueError(
                f"Invalid extension format: {ext}. Extensions must be strings starting with '.'"
            )

    # Validate templates if present
    if "templates" in config:
        if not isinstance(config["templates"], dict):
            raise ValueError("'templates' must be a dictionary")
        for template_name, template_config in config["templates"].items():
            logger.debug("Validating template: %s", template_name)
            validate_template(template_name, template_config)
