#!/bin/bash
# Info command functionality

function show_info() {
    if [[ ! -d "$CURRENT_DIR/.codesight" ]]; then
        echo "❌ Error: CodeSight not initialized in this directory."
        echo "   Run '$SCRIPT_DIR/codesight.sh init' first."
        return 1
    fi
    
    echo "CodeSight Project Information"
    echo "----------------------------"
    echo "Working directory: $CURRENT_DIR"
    
    if [[ -f "$CURRENT_DIR/.codesight/config" ]]; then
        echo "Configuration:"
        grep -v "^#" "$CURRENT_DIR/.codesight/config" | grep -v "^$" | sed 's/^/  /'
        
        echo ""
        echo "File Selection Settings:"
        echo "  RESPECT_GITIGNORE: ${RESPECT_GITIGNORE:-true}"
        
        echo ""
        echo "Token Optimization Settings:"
        echo "  ENABLE_ULTRA_COMPACT_FORMAT: ${ENABLE_ULTRA_COMPACT_FORMAT:-false}"
        echo "  REMOVE_COMMENTS: ${REMOVE_COMMENTS:-true}"
        echo "  REMOVE_EMPTY_LINES: ${REMOVE_EMPTY_LINES:-true}"
        echo "  REMOVE_IMPORTS: ${REMOVE_IMPORTS:-false}"
        echo "  ABBREVIATE_HEADERS: ${ABBREVIATE_HEADERS:-false}"
        echo "  TRUNCATE_PATHS: ${TRUNCATE_PATHS:-false}"
        echo "  MINIMIZE_METADATA: ${MINIMIZE_METADATA:-false}"
        echo "  SHORT_DATE_FORMAT: ${SHORT_DATE_FORMAT:-true}"
    else
        echo "  No configuration file found"
    fi
    
    # Check for both possible output file locations
    if [[ -f "$CURRENT_DIR/codesight.txt" ]]; then
        local overview_size=$(du -h "$CURRENT_DIR/codesight.txt" | cut -f1)
        local overview_lines=$(wc -l < "$CURRENT_DIR/codesight.txt")
        local overview_date=$(date -r "$CURRENT_DIR/codesight.txt" "+%Y-%m-%d %H:%M:%S")
        
        echo ""
        echo "Last Analysis:"
        echo "  File: codesight.txt"
        echo "  Size: $overview_size"
        echo "  Lines: $overview_lines"
        echo "  Date: $overview_date"
    elif [[ -f "$CURRENT_DIR/.codesight/codebase_overview.txt" ]]; then
        local overview_size=$(du -h "$CURRENT_DIR/.codesight/codebase_overview.txt" | cut -f1)
        local overview_lines=$(wc -l < "$CURRENT_DIR/.codesight/codebase_overview.txt")
        local overview_date=$(date -r "$CURRENT_DIR/.codesight/codebase_overview.txt" "+%Y-%m-%d %H:%M:%S")
        
        echo ""
        echo "Last Analysis:"
        echo "  File: .codesight/codebase_overview.txt"
        echo "  Size: $overview_size"
        echo "  Lines: $overview_lines"
        echo "  Date: $overview_date"
    fi
} 