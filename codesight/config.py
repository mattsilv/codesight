#!/usr/bin/env python3
"""
Configuration settings for CodeSight.
Contains default values that can be overridden via CLI arguments.
"""
from typing import List

# File extensions to include in the analysis
FILE_EXTENSIONS = [
    ".py", ".js", ".jsx", ".ts", ".tsx", ".html", ".css", ".scss", 
    ".md", ".json", ".toml", ".yaml", ".yml"
]

# Maximum number of lines per file before truncation
MAX_LINES = 500

# Default output file name for the overview
OUTPUT_FILE = "codebase_overview.txt"

# Default model for token counting
DEFAULT_MODEL = "gpt-4"

# Version number
VERSION = "0.1.0"

# Explicit file exclusions - these files will always be excluded regardless of other rules
EXCLUDED_FILES = [
    "package-lock.json",
    "yarn.lock",
    "Cargo.lock",
    ".DS_Store",
    "Thumbs.db",
    ".gitattributes",
    ".editorconfig",
    "temp",
    "design.js.txt"
]

# Explicit folder exclusions - these folders and all their contents will always be excluded
EXCLUDED_FOLDERS = [
    "node_modules",
    "dist",
    "build",
    ".git",
    ".github",
    ".vscode",
    ".idea",
    "__pycache__",
    "venv",
    ".venv",
    ".specstory"
]

# Token optimization settings
TOKEN_OPTIMIZATION = {
    # Maximum lines to include per file before truncating
    "MAX_LINES_PER_FILE": 100,
    
    # Maximum files to include in the overview
    "MAX_FILES": 100,
    
    # Skip files larger than this size (in bytes)
    "MAX_FILE_SIZE": 100000,  # 100KB
    
    # Skip binary files and non-text files
    "SKIP_BINARY_FILES": True,
    
    # Skip files with these patterns in their content
    "SKIP_CONTENT_PATTERNS": [
        "DO NOT EDIT",
        "AUTO-GENERATED",
        "GENERATED FILE"
    ],
    
    # Remove these patterns from file content
    "REMOVE_PATTERNS": [
        # Comments
        r'/\*[\s\S]*?\*/',  # C-style block comments
        r'^\s*//.*$',       # C-style line comments
        r'^\s*#.*$',        # Python/shell comments
        
        # Imports and requires
        r'^\s*import\s+.*$',
        r'^\s*from\s+.*\s+import\s+.*$',
        r'^\s*require\s*\(.*\);?$',
        
        # Decorators
        r'^\s*@.*$'
    ],
    
    # Extract only key sections from these file types
    "EXTRACT_KEY_SECTIONS": {
        ".js": True,
        ".jsx": True,
        ".ts": True,
        ".tsx": True,
        ".py": True,
        ".html": True,
        ".css": True,
        ".scss": True
    }
} 