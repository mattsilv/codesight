"""Tests for import style and resolution."""

import ast
import importlib
import sys
from pathlib import Path
from typing import Set

import pytest

EXCLUDED_FILES: Set[str] = {
    "tests/style/test_imports.py",
    "tests/style/test_formatting.py",
}


def get_python_files() -> Set[Path]:
    """Get all Python files in the project."""
    return {p for p in Path(".").rglob("*.py") if p.is_file()}


def get_all_imports(tree: ast.AST) -> set[tuple[str, str, str]]:
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
        with open(file_path, encoding="utf-8") as f:
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
            assert not unused, f"Unused imports in {file_path}: {unused}"
        except SyntaxError as e:
            pytest.fail(f"Syntax error in {file_path}: {e}")


def test_imports_can_be_resolved() -> None:
    """Test that all imports in Python files can be resolved."""
    # Add src directory to Python path for package imports
    src_path = Path("src").resolve()
    if src_path not in sys.path:
        sys.path.insert(0, str(src_path))

    for file_path in get_python_files():
        with open(file_path, encoding="utf-8") as f:
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


def get_imports(content: str) -> tuple[set[str], list[tuple[str, str]]]:
    """Extract imports from Python code.

    Returns:
        tuple: (set of module imports, list of from imports)
    """
    tree = ast.parse(content)
    module_imports: set[str] = set()
    from_imports: list[tuple[str, str]] = []

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for name in node.names:
                module_imports.add(name.name)
        elif isinstance(node, ast.ImportFrom):
            module = node.module or ""
            for name in node.names:
                from_imports.append((module, name.name))

    return module_imports, from_imports


def test_import_order() -> None:
    """Test that imports are properly ordered."""
    for file_path in get_python_files():
        with open(file_path, encoding="utf-8") as f:
            content = f.read()

        module_imports, from_imports = get_imports(content)

        # Check that standard library imports come first
        for module in module_imports:
            if "." in module:
                assert any(
                    module.startswith(stdlib)
                    for stdlib in ["os", "sys", "pathlib", "logging", "typing"]
                ), f"Third-party import {module} before standard library imports in {file_path}"


def test_import_sorting() -> None:
    """Test that imports are properly sorted."""
    files = {str(path) for path in get_python_files()}
    assert files.isdisjoint(EXCLUDED_FILES)
