"""Tests for configuration validation."""

from typing import Any

import pytest

from codesight.validate import validate_config


def test_validate_config() -> None:
    """Test configuration validation with core cases."""
    # Valid configuration
    valid_config: dict[str, Any] = {
        "include_extensions": [".py", ".md"],
        "include_files": ["README.md"],
        "truncate_py_literals": 5,
    }
    result = validate_config(valid_config)
    assert isinstance(result, dict)
    assert ".py" in result["include_extensions"]
    assert "README.md" in result["include_files"]
    assert result["truncate_py_literals"] == 5

    # Invalid cases - one test per type of validation
    with pytest.raises(ValueError):
        validate_config({"include_extensions": "not_a_list"})

    with pytest.raises(ValueError):
        validate_config({"include_extensions": ["py"]})  # Missing dot

    with pytest.raises(ValueError):
        validate_config({"truncate_py_literals": -1})  # Negative value
