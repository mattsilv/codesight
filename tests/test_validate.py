"""Tests for the validate module."""

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
    validate_template("test", valid_template)  # Should not raise

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
    # Valid config
    valid_config = {
        "include_extensions": [".py", ".md"],
        "exclude_files": [".gitignore"],
        "include_files": ["README.md"],
        "truncate_py_literals": 5,
    }
    validate_config(valid_config)  # Should not raise

    # Missing required keys
    with pytest.raises(ValueError, match="Missing required configuration keys"):
        validate_config({"include_extensions": []})

    # Invalid types
    with pytest.raises(ValueError, match="must be a list"):
        validate_config(
            {
                "include_extensions": "not_a_list",
                "exclude_files": [],
                "include_files": [],
                "truncate_py_literals": 5,
            }
        )

    # Invalid extension format
    with pytest.raises(ValueError, match="Invalid extension format"):
        validate_config(
            {
                "include_extensions": ["no_dot"],
                "exclude_files": [],
                "include_files": [],
                "truncate_py_literals": 5,
            }
        )

    # Invalid templates type
    with pytest.raises(ValueError, match="'templates' must be a dictionary"):
        validate_config(
            {
                "include_extensions": [".py"],
                "exclude_files": [],
                "include_files": [],
                "truncate_py_literals": 5,
                "templates": "not_a_dict",
            }
        )
