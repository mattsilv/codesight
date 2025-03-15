#!/bin/bash
# Default configuration for CodeSight

# File extensions to include in analysis
FILE_EXTENSIONS=".py .js .jsx .ts .tsx .html .css .scss .md .json .toml .yaml .yml .sh"

# Maximum number of lines per file before truncation
MAX_LINES_PER_FILE=1000

# Maximum number of files to include
MAX_FILES=100

# Skip files larger than this size (in bytes)
MAX_FILE_SIZE=100000

# Skip binary files
SKIP_BINARY_FILES=true

# Respect .gitignore files
RESPECT_GITIGNORE=true

# Token optimization settings
# Set to false for more readable output, true for maximum token efficiency
ENABLE_ULTRA_COMPACT_FORMAT=false
REMOVE_COMMENTS=true
REMOVE_EMPTY_LINES=true
REMOVE_IMPORTS=false
ABBREVIATE_HEADERS=false
TRUNCATE_PATHS=false
MINIMIZE_METADATA=false
SHORT_DATE_FORMAT=true

# Files to always exclude
EXCLUDED_FILES=(
    "package-lock.json"
    "yarn.lock"
    "Cargo.lock"
    ".DS_Store"
    "Thumbs.db"
    ".gitattributes"
    ".editorconfig"
    "*.pyc"
    "*.pyo"
    "*.pyd"
    "*.so"
    "*.dylib"
    "*.dll"
    "*.class"
    "*.o"
    "*.obj"
    "codesight.txt"
    ".env"
)

# Folders to always exclude (and all their contents)
EXCLUDED_FOLDERS=(
    "node_modules"
    "dist"
    "build"
    ".git"
    ".github"
    ".vscode"
    ".idea"
    "__pycache__"
    "venv"
    ".venv"
    ".env"
    ".tox"
    ".pytest_cache"
    ".coverage"
    "coverage"
    ".codesight"
)

# Display fancy ASCII banner
# TODO: Add banner