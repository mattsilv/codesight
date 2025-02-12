"""Auto-detect project type based on files and structure."""

from pathlib import Path
from typing import Literal

ProjectType = Literal["python", "javascript"]


def auto_detect_project_type(path: Path = Path(".")) -> str:
    """Auto-detect project type based on files and structure."""
    # Check for Python project indicators
    python_indicators = ["pyproject.toml", "setup.py", "requirements.txt"]
    for indicator in python_indicators:
        if (path / indicator).exists():
            return "python"

    # Check for JavaScript project indicators
    js_indicators = ["package.json", "package-lock.json"]
    for indicator in js_indicators:
        if (path / indicator).exists():
            return "javascript"

    # Unable to determine type
    return "unopinionated"
