#!/bin/bash
# Main analysis functionality for CodeSight analyze command

# Main analysis function
function analyze_codebase_modular() {
    # Load project config if exists first
    if [[ -f "$CURRENT_DIR/.codesight/config" ]]; then
        source "$CURRENT_DIR/.codesight/config"
    fi
    
    # Initialize variables with config values
    local directory="$CURRENT_DIR"
    local output_file="$CURRENT_DIR/.codesight/codesight.txt"
    local extensions="$FILE_EXTENSIONS"
    local max_lines=$MAX_LINES_PER_FILE
    local max_files=$MAX_FILES
    local max_size=$MAX_FILE_SIZE
    local OUTPUT_FILE_SPECIFIED=false
    local COPY_TO_CLIPBOARD=false
    
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
            -c|--clipboard)
                COPY_TO_CLIPBOARD=true
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
        echo "   Run 'codesight init' first."
        return 1
    fi
    
    # Create output directory
    mkdir -p "$(dirname "$output_file")"
    
    # Only show detailed output in verbose mode
    if [[ -n "$CODESIGHT_VERBOSE" ]]; then
        echo "🔍 Analyzing codebase in '$directory'..."
        echo "   Extensions: $extensions"
        echo "   Max lines: $max_lines, Max files: $max_files"
    else
        echo "Analyzing..."
    fi
    
    # Step 1: Collect files matching criteria
    if [[ -n "$CODESIGHT_VERBOSE" ]]; then
        echo "   Debug: Setting up files array" >&2
    fi
    files=()
    
    # Simple workaround - populate array directly
    if [[ "$extensions" == ".sh" ]]; then
        files=($(find "$directory" -type f -name "*.sh" -not -path "*/\.git/*" -not -path "*/node_modules/*"))
    else
        # The original collection logic doesn't work, so we need this workaround
        # Split extensions and build the find command
        IFS=' ' read -ra ext_array <<< "$extensions"
        find_args=()
        for ext in "${ext_array[@]}"; do
            if [[ "$ext" == .* ]]; then
                find_args+=("*$ext")
            else
                find_args+=("*.$ext")
            fi
        done
        
        # Build the find command dynamically
        for pattern in "${find_args[@]}"; do
            temp_files=($(find "$directory" -type f -name "$pattern" -not -path "*/\.git/*" -not -path "*/node_modules/*"))
            files+=("${temp_files[@]}")
        done
    fi
    
    if [[ -n "$CODESIGHT_VERBOSE" ]]; then
        echo "   Debug: After collection, files array size: ${#files[@]}" >&2
    fi
    
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
    if [[ ${#files[@]} -gt 0 ]]; then
        # Only show stats if we have files
        source "$SCRIPT_DIR/src/commands/visualize/tokens.sh"
        # Use our existing files array rather than finding files again
        display_token_stats "$directory" 5 "$output_file" "${files[@]}"
    else
        # Display empty table
        echo ""
        echo "🔤 Top 5 files by token count:"
        echo "┌─────────────────────────────────────────────┬───────────┬───────────┬──────────┬───────┐"
        echo "│ File Path                                   │ Raw       │ Optimized │ Savings  │ Lines │"
        echo "├─────────────────────────────────────────────┼───────────┼───────────┼──────────┼───────┤"
        echo "│ No files found                              │           │           │          │       │"
        echo "└─────────────────────────────────────────────┴───────────┴───────────┴──────────┴───────┘"
        echo "   💡 Files with high token counts may benefit from refactoring or exclusion."
    fi
    
    # Copy to clipboard only if flag is set
    if [[ "$COPY_TO_CLIPBOARD" == "true" ]]; then
        copy_to_clipboard "$output_file"
    fi
}