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

# Excluded file patterns
EXCLUDED_FILES=(
${EXCLUDED_FILES[@]/#/    \"}
${EXCLUDED_FILES[@]/%/\"}
)

# Excluded folder patterns
EXCLUDED_FOLDERS=(
${EXCLUDED_FOLDERS[@]/#/    \"}
${EXCLUDED_FOLDERS[@]/%/\"}
)
EOF
    
    echo "✅ Created configuration file"
    echo "✨ CodeSight initialized successfully!"
    echo "   Run './codesight.sh analyze' to analyze your codebase"
} 