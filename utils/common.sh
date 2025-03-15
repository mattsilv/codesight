#!/bin/bash
# Common utility functions

# Check if a file is binary
function is_binary_file() {
    local file="$1"
    
    # Use file command to detect binary files
    if file "$file" | grep -q "text"; then
        return 1 # Not binary
    else
        return 0 # Binary
    fi
}

# Clean content for output - aggressive token reduction
function clean_content() {
    # Process input to reduce token usage:
    # - Remove trailing whitespace and normalize line endings
    # - Remove empty lines
    # - Remove comments (C, C++, Python, Bash)
    # - Collapse multiple spaces to single space
    # - Remove common import/require statements
    # - Remove excessive blank lines
    sed 's/[ \t]*$//' | tr -d '\r' | \
    sed '/^\s*$/d' | \
    sed -e 's/\/\/.*$//' -e 's/\/\*.*\*\///' -e 's/^\s*#.*$//' | \
    sed 's/  */ /g' | \
    sed -e '/^\s*import /d' -e '/^\s*from .* import/d' -e '/^\s*require(/d' | \
    sed '/./,/^$/!d'
}

# Create directory if it doesn't exist
function ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

# Print colored output
function print_color() {
    local color="$1"
    local message="$2"
    
    case "$color" in
        "red")
            echo -e "\033[0;31m$message\033[0m"
            ;;
        "green")
            echo -e "\033[0;32m$message\033[0m"
            ;;
        "yellow")
            echo -e "\033[0;33m$message\033[0m"
            ;;
        "blue")
            echo -e "\033[0;34m$message\033[0m"
            ;;
        *)
            echo "$message"
            ;;
    esac
} 