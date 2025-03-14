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

# Clean content for output
function clean_content() {
    # Remove trailing whitespace and normalize line endings
    sed 's/[ \t]*$//' | tr -d '\r'
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