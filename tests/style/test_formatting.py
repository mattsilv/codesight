"""Tests for code formatting style."""

import ast
from pathlib import Path

import pytest

# Constants for test assertions
MAX_LINE_LENGTH = 100


def get_python_files() -> list[Path]:
    """Get all Python files in the project."""
    root = Path(__file__).parent.parent.parent / "src"
    return [p for p in root.rglob("*.py") if p.is_file()]


def test_function_type_annotations() -> None:
    """Test that all functions have type annotations."""
    for file_path in get_python_files():
        with open(file_path, encoding="utf-8") as f:
            content = f.read()

        try:
            tree = ast.parse(content)
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    # Skip if it's a test function (they can have capsys without annotation)
                    if node.name.startswith("test_") and "capsys" in {
                        arg.arg for arg in node.args.args
                    }:
                        continue

                    # Check return annotation
                    assert node.returns is not None, (
                        f"Function '{node.name}' in {file_path} "
                        "is missing return type annotation"
                    )

                    # Check argument annotations
                    for arg in node.args.args:
                        if arg.arg == "self":  # Skip self in methods
                            continue
                        assert arg.annotation is not None, (
                            f"Argument '{arg.arg}' in function '{node.name}' "
                            f"in {file_path} is missing type annotation"
                        )
        except SyntaxError as e:
            pytest.fail(f"Syntax error in {file_path}: {e}")


def test_no_duplicate_function_definitions() -> None:
    """Test that there are no duplicate function definitions."""
    for file_path in get_python_files():
        with open(file_path, encoding="utf-8") as f:
            content = f.read()

        try:
            tree = ast.parse(content)
            function_names = {}

            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    if node.name in function_names:
                        pytest.fail(f"Duplicate function '{node.name}' defined in {file_path}")
                    function_names[node.name] = True
        except SyntaxError as e:
            pytest.fail(f"Syntax error in {file_path}: {e}")
