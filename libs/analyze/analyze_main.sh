#!/bin/bash
# Main analysis functionality for CodeSight analyze command

# Source dependencies
source "$SCRIPT_DIR/libs/analyze/file_collection.sh"
source "$SCRIPT_DIR/libs/analyze/file_processor.sh"
source "$SCRIPT_DIR/libs/analyze/output_formatter.sh"

# Main analysis function - refactored version of analyze_codebase
function analyze_codebase_modular() {
    local directory="$CURRENT_DIR"
    local output_file="$CURRENT_DIR/codesight.txt"
    local extensions="$FILE_EXTENSIONS"
    local max_lines=$MAX_LINES_PER_FILE
    local max_files=$MAX_FILES
    local max_size=$MAX_FILE_SIZE
    local OUTPUT_FILE_SPECIFIED=false
    
    # Parse arguments
    local use_gitignore=$RESPECT_GITIGNORE
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output)
                output_file="$2"
                OUTPUT_FILE_SPECIFIED=true
                shift 2
                ;;
            --extensions)
                extensions="$2"
                shift 2
                ;;
            --max-lines)
                max_lines="$2"
                shift 2
                ;;
            --max-files)
                max_files="$2"
                shift 2
                ;;
            --max-size)
                max_size="$2"
                shift 2
                ;;
            --gitignore)
                use_gitignore=true
                shift
                ;;
            --no-gitignore)
                use_gitignore=false
                shift
                ;;
            *)
                # Assume it's the directory
                if [[ ! "$1" == -* ]]; then
                    directory="$1"
                    shift
                else
                    echo "Unknown option: $1"
                    show_help
                    return 1
                fi
                ;;
        esac
    done
    
    # Check if initialized
    if [[ ! -d "$CURRENT_DIR/.codesight" ]]; then
        echo "❌ Error: CodeSight not initialized in this directory."
        echo "   Run '$SCRIPT_DIR/codesight.sh init' first."
        return 1
    fi
    
    # Load project config if exists
    if [[ -f "$CURRENT_DIR/.codesight/config" ]]; then
        source "$CURRENT_DIR/.codesight/config"
    fi
    
    # Create output directory
    mkdir -p "$(dirname "$output_file")"
    
    echo "🔍 Analyzing codebase in '$directory'..."
    echo "   Extensions: $extensions"
    echo "   Max lines: $max_lines, Max files: $max_files"
    
    # Step 1: Collect files matching criteria
    local files=()
    collect_files "$directory" "$extensions" "$max_files" "$max_size" "$use_gitignore" "files"
    
    # Check for updates if this is a standard analyze command (not a custom location)
    if [[ "$directory" == "$CURRENT_DIR" && -z "$OUTPUT_FILE_SPECIFIED" ]]; then
        check_for_updates
    fi
    
    # Step 2: Write header to output file
    write_header "$output_file" "${#files[@]}" "$extensions" "$ENABLE_ULTRA_COMPACT_FORMAT"
    
    # Step 3: Process files and get statistics
    local stats=$(process_files "files" "$max_lines" "$output_file" "$ENABLE_ULTRA_COMPACT_FORMAT" \
        "$ABBREVIATE_HEADERS" "$TRUNCATE_PATHS" "$SHORT_DATE_FORMAT")
    
    # Step 4: Write summary statistics to output file
    local summary_stats=$(write_summary "$output_file" "$stats" "$MINIMIZE_METADATA" "$ENABLE_ULTRA_COMPACT_FORMAT")
    
    # Parse summary stats
    IFS='|' read -r total_words char_savings line_savings <<< "$summary_stats"
    
    # Print summary to console
    echo "✅ Analysis complete!"
    echo "   Overview saved to: $output_file"
    echo "   Stats: ${#files[@]} files, $total_words tokens (saved ~$char_savings%)"
    
    # Display token statistics table if available
    if [[ -f "$SCRIPT_DIR/utils/visualize/token_stats.sh" ]]; then
        source "$SCRIPT_DIR/utils/visualize/token_stats.sh"
        display_token_stats "$directory" 5 "$output_file"
    fi
    
    # Copy to clipboard if possible
    copy_to_clipboard "$output_file"
}