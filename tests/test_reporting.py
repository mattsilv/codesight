"""Tests for the reporting module."""

from pathlib import Path
from typing import Any, Dict

import pytest

from codesight.reporting import display_error_summary, display_file_stats


def test_display_file_stats(capsys: pytest.CaptureFixture[str]) -> None:
    """Test file statistics display."""
    # Create sample data with more than 10 files to test pagination
    file_stats: Dict[str, Dict[str, Any]] = {
        "src/main.py": {"tokens": 500, "lines": 200, "was_processed": True},
        "src/utils.py": {"tokens": 300, "lines": 150, "was_processed": True},
        "src/config.py": {"tokens": 200, "lines": 100, "was_processed": True},
        "src/cli.py": {"tokens": 150, "lines": 75, "was_processed": True},
        "src/core.py": {"tokens": 125, "lines": 60, "was_processed": True},
        "src/helpers.py": {"tokens": 100, "lines": 50, "was_processed": True},
        "src/types.py": {"tokens": 90, "lines": 45, "was_processed": True},
        "src/constants.py": {"tokens": 80, "lines": 40, "was_processed": True},
        "src/errors.py": {"tokens": 70, "lines": 35, "was_processed": True},
        "src/logging.py": {"tokens": 60, "lines": 30, "was_processed": True},
        "src/extra1.py": {"tokens": 50, "lines": 25, "was_processed": True},
        "src/extra2.py": {"tokens": 40, "lines": 20, "was_processed": True},
        "README.md": {"tokens": 30, "lines": 15, "was_processed": False},
    }

    display_file_stats(
        file_stats,
        total_token_count=1795,  # Sum of all tokens
        output_file="output.txt",
        copied_to_clipboard=True,
        project_type="python",
    )

    captured = capsys.readouterr()
    output = captured.out

    # Test top 10 files are shown
    assert "main.py" in output  # Highest token count
    assert "utils.py" in output
    assert "logging.py" in output  # 10th file
    assert "extra1.py" not in output  # Should be in remaining files
    assert "src" in output  # Directory path

    # Test remaining files summary
    assert "Other files" in output
    assert "3 files" in output  # extra1.py, extra2.py, README.md
    assert "120" in output  # Sum of remaining tokens (50 + 40 + 30)
    assert "60" in output  # Sum of remaining lines (25 + 20 + 15)

    # Test totals
    assert "Total" in output
    assert "+13 files" in output
    assert "1,795" in output  # Total tokens
    assert "845" in output  # Total lines

    # Test info panel
    assert "python" in output
    assert "output.txt" in output
    assert "Copied to clipboard" in output


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
        (Path("test.py"), "Syntax error"),
        (Path("data.txt"), "Encoding error"),
    ]

    display_error_summary(errors)
    captured = capsys.readouterr()
    output = captured.out

    assert "Errors encountered" in output
    assert "test.py" in output
    assert "Syntax error" in output
    assert "data.txt" in output
    assert "Encoding error" in output


def test_display_empty_error_summary(capsys: pytest.CaptureFixture[str]) -> None:
    """Test error summary display with no errors."""
    display_error_summary([])
    captured = capsys.readouterr()
    assert captured.out == ""  # No output when no errors


def test_display_file_stats_no_processed_files(capsys: pytest.CaptureFixture[str]) -> None:
    """Test display when no files were processed."""
    file_stats: Dict[str, Dict[str, Any]] = {}
    display_file_stats(file_stats, total_token_count=0)

    captured = capsys.readouterr()
    output = captured.out

    assert "Total" in output
    assert "+0 files" in output
    assert "0" in output  # Total tokens and lines
