"""Functions for transforming Python code and handling AST operations."""

import ast
import logging
from typing import Tuple

logger = logging.getLogger(__name__)


def truncate_large_literals(node: ast.AST, max_elements: int = 5) -> ast.AST:
    """Truncate large lists and dicts in Python AST to a maximum number of elements."""
    if isinstance(node, ast.List):
        if len(node.elts) > max_elements:
            node.elts = node.elts[:max_elements]
    elif isinstance(node, ast.Dict):
        if len(node.keys) > max_elements:
            node.keys = node.keys[:max_elements]
            node.values = node.values[:max_elements]
    elif isinstance(node, ast.Set):
        if len(node.elts) > max_elements:
            node.elts = node.elts[:max_elements]

    for child in ast.iter_child_nodes(node):
        truncate_large_literals(child, max_elements)
    return node


def process_python_file(content: str, truncate_size: int = 5) -> Tuple[str, bool]:
    """Process Python file content, truncating large literals if needed."""
    try:
        tree = ast.parse(content)
        modified_tree = truncate_large_literals(tree, truncate_size)
        return ast.unparse(modified_tree), True
    except SyntaxError as e:
        logger.warning("Failed to parse Python file: %s", e)
        return content, False
    except Exception as e:
        logger.error("Error processing Python file: %s", e)
        return content, False
