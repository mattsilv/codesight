#!/bin/bash
# Default configuration for CodeSight

# File extensions to include in analysis
FILE_EXTENSIONS=".py .js .jsx .ts .tsx .html .css .scss .md .json .toml .yaml .yml"

# Maximum number of lines per file before truncation
MAX_LINES_PER_FILE=100

# Maximum number of files to include
MAX_FILES=100

# Skip files larger than this size (in bytes)
MAX_FILE_SIZE=100000

# Skip binary files
SKIP_BINARY_FILES=true

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
)

# Display fancy ASCII banner
function display_banner() {
    echo "  ██████╗  ██████╗  ██████╗  ██████╗  ███████╗ ███████╗ ██╗  ██████╗  ██╗  ██╗ ████████╗"
    echo " ██╔════╝ ██╔═══██╗ ██╔══██╗ ██╔══██╗ ██╔════╝ ██╔════╝ ██║ ██╔════╝  ██║  ██║ ╚══██╔══╝"
    echo " ██║      ██║   ██║ ██║  ██║ ██║  ██║ █████╗   ███████╗ ██║ ██║  ███╗ ██║  ██║    ██║   "
    echo " ██║      ██║   ██║ ██║  ██║ ██║  ██║ ██╔══╝   ╚════██║ ██║ ██║   ██║ ██║  ██║    ██║   "
    echo " ╚██████╗ ╚██████╔╝ ██████╔╝ ██████╔╝ ███████╗ ███████║ ██║ ╚██████╔╝ ╚██████╔╝    ██║   "
    echo "  ╚═════╝  ╚═════╝  ╚═════╝  ╚═════╝  ╚══════╝ ╚══════╝ ╚═╝  ╚═════╝   ╚═════╝     ╚═╝   "
    echo "                                                               v$VERSION"
    echo "----------------------------------------------------------------"
}