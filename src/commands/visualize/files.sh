#!/bin/bash
# CodeSight visualization utility
# Displays a report of the top largest files in the codebase

function display_largest_files() {
    local directory="${1:-$PWD}"
    local limit="${2:-10}"
    local extensions="${3:-$FILE_EXTENSIONS}"
    
    echo "📊 Finding the $limit largest files in your codebase..."
    
    # Use our unified file collector
    if [[ -n "$CODESIGHT_VERBOSE" ]]; then
        echo "   Analyzing files..."
    fi
    
    # Create a temporary array to hold the files
    local file_array_name="largest_files_array"
    declare -a "$file_array_name"
    
    # Use the consolidated collector to get all matching files
    # Note that we're using the special collect_largest_files function for this purpose
    collect_largest_files "$directory" "$limit" "$extensions" "$file_array_name"
    
    # Create a temporary file to store valid files with line counts
    local valid_files_list="/tmp/codesight_valid_files.txt"
    > "$valid_files_list"
    
    # Process each file to get line count
    if [[ "${BASH_VERSINFO[0]}" -ge 4 && "${BASH_VERSINFO[1]}" -ge 3 ]]; then
        declare -n array_ref="$file_array_name"
        for file in "${array_ref[@]}"; do
            if [[ -f "$file" ]]; then
                local line_count=$(wc -l < "$file" 2>/dev/null)
                echo "$line_count $file" >> "$valid_files_list"
            fi
        done
    else
        # Fallback for older bash versions
        eval "for file in \"\${$file_array_name[@]}\"; do
            if [[ -f \"\$file\" ]]; then
                local line_count=\$(wc -l < \"\$file\" 2>/dev/null)
                echo \"\$line_count \$file\" >> \"$valid_files_list\"
            fi
        done"
    fi
    
    # Sort by line count (largest first)
    sort -nr "$valid_files_list" > "/tmp/codesight_largest_files.txt"
    mv "/tmp/codesight_largest_files.txt" "$valid_files_list"
    
    # Check if we have results
    if [[ ! -s $valid_files_list ]]; then
        echo "❌ No files found matching the criteria."
        return 1
    fi
    
    # Display results as a formatted table, excluding the total line which is always the first line
    echo ""
    echo "📏 Top $limit largest files by line count:"
    
    # Improved table display with better column handling
    # First collect all data into arrays for consistent formatting
    local -a line_counts=()
    local -a file_paths=()
    local max_path_length=0
    
    # Skip the first line if it's the total count line
    # Then collect data for remaining top N files from the temp file
    local line_number=0
    while read -r line; do
        ((line_number++))
        
        # Skip the first line if it contains the total word count
        if [[ $line_number -eq 1 && $line == *"total"* ]]; then
            continue
        fi
        
        # Extract line count and file path
        local line_count=$(echo "$line" | awk '{print $1}')
        local file_path=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
        
        # Get relative path if possible
        local rel_path="${file_path#$directory/}"
        if [[ "$rel_path" == "$file_path" ]]; then
            # If not changed, file was not under directory
            rel_path=$(basename "$file_path")
        fi
        
        # Track for max path length for optimal table width
        if [[ ${#rel_path} -gt $max_path_length ]]; then
            max_path_length=${#rel_path}
        fi
        
        # Store data in arrays
        line_counts+=($line_count)
        file_paths+=("$rel_path")
    done < "$valid_files_list"
    
    # Cap maximum path length display to terminal width
    local terminal_width=80
    if command -v tput &>/dev/null; then
        terminal_width=$(tput cols 2>/dev/null || echo 80)
    fi
    
    # Allow at least 55 chars for path, but limit based on terminal width
    local display_path_length=$((max_path_length < 55 ? 55 : max_path_length))
    if [[ $((display_path_length + 20)) -gt $terminal_width ]]; then
        display_path_length=$((terminal_width - 20))
    fi
    
    # Build table top based on calculated width - fix string repetition using printf
    local path_dashes=$(printf '%*s' $((display_path_length+2)) '' | tr ' ' '─')
    local top_line="┌───────────────┬${path_dashes}┐"
    local header_line="│ Lines         │ File Path$(printf '%*s' $((display_path_length-9)) '') │"
    local separator_line="├───────────────┼${path_dashes}┤"
    local bottom_line="└───────────────┴${path_dashes}┘"
    
    echo "$top_line"
    echo "$header_line"
    echo "$separator_line"
    
    # Display rows with consistent formatting
    for ((i=0; i<${#line_counts[@]}; i++)); do
        local rel_path="${file_paths[$i]}"
        local line_count="${line_counts[$i]}"
        
        # Truncate long paths if needed, but keep filename and parent folder intact
        if [[ ${#rel_path} -gt $display_path_length ]]; then
            # Get the filename and its parent folder
            local filename=$(basename "$rel_path")
            local parent_dir=$(dirname "$rel_path")
            local parent_name=$(basename "$parent_dir")
            
            # If file is in root (no parent), just show filename
            if [[ "$parent_name" == "." ]]; then
                rel_path="$filename"
            else
                # Show parent/filename format
                local combined="$parent_name/$filename"
                
                # If combined still too long, just show filename
                if [[ ${#combined} -gt $display_path_length ]]; then
                    rel_path="$filename"
                else
                    rel_path="$combined"
                fi
                
                # Add ellipsis if we truncated the path
                if [[ "$combined" != "$rel_path" || "$parent_dir" != "$parent_name" ]]; then
                    rel_path=".../$rel_path"
                fi
            fi
        fi
        
        printf "│ %-13s │ %-${display_path_length}s │\n" "$line_count" "$rel_path"
    done
    
    echo "$bottom_line"
    
    # Clean up temp file
    rm -f "$valid_files_list"
}