#!/bin/bash
# CodeSight file collection utilities
# This module provides a unified API for file collection across the codebase

# Source the file collection implementation
source "$SCRIPT_DIR/src/utils/collector/file_collector.sh"

# Main file collection function that should be used by all commands
function collect_files() {
    local directory="$1"
    local extensions="$2"
    local max_files="$3"
    local max_size="$4"
    local use_gitignore="$5"
    local files_array_name="$6"
    
    echo "📂 Collecting files..."
    
    # Check if using gitignore integration - only show messages in verbose mode
    if [[ "$use_gitignore" == "true" ]] && [[ -n "$CODESIGHT_VERBOSE" ]]; then
        if [[ -f "$directory/.gitignore" ]]; then
            if command -v git &>/dev/null; then
                echo "   Using Git's built-in .gitignore handling"
            else
                echo "   .gitignore found but Git not available. Patterns will be ignored."
            fi
        else
            echo "   No .gitignore found. Using standard exclusion rules."
        fi
    fi
    
    # Call the unified file collection implementation
    collect_files_unified "$directory" "$extensions" "$max_files" "$max_size" \
                         "$use_gitignore" "$SKIP_BINARY_FILES" "$files_array_name"
}

# Legacy wrapper for backward compatibility
function collect_files_respecting_gitignore() {
    local directory="$1"
    local extensions="$2"
    local files_array_name="$3"
    
    # Use unlimited files but standard MAX_FILE_SIZE limit
    collect_files_unified "$directory" "$extensions" "0" "$MAX_FILE_SIZE" \
                         "true" "$SKIP_BINARY_FILES" "$files_array_name"
}

# Legacy wrapper for backward compatibility
function collect_files_traditional() {
    local directory="$1"
    local extensions="$2"
    local max_files="$3"
    local max_size="$4"
    local files_array_name="$5"
    
    # Call with gitignore=false
    collect_files_unified "$directory" "$extensions" "$max_files" "$max_size" \
                        "false" "$SKIP_BINARY_FILES" "$files_array_name"
}