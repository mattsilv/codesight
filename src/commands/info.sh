#!/bin/bash
# CodeSight info command
# Displays information about the current configuration

function show_info() {
    echo "🔍 CodeSight Configuration Information"
    echo "----------------------------------------"
    
    # Show version
    echo "Version: $VERSION"
    echo ""
    
    # Check if initialized
    if [[ ! -d "$CURRENT_DIR/.codesight" ]]; then
        echo "❌ Not initialized in this directory."
        echo "   Run 'codesight init' to initialize."
        return 1
    fi
    
    # Load project config if exists
    if [[ -f "$CURRENT_DIR/.codesight/config" ]]; then
        source "$CURRENT_DIR/.codesight/config"
        echo "✅ Configuration file found"
        echo "   Location: $CURRENT_DIR/.codesight/config"
        echo ""
    else
        echo "⚠️ No configuration file found"
        echo "   Using default settings"
        echo ""
    fi
    
    # Show current settings
    echo "Current Configuration:"
    echo "----------------------"
    echo "File Extensions: $FILE_EXTENSIONS"
    echo "Max Lines Per File: $MAX_LINES_PER_FILE"
    echo "Max Files: $MAX_FILES"
    echo "Max File Size: $MAX_FILE_SIZE bytes"
    echo "Respect .gitignore: $RESPECT_GITIGNORE"
    echo ""
    
    # Show excluded patterns
    echo "Excluded Patterns:"
    echo "-----------------"
    echo "Excluded Files:"
    for file in "${EXCLUDED_FILES[@]}"; do
        echo "   - $file"
    done
    echo ""
    
    echo "Excluded Folders:"
    for folder in "${EXCLUDED_FOLDERS[@]}"; do
        echo "   - $folder"
    done
    echo ""
    
    # Show token optimization settings
    echo "Token Optimization Settings:"
    echo "---------------------------"
    echo "Ultra-Compact Format: ${ENABLE_ULTRA_COMPACT_FORMAT:-false}"
    echo "Remove Comments: ${REMOVE_COMMENTS:-true}"
    echo "Remove Empty Lines: ${REMOVE_EMPTY_LINES:-true}"
    echo "Remove Imports: ${REMOVE_IMPORTS:-false}"
    echo "Abbreviate Headers: ${ABBREVIATE_HEADERS:-false}"
    echo "Truncate Paths: ${TRUNCATE_PATHS:-false}"
    echo "Minimize Metadata: ${MINIMIZE_METADATA:-false}"
    echo "Short Date Format: ${SHORT_DATE_FORMAT:-true}"
    
    echo ""
    echo "To modify settings, edit $CURRENT_DIR/.codesight/config"
}