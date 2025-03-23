#!/bin/bash
# CodeSight visualization utility

# Function to display token statistics
function display_token_stats() {
    # Initialize function parameters
    
    local directory="${1:-$PWD}"
    # Ensure directory is valid, fallback to current directory
    if [[ ! -d "$directory" ]]; then
        echo "❌ Directory not found: $directory" >&2
        echo "   Using current directory instead." >&2
        directory="$PWD"
    fi
    
    # IMPORTANT: This controls how many files to display - default is now 10
    local limit="${2:-10}"
    # Ensure limit is a number, fallback to 10
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid limit: $limit" >&2
        echo "   Using default limit of 10 instead." >&2
        limit=10
    fi
    
    local output_file="${3:-$CURRENT_DIR/codesight.txt}"
    # Shift to get provided files
    shift 3
    local provided_files=("$@")
    
    # Ensure file collector utility is loaded
    if [[ -f "$SCRIPT_DIR/src/utils/collector/file_collector.sh" ]] && [[ -z "$(declare -F collect_files)" ]]; then
        source "$SCRIPT_DIR/src/utils/collector/file_collector.sh"
    fi
    
    # We'll just use directory instead of additional files for the simplified implementation
    local files=()
    
    # Files need to be analyzed individually through the CodeSight process
    local temp_dir="/tmp/codesight_token_analysis"
    mkdir -p "$temp_dir" || { echo "Error: Failed to create temp directory"; return 1; }
    
    # Make sure temp dir is empty
    rm -f "$temp_dir"/* 2>/dev/null
    
    # Use provided files if available, otherwise find them
    if [[ ${#provided_files[@]} -gt 0 ]]; then
        files=("${provided_files[@]}")
    else
        # Try to use collect_files function if it's available (imported from analyzer.sh)
        if [[ -n "$(declare -F collect_files)" ]]; then
            # Use the standard file collection method
            collect_files "$directory" ".sh" "10" "1000000" "true" "files"
        else
            # Fallback to a simple find command
            if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                echo "   Finding files to analyze using simple find..." >&2
            fi
            
            # Simple find command to get shell scripts
            while IFS= read -r file; do
                # Skip files that are too large or don't exist
                if [[ ! -f "$file" || $(wc -c < "$file" 2>/dev/null || echo 1000000) -gt 100000 ]]; then
                    continue
                fi
                files+=("$file")
            done < <(find "$directory" -type f -name "*.sh" -not -path "*/\.*" | sort)
        fi
    fi
    
    # Process each file to calculate raw and optimized tokens
    declare -a file_stats=()
    
    for file in "${files[@]}"; do
        local rel_path="${file#$PWD/}"
        # If still absolute path, just use the file name
        if [[ "$rel_path" == /* ]]; then
            rel_path=$(basename "$file")
        fi
        
        # Get file content
        if [[ ! -f "$file" ]]; then
            echo "❌ File not found: $file" >&2
            continue
        fi
        local file_lines=$(wc -l < "$file")
        local content=$(cat "$file")
        
        # Get raw token count (approximate)
        local raw_tokens=$(count_tokens "$content")
        
        # Get optimized token count
        local cleaned_content=$(echo "$content" | clean_content)
        local optimized_tokens=$(count_tokens "$cleaned_content")
        
        # Calculate savings percentage
        local token_savings=0
        if command -v bc &>/dev/null && [[ $raw_tokens -gt 0 ]]; then
            token_savings=$(echo "scale=1; ($raw_tokens - $optimized_tokens) * 100 / $raw_tokens" | bc)
        elif [[ $raw_tokens -gt 0 ]]; then
            token_savings=$(( (raw_tokens - optimized_tokens) * 100 / raw_tokens ))
        fi
        
        # Store stats: file|raw_tokens|optimized_tokens|savings|lines
        file_stats+=("$rel_path|$raw_tokens|$optimized_tokens|$token_savings|$file_lines")
    done
    
    # Create a temp file for sorting only if we have file stats
    local sorted_stats=()
    if [[ ${#file_stats[@]} -gt 0 ]]; then
        local tmp_sort_file="$temp_dir/file_stats.txt"
        # Make sure the temp file exists and is empty
        > "$tmp_sort_file"
        
        if [[ -n "$CODESIGHT_VERBOSE" ]]; then
            echo "   Sorting files by token count..." >&2
        fi
        
        # Write stats to temp file
        for stat in "${file_stats[@]}"; do
            echo "$stat" >> "$tmp_sort_file"
        done
        
        # Sort by raw token count (highest first)
        while IFS= read -r line; do
            sorted_stats+=("$line")
        done < <(sort -t '|' -k2,2nr "$tmp_sort_file")
    fi
    
    # Take top N results (limited by actual results available)
    local display_limit=$((limit<${#sorted_stats[@]}?limit:${#sorted_stats[@]}))
    local top_stats=()
    if [[ $display_limit -gt 0 ]]; then
        top_stats=("${sorted_stats[@]:0:$display_limit}")
    fi
    
    # Display the table with improved formatting
    echo ""
    echo "🔤 Top $limit files by token count:"
    
    # ===== TABLE FORMATTING - DO NOT MODIFY UNLESS YOU'RE FIXING ALIGNMENT ISSUES =====
    # Calculate column widths based on content and terminal size
    local terminal_width=80
    if command -v tput &>/dev/null; then
        terminal_width=$(tput cols 2>/dev/null || echo 80)
    fi
    
    # Set default column widths - MODIFY THESE VALUES IF YOU NEED TO ADJUST COLUMN WIDTHS
    local path_width=40  # Width for file paths
    local raw_width=10   # Width for raw token counts
    local opt_width=10   # Width for optimized token counts
    local savings_width=10  # Width for savings percentage
    local lines_width=7   # Width for line counts
    
    # Find max path width if we have data
    if [[ ${#top_stats[@]} -gt 0 ]]; then
        local max_path_width=0
        for stat in "${top_stats[@]}"; do
            IFS='|' read -r file_path _ _ _ _ <<< "$stat"
            if [[ ${#file_path} -gt $max_path_width ]]; then
                max_path_width=${#file_path}
            fi
        done
        
        # Adjust path width but don't exceed terminal width
        path_width=$((max_path_width < 40 ? 40 : max_path_width))
        
        # Total width including borders = path + raw + opt + savings + lines + borders
        local total_width=$((path_width + raw_width + opt_width + savings_width + lines_width + 14))
        
        # If too wide for terminal, reduce path width
        if [[ $total_width -gt $terminal_width ]]; then
            path_width=$((path_width - (total_width - terminal_width) - 2))
            # Ensure minimum width
            path_width=$((path_width < 20 ? 20 : path_width))
        fi
    fi
    
    # Build dynamic table borders - ensure exact column width matches
    # DO NOT modify the format of these lines - they ensure proper table borders
    local path_dashes=$(printf '%*s' $path_width '' | tr ' ' '─')
    local raw_dashes=$(printf '%*s' $raw_width '' | tr ' ' '─')
    local opt_dashes=$(printf '%*s' $opt_width '' | tr ' ' '─')
    local savings_dashes=$(printf '%*s' $savings_width '' | tr ' ' '─')
    local lines_dashes=$(printf '%*s' $lines_width '' | tr ' ' '─')
    
    # CRITICAL - DO NOT CHANGE THESE BOX DRAWING CHARACTERS - THEY ENSURE PROPER TABLE FORMATTING
    # Construct table borders with precise widths
    local top_border="┌─${path_dashes}─┬─${raw_dashes}─┬─${opt_dashes}─┬─${savings_dashes}─┬─${lines_dashes}─┐"
    local header_sep="├─${path_dashes}─┼─${raw_dashes}─┼─${opt_dashes}─┼─${savings_dashes}─┼─${lines_dashes}─┤"
    local bottom_border="└─${path_dashes}─┴─${raw_dashes}─┴─${opt_dashes}─┴─${savings_dashes}─┴─${lines_dashes}─┘"
    
    # Create header with proper spacing - ensures proper column header alignment
    local header=$(printf "│ %-${path_width}s │ %-${raw_width}s │ %-${opt_width}s │ %-${savings_width}s │ %${lines_width}s │" "File Path" "Raw" "Optimized" "Savings" "Lines")
    
    # Print table header
    echo "$top_border"
    echo "$header"
    echo "$header_sep"
    
    if [[ ${#top_stats[@]} -eq 0 ]]; then
        # No files found, display empty table with consistent column widths
        printf "│ %-${path_width}s │ %-${raw_width}s │ %-${opt_width}s │ %-${savings_width}s │ %${lines_width}s │\n" \
            "No files found" "" "" "" ""
    else
        for stat in "${top_stats[@]}"; do
            IFS='|' read -r file_path raw_tokens opt_tokens savings lines <<< "$stat"
            
            # Truncate long paths if needed, but keep filename and parent folder intact
            if [[ ${#file_path} -gt $path_width ]]; then
                # Get the filename and its parent folder
                local filename=$(basename "$file_path")
                local parent_dir=$(dirname "$file_path")
                local parent_name=$(basename "$parent_dir")
                
                # If file is in root (no parent), just show filename
                if [[ "$parent_name" == "." ]]; then
                    file_path="$filename"
                else
                    # Show parent/filename format
                    local combined="$parent_name/$filename"
                    
                    # If combined still too long, just show filename
                    if [[ ${#combined} -gt $path_width ]]; then
                        file_path="$filename"
                    else
                        file_path="$combined"
                    fi
                    
                    # Add ellipsis if we truncated the path
                    if [[ "$combined" != "$file_path" || "$parent_dir" != "$parent_name" ]]; then
                        file_path=".../$file_path"
                    fi
                fi
            fi
            
            # Format the savings value (with % symbol)
            local savings_formatted="$(printf "%.1f%%" "$savings")"
            local savings_color="\033[32m" # Green
            local reset_color="\033[0m"
            
            # IMPORTANT: These printf statements format each row in the table - DO NOT CHANGE FORMAT SPECIFIERS
            # Format and display the row with precise width control
            if [[ -t 1 ]]; then # Check if output is terminal
                # Use color for terminal output - note the %d format for numbers
                printf "│ %-${path_width}s │ %${raw_width}d │ %${opt_width}d │ ${savings_color}%-${savings_width}s${reset_color} │ %${lines_width}d │\n" \
                    "$file_path" "$raw_tokens" "$opt_tokens" "$savings_formatted" "$lines"
            else
                # No color for non-terminal output - note the %d format for numbers
                printf "│ %-${path_width}s │ %${raw_width}d │ %${opt_width}d │ %-${savings_width}s │ %${lines_width}d │\n" \
                    "$file_path" "$raw_tokens" "$opt_tokens" "$savings_formatted" "$lines"
            fi
        done
        
        # Calculate totals for the displayed files
        local total_raw=0
        local total_opt=0
        local total_lines=0
        
        for stat in "${top_stats[@]}"; do
            IFS='|' read -r _ raw_tokens opt_tokens _ lines <<< "$stat"
            ((total_raw += raw_tokens))
            ((total_opt += opt_tokens))
            ((total_lines += lines))
        done
        
        # Calculate total savings percentage
        local total_savings=0
        if command -v bc &>/dev/null && [[ $total_raw -gt 0 ]]; then
            total_savings=$(echo "scale=1; ($total_raw - $total_opt) * 100 / $total_raw" | bc)
        elif [[ $total_raw -gt 0 ]]; then
            total_savings=$(( (total_raw - total_opt) * 100 / total_raw ))
        fi
        
        # Format total savings with % symbol
        local total_savings_formatted="$(printf "%.1f%%" "$total_savings")"
        
        # Print separator row with proper width - DO NOT MODIFY THIS LINE
        echo "├─${path_dashes}─┼─${raw_dashes}─┼─${opt_dashes}─┼─${savings_dashes}─┼─${lines_dashes}─┤"
        
        # CRITICAL: Format for totals row - DO NOT CHANGE THE FORMAT SPECIFIERS
        # Add total row with bold formatting if in terminal
        if [[ -t 1 ]]; then
            local bold="\033[1m"
            local reset="\033[0m"
            printf "│ ${bold}%-${path_width}s${reset} │ ${bold}%${raw_width}d${reset} │ ${bold}%${opt_width}d${reset} │ ${bold}%-${savings_width}s${reset} │ ${bold}%${lines_width}d${reset} │\n" \
                "TOTAL (${#top_stats[@]} files)" "$total_raw" "$total_opt" "$total_savings_formatted" "$total_lines"
        else
            printf "│ %-${path_width}s │ %${raw_width}d │ %${opt_width}d │ %-${savings_width}s │ %${lines_width}d │\n" \
                "TOTAL (${#top_stats[@]} files)" "$total_raw" "$total_opt" "$total_savings_formatted" "$total_lines"
        fi
    fi
    
    # Print table bottom border - DO NOT MODIFY
    echo "$bottom_border"
    
    # Add note about potential savings
    echo "   💡 Files with high token counts may benefit from refactoring or exclusion."
    if [[ ${#top_stats[@]} -gt 0 ]]; then
        echo "   📊 Total estimated tokens: $(printf "%'d" $total_opt) optimized from $(printf "%'d" $total_raw) raw tokens."
    fi
    
    # Clean up
    if [[ -d "$temp_dir" ]]; then
        rm -rf "$temp_dir"
    fi
}

# Function to get token stats without displaying a table
function get_token_stats() {
    local provided_files=($@)
    local temp_dir="/tmp/codesight_token_analysis"
    mkdir -p "$temp_dir" || { echo "Error: Failed to create temp directory"; return 1; }
    
    # Process each file to calculate raw and optimized tokens
    declare -a file_stats=()
    local total_raw=0
    local total_opt=0
    local total_lines=0
    
    for file in "${provided_files[@]}"; do
        local rel_path="${file#$PWD/}"
        # If still absolute path, just use the file name
        if [[ "$rel_path" == /* ]]; then
            rel_path=$(basename "$file")
        fi
        
        # Get file content
        if [[ ! -f "$file" ]]; then
            continue
        fi
        local file_lines=$(wc -l < "$file")
        local content=$(cat "$file")
        
        # Get raw token count (approximate)
        local raw_tokens=$(count_tokens "$content")
        
        # Get optimized token count
        local cleaned_content=$(echo "$content" | clean_content)
        local optimized_tokens=$(count_tokens "$cleaned_content")
        
        # Calculate savings percentage
        local token_savings=0
        if command -v bc &>/dev/null && [[ $raw_tokens -gt 0 ]]; then
            token_savings=$(echo "scale=1; ($raw_tokens - $optimized_tokens) * 100 / $raw_tokens" | bc)
        elif [[ $raw_tokens -gt 0 ]]; then
            token_savings=$(( (raw_tokens - optimized_tokens) * 100 / raw_tokens ))
        fi
        
        # Add to totals
        ((total_raw += raw_tokens))
        ((total_opt += optimized_tokens))
        ((total_lines += file_lines))
    done
    
    # Calculate total savings percentage
    local total_savings=0
    if command -v bc &>/dev/null && [[ $total_raw -gt 0 ]]; then
        total_savings=$(echo "scale=1; ($total_raw - $total_opt) * 100 / $total_raw" | bc)
    elif [[ $total_raw -gt 0 ]]; then
        total_savings=$(( (total_raw - total_opt) * 100 / total_raw ))
    fi
    
    # Return stats: files|raw_tokens|optimized_tokens|savings|lines
    echo "${#provided_files[@]}|$total_raw|$total_opt|$total_savings|$total_lines"
    
    # Clean up
    if [[ -d "$temp_dir" ]]; then
        rm -rf "$temp_dir"
    fi
}