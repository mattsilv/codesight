#!/bin/bash
# Utility functions for CodeSight

# Check if a file is binary
is_binary_file() {
    local file="$1"
    
    # Use file command to check if binary
    if file -b "$file" | grep -q text; then
        # Text file
        return 1
    else
        # Binary file
        return 0
    fi
}

# Clean content to reduce token usage
clean_content() {
    # Read from stdin and clean content
    
    # Remove C-style comments
    sed -e 's/\/\*[^*]*\*\+([^/*][^*]*\*\+)*\///' |
    
    # Remove C++ style comments
    sed -e 's/\/\/.*$//' |
    
    # Remove Python/shell comments
    sed -e 's/#.*$//' |
    
    # Remove trailing whitespace
    sed -e 's/[ \t]*$//' |
    
    # Collapse multiple empty lines into one
    sed -e '/^$/N;/^\n$/D' |
    
    # Remove import statements
    sed -e '/^\s*import /d' |
    sed -e '/^\s*from .* import/d' |
    sed -e '/^\s*require(/d' |
    
    # Remove decorators
    sed -e '/^\s*@/d' |
    
    # Final trim
    sed -e '/./,$!d' -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

# Calculate approximate token count
# This is a simple approximation - word count plus punctuation
count_tokens() {
    local text="$1"
    
    # Count words
    local words=$(echo "$text" | wc -w)
    
    # Count special characters and punctuation (rough approximation)
    local special_chars=$(echo "$text" | grep -o '[[:punct:]]' | wc -l)
    
    # Return approximate token count
    echo $((words + special_chars))
}

# Format a file size in human-readable format
format_size() {
    local bytes="$1"
    
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$((bytes / 1024))KB"
    else
        echo "$((bytes / 1048576))MB"
    fi
}

# Format a relative time (time ago)
format_time_ago() {
    local timestamp="$1"
    local now=$(date +%s)
    local diff=$((now - timestamp))
    
    if [[ $diff -lt 60 ]]; then
        echo "just now"
    elif [[ $diff -lt 3600 ]]; then
        local minutes=$((diff / 60))
        if [[ $minutes -eq 1 ]]; then
            echo "1 minute ago"
        else
            echo "$minutes minutes ago"
        fi
    elif [[ $diff -lt 86400 ]]; then
        local hours=$((diff / 3600))
        if [[ $hours -eq 1 ]]; then
            echo "1 hour ago"
        else
            echo "$hours hours ago"
        fi
    else
        local days=$((diff / 86400))
        if [[ $days -eq 1 ]]; then
            echo "1 day ago"
        else
            echo "$days days ago"
        fi
    fi
}

# Check if a path should be excluded based on patterns
should_exclude() {
    local path="$1"
    local filename=$(basename "$path")
    
    # Check excluded files
    for pattern in "${EXCLUDED_FILES[@]}"; do
        if [[ "$filename" == $pattern ]]; then
            return 0
        fi
    done
    
    # Check excluded folders
    for folder in "${EXCLUDED_FOLDERS[@]}"; do
        if [[ "$path" == *"$folder"* ]]; then
            return 0
        fi
    done
    
    # Not excluded
    return 1
}

# Convert file extension to language name (for code blocks)
extension_to_language() {
    local ext="$1"
    
    case "$ext" in
        .py)
            echo "python"
            ;;
        .js)
            echo "javascript"
            ;;
        .jsx)
            echo "jsx"
            ;;
        .ts)
            echo "typescript"
            ;;
        .tsx)
            echo "tsx"
            ;;
        .html)
            echo "html"
            ;;
        .css)
            echo "css"
            ;;
        .scss)
            echo "scss"
            ;;
        .json)
            echo "json"
            ;;
        .md)
            echo "markdown"
            ;;
        .sh)
            echo "bash"
            ;;
        .yml|.yaml)
            echo "yaml"
            ;;
        .rb)
            echo "ruby"
            ;;
        .java)
            echo "java"
            ;;
        .php)
            echo "php"
            ;;
        .go)
            echo "go"
            ;;
        .rs)
            echo "rust"
            ;;
        .cs)
            echo "csharp"
            ;;
        .cpp|.cc|.cxx)
            echo "cpp"
            ;;
        .c)
            echo "c"
            ;;
        .h|.hpp)
            echo "cpp"
            ;;
        *)
            echo "text"
            ;;
    esac
}