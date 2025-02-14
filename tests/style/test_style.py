"""Tests for code style and formatting."""

import ast
from pathlib import Path


def get_source_files() -> list[Path]:
    """Get all Python files in the project's src directory."""
    root = Path(__file__).parent.parent.parent
    return [
        p for p in (root / "src").rglob("*.py") if not any(part.startswith(".") for part in p.parts)
    ]


def test_function_definitions() -> None:
    """Test basic function definition quality."""
    for file_path in get_source_files():
        with open(file_path, encoding="utf-8") as f:
            tree = ast.parse(f.read())

            # Get all function definitions
            functions = [node for node in ast.walk(tree) if isinstance(node, ast.FunctionDef)]

            # Skip empty files
            if not functions:
                continue

            # Test function names are unique
            names = [f.name for f in functions]
            assert len(names) == len(set(names)), f"Duplicate function names in {file_path}"

            # Test functions have docstrings
            for func in functions:
                assert ast.get_docstring(func), f"Missing docstring in {file_path}: {func.name}"
