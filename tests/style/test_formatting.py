"""Tests for code formatting style."""

import ast
from pathlib import Path
from typing import List

import pytest


def get_python_files() -> List[Path]:
    """Get all Python files in the project."""
    src_dir = Path("src/codesight")
    test_dir = Path("tests")
    python_files = []

    for directory in [src_dir, test_dir]:
        for file in directory.rglob("*.py"):
            python_files.append(file)

    return python_files


def test_line_length() -> None:
    """Test that no lines exceed 100 characters."""
    for file_path in get_python_files():
        with open(file_path, "r", encoding="utf-8") as f:
            for i, line in enumerate(f, 1):
                if len(line.rstrip()) > 100:
                    pytest.fail(f"Line {i} in {file_path} exceeds 100 characters: {line.strip()}")


def test_function_type_annotations() -> None:
    """Test that all functions have type annotations."""
    for file_path in get_python_files():
        with open(file_path, "r", encoding="utf-8") as f:
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
        with open(file_path, "r", encoding="utf-8") as f:
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
