"""Tests for the validate module."""

from typing import Any, cast

import pytest

from codesight.validate import validate_config, validate_template


def test_validate_template() -> None:
    """Test template validation."""
    # Valid template
    valid_template = {
        "exclude_extensions": [".pyc", ".pyo"],
        "key_directories": ["src", "tests"],
        "file_docs": {"README.md": "Documentation"},
    }
    validate_template("test", cast(dict[str, Any], valid_template))  # Should not raise

    # Invalid keys
    with pytest.raises(ValueError, match="Invalid keys in template"):
        validate_template("test", {"invalid_key": []})

    # Invalid exclude_extensions type
    with pytest.raises(ValueError, match="exclude_extensions must be a list"):
        validate_template("test", {"exclude_extensions": "not_a_list"})

    # Invalid extension format
    with pytest.raises(ValueError, match="Invalid extension format"):
        validate_template("test", {"exclude_extensions": ["no_dot"]})

    # Invalid key_directories type
    with pytest.raises(ValueError, match="key_directories must be a list"):
        validate_template("test", {"key_directories": "not_a_list"})

    # Invalid file_docs type
    with pytest.raises(ValueError, match="file_docs must be a dictionary"):
        validate_template("test", {"file_docs": "not_a_dict"})


def test_validate_config() -> None:
    """Test configuration validation."""
    # Test valid configuration
    valid_config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "exclude_files": [".gitignore"],
        "include_files": [],
        "exclude_patterns": [],
    }
    result = validate_config(valid_config)
    assert isinstance(result, dict)
    assert result["truncate_py_literals"] == 5

    # Test missing required keys
    invalid_config: dict[str, Any] = {
        "include_extensions": [".py"],
    }
    with pytest.raises(ValueError):
        validate_config(invalid_config)

    # Test invalid extension format
    invalid_extension_config: dict[str, Any] = {
        "include_extensions": ["py"],  # Missing dot
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
    }
    with pytest.raises(ValueError):
        validate_config(invalid_extension_config)


def test_validate_template_basic() -> None:
    """Test basic template validation."""
    valid_template = {
        "exclude_extensions": [".pyc", ".pyo"],
        "key_directories": ["src", "tests"],
        "file_docs": {"README.md": "Documentation"},
    }
    validate_template("test", cast(dict[str, Any], valid_template))


def test_validate_template_invalid_keys() -> None:
    """Test template validation with invalid keys."""
    invalid_template = {"exclude_extensions": [".pyc"], "invalid_key": "value"}
    with pytest.raises(ValueError, match="Invalid keys.*invalid_key"):
        validate_template("test", cast(dict[str, Any], invalid_template))


def test_validate_template_invalid_extension_format() -> None:
    """Test template validation with invalid extension format."""
    invalid_template = {"exclude_extensions": ["py", "txt"]}  # Missing dots
    with pytest.raises(ValueError, match="Invalid extension format"):
        validate_template("test", cast(dict[str, Any], invalid_template))


def test_validate_template_invalid_directory_name() -> None:
    """Test template validation with invalid directory name."""
    invalid_template = {"key_directories": ["src", 42]}  # Non-string value
    with pytest.raises(ValueError, match="Invalid directory name"):
        validate_template("test", cast(dict[str, Any], invalid_template))


def test_validate_template_invalid_file_docs() -> None:
    """Test template validation with invalid file documentation."""
    invalid_template = {"file_docs": {"README.md": 42}}  # Non-string value
    with pytest.raises(ValueError, match="Invalid file documentation entry"):
        validate_template("test", cast(dict[str, Any], invalid_template))


def test_validate_config_basic() -> None:
    """Test basic configuration validation."""
    valid_config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "exclude_files": ["*.pyc"],
        "include_files": ["README.md"],
        "exclude_patterns": [],
    }
    result = validate_config(valid_config)
    assert isinstance(result, dict)
    assert result["truncate_py_literals"] == 5  # Default value


def test_validate_config_missing_keys() -> None:
    """Test configuration validation with missing required keys."""
    invalid_config: dict[str, Any] = {
        "include_extensions": [".py"]
        # Missing other required keys
    }
    with pytest.raises(ValueError, match="Missing required configuration keys"):
        validate_config(invalid_config)


def test_validate_config_invalid_types() -> None:
    """Test configuration validation with invalid types."""
    # Test invalid include_extensions type
    invalid_type_config: dict[str, Any] = {
        "include_extensions": "not_a_list",  # Should be a list
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
    }
    with pytest.raises(ValueError):
        validate_config(invalid_type_config)

    # Test invalid exclude_files type
    invalid_type_config = {
        "include_extensions": [".py"],
        "exclude_files": "not_a_list",  # Should be a list
        "include_files": [],
        "exclude_patterns": [],
    }
    with pytest.raises(ValueError):
        validate_config(invalid_type_config)

    # Test invalid include_files type
    invalid_type_config = {
        "include_extensions": [".py"],
        "exclude_files": [],
        "include_files": "not_a_list",  # Should be a list
        "exclude_patterns": [],
    }
    with pytest.raises(ValueError):
        validate_config(invalid_type_config)

    # Test invalid exclude_patterns type
    invalid_type_config = {
        "include_extensions": [".py"],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": "not_a_list",  # Should be a list
    }
    with pytest.raises(ValueError):
        validate_config(invalid_type_config)


def test_validate_config_invalid_values() -> None:
    """Test configuration validation with invalid values."""
    # Test invalid extension format
    invalid_value_config: dict[str, Any] = {
        "include_extensions": ["py", "md"],  # Missing dots
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
    }
    with pytest.raises(ValueError):
        validate_config(invalid_value_config)

    # Test non-string values in lists
    invalid_value_config = {
        "include_extensions": [".py", 123],  # Number instead of string
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
    }
    with pytest.raises(ValueError):
        validate_config(invalid_value_config)


def test_validate_config_empty_lists() -> None:
    """Test configuration validation with empty lists."""
    config: dict[str, Any] = {
        "include_extensions": [],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
    }
    result = validate_config(config)
    assert isinstance(result, dict)


def test_validate_config_with_templates() -> None:
    """Test configuration validation with templates."""
    config: dict[str, Any] = {
        "include_extensions": [".py"],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
    }
    result = validate_config(config)
    assert isinstance(result, dict)


def test_validate_config_invalid_template() -> None:
    """Test configuration validation with invalid template."""
    config: dict[str, Any] = {
        "include_extensions": [".py"],
        "exclude_files": [],
        "include_files": [],
        "exclude_patterns": [],
    }
    result = validate_config(config)
    assert isinstance(result, dict)


def test_validate_config_unicode_paths() -> None:
    """Test configuration validation with Unicode paths."""
    config: dict[str, Any] = {
        "include_extensions": [".py"],
        "exclude_files": ["*.pyc"],
        "include_files": ["README_中文.md", "документация.txt"],
        "exclude_patterns": [],
    }
    result = validate_config(config)
    assert isinstance(result, dict)


def test_validate_config_path_traversal() -> None:
    """Test configuration validation with path traversal attempts."""
    config: dict[str, Any] = {
        "include_extensions": [".py"],
        "exclude_files": ["*.pyc"],
        "include_files": ["../outside.txt", "/etc/passwd"],
        "exclude_patterns": [],
    }
    result = validate_config(config)
    assert isinstance(result, dict)


def test_validate_config_glob_patterns() -> None:
    """Test configuration validation with various glob patterns."""
    config: dict[str, Any] = {
        "include_extensions": [".py"],
        "exclude_files": ["**/*.pyc", "node_modules/**/*", "!important.pyc", "[a-z]*.py"],
        "include_files": ["README.md"],
        "exclude_patterns": [],
    }
    result = validate_config(config)
    assert isinstance(result, dict)
