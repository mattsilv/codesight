#!/bin/bash
# CodeSight configuration utility
# Handles loading and management of config files

# Default configuration values
FILE_EXTENSIONS=".py .js .jsx .ts .tsx .html .css .md .json .sh"
MAX_LINES_PER_FILE=1000
MAX_FILES=100
MAX_FILE_SIZE=100000
RESPECT_GITIGNORE=true

# Excluded file patterns
EXCLUDED_FILES=("package-lock.json" "yarn.lock" "Cargo.lock" ".DS_Store" "Thumbs.db" 
               ".gitattributes" ".editorconfig" "*.pyc" "*.pyo" "*.pyd" 
               "*.so" "*.dylib" "*.dll" "*.class" "*.o" "*.obj" "codesight.txt" ".env"
               "CLAUDE.md" "CONTRIBUTING.md" "LICENSE")

# Excluded folder patterns
EXCLUDED_FOLDERS=("node_modules" "dist" "build" ".git" ".github" ".vscode" ".idea" 
                 "__pycache__" "venv" ".venv" ".env" ".tox" ".pytest_cache" 
                 ".coverage" "coverage" ".codesight" "docs")

# Token optimization settings
ENABLE_ULTRA_COMPACT_FORMAT=false
REMOVE_COMMENTS=true
REMOVE_EMPTY_LINES=true
REMOVE_IMPORTS=false
ABBREVIATE_HEADERS=false
TRUNCATE_PATHS=false
MINIMIZE_METADATA=false
SHORT_DATE_FORMAT=true
SKIP_BINARY_FILES=true

# Load configuration from multiple sources
function load_config() {
    local directory="$1"
    local config_loaded=false
    
    # Check for local config in current directory
    if [[ -f "$directory/.codesight/config" ]]; then
        source "$directory/.codesight/config"
        config_loaded=true
    fi
    
    # Check for user config in home directory (for global settings)
    if [[ -f "$HOME/.codesight/config" ]]; then
        source "$HOME/.codesight/config"
        config_loaded=true
    fi
    
    return 0
}

# Load config from specified directory if it exists
function load_local_config() {
    local directory="$1"
    
    if [[ -d "$directory/.codesight" && -f "$directory/.codesight/config" ]]; then
        source "$directory/.codesight/config"
        return 0
    fi
    
    return 1
}

# Helper to clean content and reduce tokens
function clean_content() {
    local content=""
    
    # Read content from stdin
    while IFS= read -r line; do
        content+="$line"$'\n'
    done
    
    # Apply token reduction techniques based on configuration
    if [[ "$REMOVE_COMMENTS" == "true" ]]; then
        # Remove comments - this is a simplified version
        content=$(echo "$content" | sed 's/\/\/.*$//g')  # Remove // comments
        content=$(echo "$content" | sed 's/#.*$//g')     # Remove # comments
    fi
    
    if [[ "$REMOVE_EMPTY_LINES" == "true" ]]; then
        # Remove empty lines or lines with only whitespace
        content=$(echo "$content" | sed '/^[[:space:]]*$/d')
    fi
    
    if [[ "$REMOVE_IMPORTS" == "true" ]]; then
        # Remove import statements (simplified)
        content=$(echo "$content" | sed '/^import /d')  # Remove Python imports
        content=$(echo "$content" | sed '/^from /d')    # Remove Python from imports
        content=$(echo "$content" | sed '/^require(/d') # Remove JS requires
        content=$(echo "$content" | sed '/^import(/d')  # Remove JS imports
    fi
    
    # Output the cleaned content
    echo "$content"
}

# Check if a file appears to be binary
function is_binary_file() {
    local file="$1"
    
    # Try file command if available
    if command -v file &>/dev/null; then
        local file_type=$(file -b "$file")
        if [[ "$file_type" == *"executable"* || "$file_type" == *"binary"* ]]; then
            return 0  # Binary
        fi
    fi
    
    # Check if the file contains null bytes (simple binary check)
    if grep -q $'\x00' "$file" 2>/dev/null; then
        return 0  # Binary
    fi
    
    # Check file extension
    local ext="${file##*.}"
    case "$ext" in
        jpg|jpeg|png|gif|bmp|ico|webp|tiff|pdf|doc|docx|xls|xlsx|exe|dll|so|dylib|zip|gz|tar|bin)
            return 0  # Binary
            ;;
    esac
    
    return 1  # Not binary
}

# Count tokens in a piece of text (approximate)
function count_tokens() {
    local text="$1"
    
    # Simple approximation: count words
    local words=$(echo "$text" | wc -w | tr -d ' ')
    
    echo "$words"
}