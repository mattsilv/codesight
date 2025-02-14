"""Tests for configuration validation."""

from typing import Any

import pytest

from codesight.validate import validate_config, validate_template


def test_validate_template() -> None:
    """Test template validation with core cases."""
    # Valid template
    valid_template = {
        "exclude_extensions": [".pyc", ".pyo"],
        "key_directories": ["src", "tests"],
        "file_docs": {"README.md": "Documentation"},
    }
    validate_template("test", valid_template)

    # Invalid cases - one test per type of validation
    with pytest.raises(ValueError):
        validate_template("test", {"invalid_key": []})  # Invalid key

    with pytest.raises(ValueError):
        validate_template(
            "test",
            {  # Invalid value type
                "exclude_extensions": "not_a_list",
                "key_directories": ["src"],
                "file_docs": {},
            },
        )

    with pytest.raises(ValueError):
        validate_template(
            "test",
            {  # Invalid extension format
                "exclude_extensions": ["py"],  # Missing dot
                "key_directories": ["src"],
                "file_docs": {},
            },
        )


def test_validate_config() -> None:
    """Test configuration validation with core cases."""
    # Valid configuration
    valid_config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "exclude_files": ["*.pyc"],
        "include_files": ["README.md"],
        "exclude_patterns": [],
    }
    result = validate_config(valid_config)
    assert isinstance(result, dict)
    assert result["truncate_py_literals"] == 5  # Default value

    # Invalid cases - one test per type of validation
    with pytest.raises(ValueError):
        validate_config({"include_extensions": [".py"]})  # Missing required keys

    with pytest.raises(ValueError):
        validate_config(
            {  # Invalid value type
                "include_extensions": "not_a_list",
                "exclude_files": [],
                "include_files": [],
                "exclude_patterns": [],
            }
        )

    # Test special cases in one test
    special_config = {
        "include_extensions": [".py"],
        "exclude_files": ["*.pyc"],
        "include_files": ["README_中文.md"],  # Unicode path
        "exclude_patterns": ["**/temp/*"],  # Glob pattern
    }
    result = validate_config(special_config)
    assert isinstance(result, dict)
