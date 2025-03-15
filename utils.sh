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

# Clean content to reduce token usage - configurable token reduction
clean_content() {
    # Process input to reduce token usage but preserve key information based on configuration:
    # - Remove trailing whitespace and normalize line endings (always done)
    # - Remove comments (C, C++, Python, Bash) if REMOVE_COMMENTS=true
    # - Remove empty lines if REMOVE_EMPTY_LINES=true
    # - Collapse multiple spaces to single space (always done)
    # - Remove common import/require statements if REMOVE_IMPORTS=true
    
    # Start with basic cleaning (always performed)
    local SED_SCRIPT="s/[ \t]*$// ; s/  */ /g"
    
    # Add comment removal if configured
    if [[ "$REMOVE_COMMENTS" == "true" ]]; then
        SED_SCRIPT="$SED_SCRIPT ; s/\/\*[^*]*\*\+([^/*][^*]*\*\+)*\/// ; s/\/\/.*$// ; s/^#[^!].*$//"
    fi
    
    # Add empty line removal if configured
    if [[ "$REMOVE_EMPTY_LINES" == "true" ]]; then
        SED_SCRIPT="$SED_SCRIPT ; /^\s*$/d"
    fi
    
    # Add import/require removal if configured
    if [[ "$REMOVE_IMPORTS" == "true" ]]; then
        SED_SCRIPT="$SED_SCRIPT ; /^\s*import /d ; /^\s*from .* import/d ; /^\s*require(/d ; /^\s*@/d"
    fi
    
    # Apply all configured cleaning operations
    sed -e "$SED_SCRIPT"
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