#!/bin/bash
# CodeSight visualization commands

# Source the core modules
if [[ -f "$SCRIPT_DIR/src/utils/collector/file_collector.sh" ]]; then
    source "$SCRIPT_DIR/src/utils/collector/file_collector.sh"
else
    echo "⚠️ Warning: File collector module not found!" >&2
fi

# Source the visualization submodules
source "$SCRIPT_DIR/src/commands/visualize/files.sh"
source "$SCRIPT_DIR/src/commands/visualize/tokens.sh"

# Help function for visualize command
function show_visualize_help() {
    echo "CodeSight Visualization Commands"
    echo "-------------------------------"
    echo "Usage: codesight visualize [type] [options]"
    echo ""
    echo "Types:"
    echo "  files      - Show largest files by line count"
    echo "  tokens     - Show top files by token count with optimization stats"
    echo "  extensions - Show file counts by extension type"
    echo "  languages  - Show language distribution"
    echo ""
    echo "Options:"
    echo "  --limit N  - Show top N results (default: 10)"
    echo "  --dir DIR  - Analyze specific directory (default: current dir)"
    echo ""
    echo "Examples:"
    echo "  codesight visualize files --limit 20"
    echo "  codesight visualize tokens --dir ./src"
}

# Main visualization command handler
function visualize_command() {
    local viz_type=""
    local limit=10
    local directory="$CURRENT_DIR"
    
    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_visualize_help
                return 0
                ;;
            --limit)
                shift
                limit="$1"
                ;;
            --dir)
                shift
                directory="$1"
                ;;
            --*)
                echo "❌ Unknown option: $1"
                show_visualize_help
                return 1
                ;;
            *)
                if [[ -z "$viz_type" ]]; then
                    viz_type="$1"
                else
                    echo "❌ Unknown argument: $1"
                    show_visualize_help
                    return 1
                fi
                ;;
        esac
        shift
    done
    
    # Default to files if no type provided
    if [[ -z "$viz_type" ]]; then
        viz_type="files"
    fi
    
    # Run the appropriate visualization
    case "$viz_type" in
        files)
            display_largest_files "$directory" "$limit" "$FILE_EXTENSIONS"
            ;;
        tokens)
            if [[ -n "$(declare -F collect_files)" ]]; then
                # First collect files using the standard collector
                local files=()
                echo "📂 Collecting files for token analysis..."
                collect_files "$directory" "$FILE_EXTENSIONS" "100" "$MAX_FILE_SIZE" "$RESPECT_GITIGNORE" "files"
                
                # Then display stats using collected files
                if [[ ${#files[@]} -gt 0 ]]; then
                    display_token_stats "$directory" "$limit" "$CURRENT_DIR/codesight.txt" "${files[@]}"
                else
                    display_token_stats "$directory" "$limit"
                fi
            else
                # Fallback to simple implementation
                display_token_stats "$directory" "$limit"
            fi
            ;;
        extensions)
            echo "📊 Visualizing files by extension type..."
            echo "   (Not implemented yet)"
            ;;
        languages)
            echo "📊 Visualizing language distribution..."
            echo "   (Not implemented yet)"
            ;;
        *)
            echo "❌ Unknown visualization type: $viz_type"
            show_visualize_help
            return 1
            ;;
    esac
}