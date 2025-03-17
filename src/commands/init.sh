#!/bin/bash
# CodeSight init command
# Initializes a project directory for CodeSight

function init_project() {
    local directory="${1:-$CURRENT_DIR}"
    
    echo "🚀 Initializing CodeSight in $directory..."
    
    # Create .codesight directory if it doesn't exist
    if [[ ! -d "$directory/.codesight" ]]; then
        mkdir -p "$directory/.codesight"
        echo "   Created directory: $directory/.codesight"
    else
        echo "   Directory already exists: $directory/.codesight"
    fi
    
    # Check if config already exists
    if [[ -f "$directory/.codesight/config" ]]; then
        echo "   Config file already exists"
        echo "   To reset to defaults, remove $directory/.codesight/config and run init again"
        return 0
    fi
    
    # Create default config file
    cat > "$directory/.codesight/config" << EOF
# CodeSight configuration file
# Edit this file to customize CodeSight's behavior

# File extensions to include (space-separated)
FILE_EXTENSIONS=".py .js .jsx .ts .tsx .html .css .md .json"

# Limits for token optimization
MAX_LINES_PER_FILE=100  # Truncate files longer than this
MAX_FILES=100           # Maximum number of files to process
MAX_FILE_SIZE=100000    # Skip files larger than this (bytes)

# Excluded patterns (these override .gitignore if found)
EXCLUDED_FILES=("package-lock.json" "yarn.lock" ".DS_Store")
EXCLUDED_FOLDERS=("node_modules" "dist" ".git" "venv" "__pycache__")

# Gitignore support
RESPECT_GITIGNORE=true  # Exclude folders listed in .gitignore

# Token optimization options
ENABLE_ULTRA_COMPACT_FORMAT=false  # Ultra-compact output format
REMOVE_COMMENTS=true               # Remove comments from code
REMOVE_EMPTY_LINES=true            # Remove empty lines from code
REMOVE_IMPORTS=false               # Remove import statements
ABBREVIATE_HEADERS=false           # Use abbreviated headers
TRUNCATE_PATHS=false               # Shorten file paths
MINIMIZE_METADATA=false            # Reduce metadata in output
SHORT_DATE_FORMAT=true             # Use compact date format
SKIP_BINARY_FILES=true             # Skip files that appear to be binary
EOF
    
    echo "✅ Created default config file: $directory/.codesight/config"
    echo "   Edit this file to customize CodeSight's behavior"
    
    echo ""
    echo "🔍 To analyze your codebase, run:"
    echo "   codesight analyze"
    
    return 0
}