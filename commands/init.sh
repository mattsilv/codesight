#!/bin/bash
# Init command functionality

function init_project() {
    local force=false
    
    # Check for force flag
    if [[ "$1" == "--force" ]]; then
        force=true
    fi
    
    # Check if already initialized
    if [[ -d "$CURRENT_DIR/.codesight" && "$force" == "false" ]]; then
        echo "❌ Error: CodeSight already initialized in this directory."
        echo "   Use --force to reinitialize."
        return 1
    fi
    
    # Create directory
    mkdir -p "$CURRENT_DIR/.codesight"
    echo "✅ Created .codesight directory in $CURRENT_DIR"
    
    # Create config file
    cat > "$CURRENT_DIR/.codesight/config" << EOF
# CodeSight configuration
# Created on $(date)

# File extensions to include
FILE_EXTENSIONS="$FILE_EXTENSIONS"

# Maximum number of lines per file
MAX_LINES_PER_FILE=$MAX_LINES_PER_FILE

# Maximum number of files to include
MAX_FILES=$MAX_FILES

# Maximum file size in bytes
MAX_FILE_SIZE=$MAX_FILE_SIZE

# Skip binary files
SKIP_BINARY_FILES=$SKIP_BINARY_FILES

# Respect gitignore files
RESPECT_GITIGNORE=$RESPECT_GITIGNORE

# Token optimization settings
ENABLE_ULTRA_COMPACT_FORMAT=$ENABLE_ULTRA_COMPACT_FORMAT
REMOVE_COMMENTS=$REMOVE_COMMENTS
REMOVE_EMPTY_LINES=$REMOVE_EMPTY_LINES
REMOVE_IMPORTS=$REMOVE_IMPORTS
ABBREVIATE_HEADERS=$ABBREVIATE_HEADERS
TRUNCATE_PATHS=$TRUNCATE_PATHS
MINIMIZE_METADATA=$MINIMIZE_METADATA
SHORT_DATE_FORMAT=$SHORT_DATE_FORMAT

# Excluded file patterns
EXCLUDED_FILES=(
$(printf "    \"%s\"\n" "${EXCLUDED_FILES[@]}")
)

# Excluded folder patterns
EXCLUDED_FOLDERS=(
$(printf "    \"%s\"\n" "${EXCLUDED_FOLDERS[@]}")
)
)
EOF
    
    echo "✅ Created configuration file"
    echo "✨ CodeSight initialized successfully!"
    echo "   Run './codesight.sh analyze' to analyze your codebase"
} 