#!/usr/bin/env python3
"""
Exclusion handling for CodeSight.
Handles gitignore patterns and file exclusions.
"""
import os
import re
from typing import List, Tuple
import config

def parse_gitignore(root_dir: str) -> List[str]:
    """
    Parse .gitignore file and return ignore patterns
    
    Args:
        root_dir: Root directory of the project
        
    Returns:
        List of gitignore patterns
    """
    gitignore_path = os.path.join(root_dir, ".gitignore")
    patterns = []
    
    # Add common patterns that should always be ignored
    common_ignores = [
        "node_modules/",
        "venv/",
        ".venv/",
        "__pycache__/",
        "*.pyc",
        "*.pyo",
        "*.pyd",
        ".git/",
        ".idea/",
        ".vscode/",
        "dist/",
        "build/",
        "*.egg-info/",
        ".DS_Store",
        "*.so",
        "*.dylib",
        "*.dll",
        "*.class"
    ]
    patterns.extend(common_ignores)
    
    if os.path.exists(gitignore_path):
        with open(gitignore_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    patterns.append(line)
    
    return patterns

def convert_gitignore_pattern_to_regex(pattern: str) -> Tuple[str, bool]:
    """
    Convert a gitignore pattern to a regex pattern
    
    Args:
        pattern: Gitignore pattern
        
    Returns:
        Tuple of (regex_pattern, is_negation)
    """
    # Handle negation (patterns that start with !)
    is_negation = pattern.startswith("!")
    if is_negation:
        pattern = pattern[1:]
    
    # Handle directory-only patterns (patterns that end with /)
    is_dir_only = pattern.endswith("/")
    if is_dir_only:
        pattern = pattern[:-1]
        
    # Handle patterns that start with / (anchored to root)
    is_anchored = pattern.startswith("/")
    if is_anchored:
        pattern = pattern[1:]
    
    # Convert the glob pattern to a regex pattern
    if "**" in pattern:
        # Handle ** pattern (matches any number of directories)
        pattern = pattern.replace("**", "__DOUBLE_STAR__")
    
    # Escape special regex characters
    pattern = re.escape(pattern)
    
    # Restore ** pattern
    pattern = pattern.replace("__DOUBLE_STAR__", ".*")
    
    # Convert gitignore glob patterns to regex
    pattern = pattern.replace("\\*", "[^/]*")  # * matches anything except /
    pattern = pattern.replace("\\?", "[^/]")   # ? matches a single character except /
    
    # Build the final regex pattern
    if is_anchored:
        # Pattern is anchored to root
        if is_dir_only:
            regex = f"^{pattern}(/.*)?$"
        else:
            regex = f"^{pattern}(/.*)?$|^{pattern}$"
    else:
        # Pattern can match anywhere in the path
        if is_dir_only:
            regex = f"^{pattern}(/.*)?$|^.+/{pattern}(/.*)?$"
        else:
            regex = f"^{pattern}(/.*)?$|^{pattern}$|^.+/{pattern}(/.*)?$|^.+/{pattern}$"
    
    return regex, is_negation

def is_path_ignored(path: str, ignore_patterns: List[Tuple[str, bool]]) -> bool:
    """
    Check if a path should be ignored based on gitignore patterns
    
    Args:
        path: Path to check (relative to root)
        ignore_patterns: List of (regex_pattern, is_negation) tuples
        
    Returns:
        True if the path should be ignored, False otherwise
    """
    # Default to not ignored
    ignored = False
    
    # Convert Windows path separators to Unix
    path = path.replace("\\", "/")
    
    for regex_pattern, is_negation in ignore_patterns:
        if re.match(regex_pattern, path):
            # If it's a negation pattern, this path is explicitly NOT ignored
            if is_negation:
                return False
            # Otherwise, mark it as ignored
            ignored = True
    
    return ignored

def is_explicitly_excluded(path: str) -> bool:
    """
    Check if a path is explicitly excluded based on config settings
    
    Args:
        path: Path to check (relative to root)
        
    Returns:
        True if the path should be excluded, False otherwise
    """
    # Get the filename and directory name
    filename = os.path.basename(path)
    
    # Check if the file is in the excluded files list
    if filename in config.EXCLUDED_FILES:
        return True
    
    # Check if any parent directory is in the excluded folders list
    path_parts = path.split(os.sep)
    for i in range(len(path_parts)):
        if path_parts[i] in config.EXCLUDED_FOLDERS:
            return True
    
    return False

def prepare_ignore_patterns(root_dir: str) -> List[Tuple[str, bool]]:
    """
    Prepare ignore patterns from gitignore file
    
    Args:
        root_dir: Root directory of the project
        
    Returns:
        List of (regex_pattern, is_negation) tuples
    """
    # Parse gitignore patterns
    gitignore_patterns = parse_gitignore(root_dir)
    
    # Convert gitignore patterns to regex patterns
    regex_patterns = []
    for pattern in gitignore_patterns:
        regex_pattern, is_negation = convert_gitignore_pattern_to_regex(pattern)
        regex_patterns.append((regex_pattern, is_negation))
    
    return regex_patterns

def should_exclude(rel_path: str, ignore_patterns: List[Tuple[str, bool]]) -> bool:
    """
    Determine if a path should be excluded based on all exclusion rules
    
    Args:
        rel_path: Relative path to check
        ignore_patterns: List of (regex_pattern, is_negation) tuples from gitignore
        
    Returns:
        True if the path should be excluded, False otherwise
    """
    # First check explicit exclusions (highest priority)
    if is_explicitly_excluded(rel_path):
        return True
    
    # Then check gitignore patterns
    if is_path_ignored(rel_path, ignore_patterns):
        return True
    
    return False 