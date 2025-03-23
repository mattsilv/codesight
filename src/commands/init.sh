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
    
    # Create default config file using the default values from config.sh
    
    # Create a properly formatted array string for excluded files
    local excluded_files_str="("
    for item in "${EXCLUDED_FILES[@]}"; do
        excluded_files_str+="\"$item\" "
    done
    excluded_files_str="${excluded_files_str% })"
    
    # Create a properly formatted array string for excluded folders
    local excluded_folders_str="("
    for item in "${EXCLUDED_FOLDERS[@]}"; do
        excluded_folders_str+="\"$item\" "
    done
    excluded_folders_str="${excluded_folders_str% })"
    
    cat > "$directory/.codesight/config" << EOF
# CodeSight configuration file
# Edit this file to customize CodeSight's behavior

# File extensions to include (space-separated)
FILE_EXTENSIONS="$FILE_EXTENSIONS"

# Limits for token optimization
MAX_LINES_PER_FILE=$MAX_LINES_PER_FILE  # Truncate files longer than this
MAX_FILES=$MAX_FILES           # Maximum number of files to process
MAX_FILE_SIZE=$MAX_FILE_SIZE    # Skip files larger than this (bytes)

# Excluded patterns (these override .gitignore if found)
EXCLUDED_FILES=$excluded_files_str
EXCLUDED_FOLDERS=$excluded_folders_str

# Gitignore support
RESPECT_GITIGNORE=$RESPECT_GITIGNORE  # Exclude folders listed in .gitignore

# Token optimization options
ENABLE_ULTRA_COMPACT_FORMAT=$ENABLE_ULTRA_COMPACT_FORMAT  # Ultra-compact output format
REMOVE_COMMENTS=$REMOVE_COMMENTS               # Remove comments from code
REMOVE_EMPTY_LINES=$REMOVE_EMPTY_LINES            # Remove empty lines from code
REMOVE_IMPORTS=$REMOVE_IMPORTS               # Remove import statements
ABBREVIATE_HEADERS=$ABBREVIATE_HEADERS           # Use abbreviated headers
TRUNCATE_PATHS=$TRUNCATE_PATHS               # Shorten file paths
MINIMIZE_METADATA=$MINIMIZE_METADATA            # Reduce metadata in output
SHORT_DATE_FORMAT=$SHORT_DATE_FORMAT             # Use compact date format
SKIP_BINARY_FILES=$SKIP_BINARY_FILES             # Skip files that appear to be binary
EOF
    
    echo "✅ Created default config file: $directory/.codesight/config"
    echo "   Edit this file to customize CodeSight's behavior"
    
    echo ""
    echo "🔍 To analyze your codebase, run:"
    echo "   codesight analyze"
    
    return 0
}