"""Configuration validation for CodeSight.

Example valid configuration:
```toml
# File extensions to include (must start with '.')
include_extensions = [".py", ".js", ".md"]

# Files to always include
include_files = ["README.md", ".pre-commit-config.yaml"]

# Maximum elements in Python literals
truncate_py_literals = 5
```
"""

import logging
from typing import Any, cast

from .config import DEFAULT_CONFIG, CodeSightConfig

logger = logging.getLogger(__name__)


def validate_config(config: dict[str, Any]) -> CodeSightConfig:
    """Validate the configuration dictionary.

    Args:
        config: Configuration dictionary to validate

    Returns:
        Validated configuration dictionary with defaults applied

    Raises:
        ValueError: If configuration is invalid
    """
    # Start with defaults
    result = dict(DEFAULT_CONFIG)

    # Validate and merge include_extensions
    extensions = config.get("include_extensions", result["include_extensions"])
    if not isinstance(extensions, list):
        raise ValueError("include_extensions must be a list")
    if not all(isinstance(ext, str) and ext.startswith(".") for ext in extensions):
        raise ValueError("All extensions must be strings starting with dot")

    # Validate and merge include_files
    files = config.get("include_files", result["include_files"])
    if not isinstance(files, list):
        raise ValueError("include_files must be a list")
    if not all(isinstance(f, str) for f in files):
        raise ValueError("All include_files must be strings")

    # Validate and merge truncate_py_literals
    truncate = config.get("truncate_py_literals", result["truncate_py_literals"])
    if not isinstance(truncate, int) or truncate < 0:
        raise ValueError("truncate_py_literals must be a non-negative integer")

    # Return validated config
    return CodeSightConfig(
        include_extensions=extensions,
        include_files=files,
        truncate_py_literals=truncate,
    )
