#!/bin/bash
# CodeSight visualization utility
# Displays a report of the top files by token count with optimization details

function display_token_stats() {
    local directory="${1:-$PWD}"
    local limit="${2:-5}"
    local output_file="${3:-$CURRENT_DIR/codesight.txt}"
    
    echo "📊 Analyzing top $limit files by token count..."
    
    # Files need to be analyzed individually through the CodeSight process
    # We can't just count raw tokens like we do with lines
    local temp_dir="/tmp/codesight_token_analysis"
    mkdir -p "$temp_dir"
    
    # Use find to get files matching our extension criteria
    IFS=' ' read -ra ext_array <<< "$FILE_EXTENSIONS"
    find_cmd="find \"$directory\" -type f \\( -false"
    for ext in "${ext_array[@]}"; do
        find_cmd+=" -o -name \"*$ext\""
    done
    find_cmd+=" \\) | sort"
    
    # Add exclusion filters
    for folder in "${EXCLUDED_FOLDERS[@]}"; do
        find_cmd+=" | grep -v \"/$folder/\""
    done
    
    # Get files to analyze
    local files=()
    while IFS= read -r file; do
        # Skip excluded files and apply size limits
        local excluded=false
        for pattern in "${EXCLUDED_FILES[@]}"; do
            if [[ "$(basename "$file")" == $pattern ]]; then
                excluded=true
                break
            fi
        done
        
        # Skip if excluded
        if [[ "$excluded" == "true" ]]; then
            continue
        fi
        
        # Skip if too large
        if command -v stat &>/dev/null; then
            file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
        else
            file_size=$(wc -c < "$file" 2>/dev/null)
        fi
        
        if [[ -n "$file_size" ]] && [[ "$file_size" =~ ^[0-9]+$ ]] && [[ $file_size -gt $MAX_FILE_SIZE ]]; then
            continue
        fi
        
        # Skip binary files if configured
        if [[ "$SKIP_BINARY_FILES" == "true" ]] && is_binary_file "$file"; then
            continue
        fi
        
        files+=("$file")
    done < <(eval $find_cmd)
    
    echo "   Analyzing ${#files[@]} files for token statistics..."
    
    # Process each file to calculate raw and optimized tokens
    declare -a file_stats=()
    
    for file in "${files[@]}"; do
        local rel_path="${file#$PWD/}"
        # If still absolute path, just use the file name
        if [[ "$rel_path" == /* ]]; then
            rel_path=$(basename "$file")
        fi
        
        # Get file content
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
    
    # Create a temp file for sorting
    local tmp_sort_file="$temp_dir/file_stats.txt"
    for stat in "${file_stats[@]}"; do
        echo "$stat" >> "$tmp_sort_file"
    done
    
    # Sort by token count (highest first)
    local sorted_stats=()
    while IFS= read -r line; do
        sorted_stats+=("$line")
    done < <(sort -t '|' -k2 -nr "$tmp_sort_file")
    
    # Take top N results
    local top_stats=("${sorted_stats[@]:0:$limit}")
    
    # Display the table
    echo ""
    echo "🔤 Top $limit files by token count:"
    echo "┌─────────────────────────────────────────────┬───────────┬───────────┬──────────┬───────┐"
    echo "│ File Path                                   │ Raw       │ Optimized │ Savings  │ Lines │"
    echo "├─────────────────────────────────────────────┼───────────┼───────────┼──────────┼───────┤"
    
    for stat in "${top_stats[@]}"; do
        IFS='|' read -r file_path raw_tokens opt_tokens savings lines <<< "$stat"
        
        # Truncate long paths if needed
        local max_path_length=43  # Maximum characters to display
        if [[ ${#file_path} -gt $max_path_length ]]; then
            # Truncate and add ellipsis
            file_path="...${file_path:(-$max_path_length+3)}"
        fi
        
        # Format the savings with color if possible
        local savings_color="\033[32m" # Green
        local reset_color="\033[0m"
        
        # Format and display the row
        if [[ -t 1 ]]; then # Check if output is terminal
            printf "│ %-43s │ %-9s │ %-9s │ ${savings_color}%6s%%${reset_color} │ %5s │\n" \
                "$file_path" "$raw_tokens" "$opt_tokens" "$savings" "$lines"
        else
            printf "│ %-43s │ %-9s │ %-9s │ %6s%% │ %5s │\n" \
                "$file_path" "$raw_tokens" "$opt_tokens" "$savings" "$lines"
        fi
    done
    
    echo "└─────────────────────────────────────────────┴───────────┴───────────┴──────────┴───────┘"
    
    # Add note about potential savings
    echo "   💡 Files with high token counts may benefit from refactoring or exclusion."
    
    # Clean up
    rm -rf "$temp_dir"
}