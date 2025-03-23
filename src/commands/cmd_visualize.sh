#!/bin/bash
# CodeSight visualize command - main entry point

# Main visualize command wrapper
function visualize_command() {
    # Load the visualize module if not already loaded
    if ! command -v visualize_command_impl &>/dev/null; then
        source "$SCRIPT_DIR/src/commands/visualize.sh" || {
            echo -e "\033[31m❌ Error: Could not load visualize module\033[0m"
            return 1
        }
    fi
    
    # Call the module implementation
    visualize_command_impl "$@"
}

# Rename the implementation function to avoid conflict
function visualize_command_impl() {
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
            display_token_stats "$directory" "$limit"
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