"""Deprecated: Style tests have been moved to tests/style/ directory.

Please use the following modules instead:
- tests.style.test_imports: For import-related tests
- tests.style.test_formatting: For code formatting tests.
"""

import ast
import importlib
import sys
from pathlib import Path
from typing import List, Set, Tuple

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


def get_all_imports(tree: ast.AST) -> Set[Tuple[str, str, str]]:
    """Get all import names from an AST."""
    imports = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for name in node.names:
                imports.add(("direct", name.name, ""))
        elif isinstance(node, ast.ImportFrom):
            # Skip relative imports (those with a nonzero level)
            if getattr(node, "level", 0) > 0:
                continue
            module = node.module if node.module else ""
            # Skip known modules that you want to ignore
            if module == "typing" or module == "codesight" or module.startswith("codesight."):
                continue
            for name in node.names:
                imports.add(("from", module, name.name))
    return imports


def test_no_unused_imports() -> None:
    """Test that there are no unused imports in Python files."""
    for file_path in get_python_files():
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        try:
            tree = ast.parse(content)
            imports = {
                name.name
                for node in ast.walk(tree)
                if isinstance(node, (ast.Import, ast.ImportFrom))
                for name in node.names
            }

            # Get all names used in the file
            used_names = {
                node.id
                for node in ast.walk(tree)
                if isinstance(node, ast.Name) and isinstance(node.ctx, ast.Load)
            }

            # Check for unused imports
            unused = imports - used_names
            assert not unused, f"Unused imports in {str(file_path)}: {unused}"
        except SyntaxError as e:
            pytest.fail(f"Syntax error in {file_path}: {e}")


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


def test_imports_can_be_resolved() -> None:
    """Test that all imports in Python files can be resolved."""
    # Add src directory to Python path for package imports
    src_path = Path("src").resolve()
    if src_path not in sys.path:
        sys.path.insert(0, str(src_path))

    for file_path in get_python_files():
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        try:
            tree = ast.parse(content)
            imports = get_all_imports(tree)

            for import_type, module, name in imports:
                try:
                    if import_type == "direct":
                        importlib.import_module(module)
                    elif import_type == "from":
                        importlib.import_module(module)
                except ImportError as e:
                    msg = f"Import '{module}.{name}' in {file_path} cannot be resolved"
                    pytest.fail(f"{msg}: {e}")
        except SyntaxError as e:
            pytest.fail(f"Syntax error in {file_path}: {e}")
