"""Tests for the config module."""
from pathlib import Path
from codesight.config import auto_detect_project_type, merge_configs

def test_auto_detect_project_type(tmp_path):
    """Test project type detection."""
    # Create test files
    (tmp_path / "pyproject.toml").touch()
    
    # Test Python detection
    assert auto_detect_project_type(tmp_path) == "python"
    
    # Remove Python file and add JavaScript file
    (tmp_path / "pyproject.toml").unlink()
    (tmp_path / "package.json").touch()
    
    # Test JavaScript detection
    assert auto_detect_project_type(tmp_path) == "javascript"
    
    # Remove all files
    (tmp_path / "package.json").unlink()
    
    # Test unopinionated fallback
    assert auto_detect_project_type(tmp_path) == "unopinionated"

def test_merge_configs():
    """Test config merging."""
    base = {
        "include_extensions": [".py"],
        "templates": {
            "python": {
                "exclude_extensions": [".pyc"]
            }
        }
    }
    
    override = {
        "include_extensions": [".js"],
        "templates": {
            "python": {
                "exclude_extensions": [".pyo"]
            }
        }
    }
    
    merged = merge_configs(base, override)
    assert merged["include_extensions"] == [".js"]
    assert merged["templates"]["python"]["exclude_extensions"] == [".pyo"] 