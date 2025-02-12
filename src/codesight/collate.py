"""Core file gathering and collation logic."""
import ast
from pathlib import Path
from typing import List, Set, Optional, Tuple
from fnmatch import fnmatch
import logging
import chardet

try:
    import tiktoken
except ImportError:
    tiktoken = None

logger = logging.getLogger(__name__)

def parse_gitignore(root_folder: Path) -> List[str]:
    """Parse .gitignore patterns from the root folder."""
    gitignore_path = root_folder / '.gitignore'
    if not gitignore_path.exists():
        logger.debug("No .gitignore file found at %s", gitignore_path)
        return []
    
    try:
        with open(gitignore_path, 'r', encoding='utf-8') as f:
            return [line.strip() for line in f if line.strip() and not line.startswith('#')]
    except UnicodeDecodeError:
        logger.warning("Failed to read .gitignore with UTF-8 encoding, attempting detection")
        with open(gitignore_path, 'rb') as f:
            content = f.read()
            encoding = chardet.detect(content)['encoding'] or 'utf-8'
        with open(gitignore_path, 'r', encoding=encoding) as f:
            return [line.strip() for line in f if line.strip() and not line.startswith('#')]
    except Exception as e:
        logger.error("Failed to read .gitignore: %s", e)
        return []

def should_ignore(path: Path, config: dict) -> bool:
    """
    Check if a file should be ignored based on gitignore patterns and configuration.
    """
    # Check if any parent folder starts with a dot (hidden folder)
    for part in path.parts:
        if part.startswith('.'):
            # Allow if the path or any parent path is in include_files
            current_path = part
            if current_path in config.get('include_files', []):
                return False
            
            # Check if any parent path is included
            for i in range(len(path.parts)):
                if str(Path(*path.parts[:i+1])) in config.get('include_files', []):
                    return False
            
            # If not explicitly included, ignore hidden folders
            return True

    # Check if file matches any exclude patterns
    if any(fnmatch(str(path), pattern) for pattern in config.get('exclude_files', [])):
        return True

    # Check file extension
    if path.suffix and config.get('include_extensions'):
        return path.suffix not in config.get('include_extensions', [])

    return False

def truncate_large_literals(node: ast.AST, max_elements: int = 5) -> ast.AST:
    """Truncate large lists, sets, dicts in Python AST."""
    if isinstance(node, (ast.List, ast.Set, ast.Dict)):
        if isinstance(node, ast.Dict):
            if len(node.keys) > max_elements:
                node.keys = node.keys[:max_elements]
                node.values = node.values[:max_elements]
        else:
            if len(node.elts) > max_elements:
                node.elts = node.elts[:max_elements]
    for child in ast.iter_child_nodes(node):
        truncate_large_literals(child, max_elements)
    return node

def process_python_file(content: str, max_elements: int) -> Tuple[str, bool]:
    """Process Python file content, truncating large literals.
    Returns tuple of (processed_content, was_processed)"""
    try:
        tree = ast.parse(content)
        modified_tree = truncate_large_literals(tree, max_elements)
        return ast.unparse(modified_tree), True
    except SyntaxError as e:
        logger.warning("Failed to parse Python file due to syntax error: %s", e)
        return content, False
    except Exception as e:
        logger.warning("Failed to process Python file: %s", e)
        return content, False

def estimate_token_length(text: str, model: str = "gpt-3.5-turbo") -> Optional[int]:
    """Estimate the number of tokens in the text using tiktoken."""
    if not tiktoken:
        return None
    try:
        encoding = tiktoken.encoding_for_model(model)
        return len(encoding.encode(text, disallowed_special=()))
    except Exception as e:
        print(f"Warning: Error while tokenizing text: {e}")
        return None

def gather_and_collate(root_folder: Path, config: dict) -> tuple[str, Optional[int], list[tuple[Path, int]]]:
    """Gather and collate files based on configuration."""
    collected_files = []
    file_stats = []  # List of (path, token_count) tuples
    key_dirs = config.get('key_directories', [])
    file_docs = config.get('file_docs', {})
    errors = []
    
    def should_process_path(path: Path) -> bool:
        """Check if a path should be processed based on key directories."""
        if not key_dirs:  # If no key directories specified, process everything
            return True
        try:
            rel_path = path.relative_to(root_folder)
            return any(str(rel_path).startswith(str(Path(d))) for d in key_dirs)
        except ValueError:
            logger.debug("Could not determine relative path for %s", path)
            return False
    
    for path in root_folder.rglob('*'):
        if not path.is_file():
            continue
            
        if not should_process_path(path):
            continue
            
        if should_ignore(path, config):
            continue
            
        if path.suffix in config['include_extensions'] or str(path.name) in config['include_files']:
            try:
                # Try UTF-8 first
                try:
                    with open(path, 'r', encoding='utf-8') as f:
                        content = f.read()
                except UnicodeDecodeError:
                    # If UTF-8 fails, try to detect encoding
                    with open(path, 'rb') as f:
                        raw_content = f.read()
                    encoding = chardet.detect(raw_content)['encoding'] or 'utf-8'
                    logger.info("Detected %s encoding for %s", encoding, path)
                    with open(path, 'r', encoding=encoding) as f:
                        content = f.read()
                
                # Process Python files if needed
                if path.suffix == '.py' and config['truncate_py_literals']:
                    content, was_processed = process_python_file(content, config['truncate_py_literals'])
                    if not was_processed:
                        logger.warning("Failed to process Python literals in %s", path)
                
                relative_path = path.relative_to(root_folder)
                file_doc = file_docs.get(str(relative_path), "")
                
                # Calculate token count for this file
                file_content = f"```{path.suffix[1:]}\n{content}\n```"
                if file_doc:
                    file_content = f"DOCUMENTATION:\n{file_doc}\n\nCONTENTS:\n{file_content}"
                file_token_count = estimate_token_length(file_content) or 0
                file_stats.append((relative_path, file_token_count))
                
                if file_doc:
                    collected_files.append(f"### File: {relative_path}\nDOCUMENTATION:\n{file_doc}\n\nCONTENTS:\n```{path.suffix[1:]}\n{content}\n```\n\n")
                else:
                    collected_files.append(f"### File: {relative_path}\n\n```{path.suffix[1:]}\n{content}\n```\n\n")
            except Exception as e:
                errors.append(f"Error processing {path}: {str(e)}")
                logger.error("Failed to process %s: %s", path, e)
                continue
    
    if errors:
        logger.warning("Encountered errors while processing files:\n%s", "\n".join(errors))
    
    final_text = "".join(collected_files)
    total_token_count = estimate_token_length(final_text) if tiktoken else None
    return final_text, total_token_count, file_stats 