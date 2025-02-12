"""Tests for auto_detect module."""

from pathlib import Path
from tempfile import TemporaryDirectory

from codesight.auto_detect import auto_detect_project_type


def test_detect_python_by_pyproject() -> None:
    """Test detection of Python project by pyproject.toml."""
    with TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        (temp_path / "pyproject.toml").touch()
        assert auto_detect_project_type(temp_path) == "python"


def test_detect_javascript_by_package() -> None:
    """Test detection of JavaScript project by package.json."""
    with TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        (temp_path / "package.json").touch()
        assert auto_detect_project_type(temp_path) == "javascript"


def test_detect_none_for_empty_dir() -> None:
    """Test detection returns unopinionated for empty directory."""
    with TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        assert auto_detect_project_type(temp_path) == "unopinionated"


def test_detect_none_for_mixed_files() -> None:
    """Test detection returns unopinionated for mixed file types."""
    with TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        (temp_path / "main.py").touch()
        (temp_path / "app.js").touch()
        assert auto_detect_project_type(temp_path) == "unopinionated"
