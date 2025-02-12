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


def test_validate_template_basic() -> None:
    """Test basic template validation."""
    valid_template = {
        "exclude_extensions": [".pyc", ".pyo"],
        "key_directories": ["src", "tests"],
        "file_docs": {"README.md": "Documentation"},
    }
    validate_template("test", valid_template)


def test_validate_template_invalid_keys() -> None:
    """Test template validation with invalid keys."""
    invalid_template = {"exclude_extensions": [".pyc"], "invalid_key": "value"}
    with pytest.raises(ValueError, match="Invalid keys.*invalid_key"):
        validate_template("test", invalid_template)


def test_validate_template_invalid_extension_format() -> None:
    """Test template validation with invalid extension format."""
    invalid_template = {"exclude_extensions": ["py", "txt"]}  # Missing dots
    with pytest.raises(ValueError, match="Invalid extension format"):
        validate_template("test", invalid_template)


def test_validate_template_invalid_directory_name() -> None:
    """Test template validation with invalid directory name."""
    invalid_template = {"key_directories": ["src", 42]}  # Non-string value
    with pytest.raises(ValueError, match="Invalid directory name"):
        validate_template("test", invalid_template)


def test_validate_template_invalid_file_docs() -> None:
    """Test template validation with invalid file documentation."""
    invalid_template = {"file_docs": {"README.md": 42}}  # Non-string value
    with pytest.raises(ValueError, match="Invalid file documentation entry"):
        validate_template("test", invalid_template)


def test_validate_config_basic() -> None:
    """Test basic configuration validation."""
    valid_config = {
        "include_extensions": [".py", ".md"],
        "exclude_files": ["*.pyc"],
        "include_files": ["README.md"],
        "truncate_py_literals": 5,
    }
    validate_config(valid_config)


def test_validate_config_missing_keys() -> None:
    """Test configuration validation with missing required keys."""
    invalid_config = {
        "include_extensions": [".py"]
        # Missing other required keys
    }
    with pytest.raises(ValueError, match="Missing required configuration keys"):
        validate_config(invalid_config)


def test_validate_config_invalid_types() -> None:
    """Test configuration validation with invalid types."""
    configs_with_invalid_types = [
        {
            "include_extensions": ".py",  # Should be list
            "exclude_files": [],
            "include_files": [],
            "truncate_py_literals": 5,
        },
        {
            "include_extensions": [],
            "exclude_files": "test",  # Should be list
            "include_files": [],
            "truncate_py_literals": 5,
        },
        {
            "include_extensions": [],
            "exclude_files": [],
            "include_files": "test",  # Should be list
            "truncate_py_literals": 5,
        },
        {
            "include_extensions": [],
            "exclude_files": [],
            "include_files": [],
            "truncate_py_literals": "5",
        },  # Should be int
    ]
    for config in configs_with_invalid_types:
        with pytest.raises(ValueError):
            validate_config(config)


def test_validate_config_invalid_extension_format() -> None:
    """Test configuration validation with invalid extension format."""
    invalid_config = {
        "include_extensions": ["py", "md"],  # Missing dots
        "exclude_files": [],
        "include_files": [],
        "truncate_py_literals": 5,
    }
    with pytest.raises(ValueError, match="Invalid extension format"):
        validate_config(invalid_config)


def test_validate_config_empty_lists() -> None:
    """Test configuration validation with empty lists."""
    config = {
        "include_extensions": [],
        "exclude_files": [],
        "include_files": [],
        "truncate_py_literals": 5,
    }
    validate_config(config)  # Should not raise


def test_validate_config_with_templates() -> None:
    """Test configuration validation with templates."""
    config = {
        "include_extensions": [".py"],
        "exclude_files": [],
        "include_files": [],
        "truncate_py_literals": 5,
        "templates": {"python": {"exclude_extensions": [".pyc"], "key_directories": ["src"]}},
    }
    validate_config(config)


def test_validate_config_invalid_template() -> None:
    """Test configuration validation with invalid template."""
    config = {
        "include_extensions": [".py"],
        "exclude_files": [],
        "include_files": [],
        "truncate_py_literals": 5,
        "templates": {"python": {"invalid_key": "value"}},
    }
    with pytest.raises(ValueError, match="Invalid keys"):
        validate_config(config)


def test_validate_config_unicode_paths() -> None:
    """Test configuration validation with Unicode paths."""
    config = {
        "include_extensions": [".py"],
        "exclude_files": ["*.pyc"],
        "include_files": ["README_中文.md", "документация.txt"],
        "truncate_py_literals": 5,
    }
    validate_config(config)  # Should not raise


def test_validate_config_path_traversal() -> None:
    """Test configuration validation with path traversal attempts."""
    config = {
        "include_extensions": [".py"],
        "exclude_files": ["*.pyc"],
        "include_files": ["../outside.txt", "/etc/passwd"],
        "truncate_py_literals": 5,
    }
    validate_config(config)  # Should validate (actual path checking is done elsewhere)


def test_validate_config_glob_patterns() -> None:
    """Test configuration validation with various glob patterns."""
    config = {
        "include_extensions": [".py"],
        "exclude_files": ["**/*.pyc", "node_modules/**/*", "!important.pyc", "[a-z]*.py"],
        "include_files": ["README.md"],
        "truncate_py_literals": 5,
    }
    validate_config(config)  # Should not raise
