"""Tests for the reporting module."""

from pathlib import Path
from typing import Any

import pytest

from codesight.reporting import display_error_summary, display_file_stats

# Constants for group comparisons
CONFIG_GROUP = 2  # .env, config.py
CORE_GROUP = 1  # README.md, pyproject.toml
DOCS_GROUP = 6  # docs/, examples/
ENTRY_POINT_GROUP = 3  # __init__.py, main.py
SOURCE_GROUP = 4  # src/, lib/, core/
OTHER_GROUP = 8  # Other files


def test_display_file_stats(capsys: pytest.CaptureFixture[str]) -> None:
    """Test file statistics display."""
    file_stats = {
        "test.py": {"tokens": 100, "lines": 50, "was_processed": True},
    }
    total_tokens = 100

    display_file_stats(file_stats, total_tokens)
    output = capsys.readouterr().out

    assert "File Statistics" in output
    assert "test.py" in output
    assert "100" in output


def test_display_file_stats_root_directory(capsys: pytest.CaptureFixture[str]) -> None:
    """Test display of files in root directory."""
    file_stats = {
        "main.py": {"tokens": 100, "lines": 50, "was_processed": True},
        "src/utils.py": {"tokens": 80, "lines": 40, "was_processed": True},
    }

    display_file_stats(file_stats, total_token_count=180)
    captured = capsys.readouterr()
    output = captured.out

    assert "root" in output.lower()  # Check root directory indication
    assert "src" in output  # Check normal directory path


def test_display_error_summary(capsys: pytest.CaptureFixture[str]) -> None:
    """Test error summary display."""
    errors = [
        (Path("src/main.py"), "Syntax error"),
        (Path("tests/test_main.py"), "Import error"),
    ]

    display_error_summary(errors)
    output = capsys.readouterr().out

    assert "src/main.py" in output
    assert "tests/test_main.py" in output
    assert "Syntax error" in output
    assert "Import error" in output


def test_display_empty_error_summary(capsys: pytest.CaptureFixture[str]) -> None:
    """Test error summary display with no errors."""
    display_error_summary([])
    captured = capsys.readouterr()
    assert captured.out == ""  # No output when no errors


def test_display_file_stats_empty(capsys: pytest.CaptureFixture[str]) -> None:
    """Test file statistics display with empty data."""
    file_stats: dict[str, dict[str, Any]] = {}
    total_tokens = 0

    display_file_stats(file_stats, total_tokens)
    output = capsys.readouterr().out

    assert "File Statistics" in output
    assert "+0 files" in output
    assert "0" in output  # Total tokens and lines
