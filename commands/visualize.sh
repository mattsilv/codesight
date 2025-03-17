#!/bin/bash
# Visualize command functionality

function visualize_command() {
    local visualize_type="files"
    local directory="$CURRENT_DIR"
    local limit=10
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            files|tokens|extensions|languages)
                visualize_type="$1"
                shift
                ;;
            --limit|-n)
                limit="$2"
                shift 2
                ;;
            --directory|-d)
                directory="$2"
                shift 2
                ;;
            *)
                # If it's not an option, assume it's the directory
                if [[ ! "$1" == -* ]]; then
                    directory="$1"
                    shift
                else
                    echo "❌ Unknown option: $1"
                    show_visualize_help
                    return 1
                fi
                ;;
        esac
    done
    
    # Ensure directory exists
    if [[ ! -d "$directory" ]]; then
        echo "❌ Error: Directory '$directory' does not exist."
        return 1
    fi
    
    # Load config if it exists
    if [[ -f "$CURRENT_DIR/.codesight/config" ]]; then
        source "$CURRENT_DIR/.codesight/config"
    fi
    
    # Based on visualize type, call appropriate function
    case "$visualize_type" in
        files)
            display_largest_files "$directory" "$limit" "$FILE_EXTENSIONS"
            ;;
        tokens)
            # Source token_stats.sh and display token statistics
            source "$SCRIPT_DIR/utils/visualize/token_stats.sh"
            display_token_stats "$directory" "$limit"
            ;;
        extensions)
            echo "Extension visualization not implemented yet."
            ;;
        languages)
            echo "Language visualization not implemented yet."
            ;;
        *)
            echo "❌ Unknown visualization type: $visualize_type"
            show_visualize_help
            return 1
            ;;
    esac
}

function show_visualize_help() {
    echo "CodeSight Visualize Command"
    echo "Usage: codesight visualize [type] [options]"
    echo ""
    echo "Types:"
    echo "  files        Show largest files by line count (default)"
    echo "  tokens       Show files with highest token counts and optimization potential"
    echo "  extensions   Show distribution of file extensions (coming soon)"
    echo "  languages    Show programming language distribution (coming soon)"
    echo ""
    echo "Options:"
    echo "  --limit, -n N   Limit results to N items (default: 10)"
    echo "  --directory, -d DIR   Analyze files in DIR (default: current directory)"
    echo ""
    echo "Examples:"
    echo "  codesight visualize files"
    echo "  codesight visualize tokens --limit 5"
    echo "  codesight visualize files --limit 15"
    echo "  codesight visualize files --directory ./src"
}