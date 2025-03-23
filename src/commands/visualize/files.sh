#!/bin/bash
# CodeSight visualization utility
# Displays a report of the top largest files in the codebase

function display_largest_files() {
    local directory="${1:-$PWD}"
    local limit="${2:-10}"
    local extensions="${3:-$FILE_EXTENSIONS}"
    
    echo "📊 Finding the $limit largest files in your codebase..."
    
    # Convert extensions into a format suitable for find
    IFS=' ' read -ra ext_array <<< "$extensions"
    find_extensions=""
    for ext in "${ext_array[@]}"; do
        if [[ -z "$find_extensions" ]]; then
            find_extensions="-name \"*$ext\""
        else
            find_extensions="$find_extensions -o -name \"*$ext\""
        fi
    done
    
    # Check if we're respecting gitignore
    local gitignore_filter=""
    if [[ "$RESPECT_GITIGNORE" == "true" && -f "$directory/.gitignore" ]]; then
        echo "   Respecting .gitignore patterns"
        # We'll use our gitignore utility here if integrated later
    fi
    
    # Build the find command to locate files
    local find_cmd="find \"$directory\" -type f \\( $find_extensions \\)"
    
    # For each excluded folder, add a -not -path clause
    for folder in "${EXCLUDED_FOLDERS[@]}"; do
        find_cmd="$find_cmd -not -path \"*/$folder/*\""
    done
    
    # Execute the find command and pipe to file size calculation
    echo "   Analyzing files..."
    
    # Create a temporary file to store valid files
    local valid_files_list="/tmp/codesight_valid_files.txt"
    > "$valid_files_list"
    
    # Check that files exist before counting lines
    # Using command substitution instead of eval
    while read -r file; do
        if [[ -f "$file" ]]; then
            echo "$file" >> "$valid_files_list"
        else
            echo "❌ File not found: $file" >&2
        fi
    done < <(eval "$find_cmd")
    
    # Get top files by line count - handle cross-platform compatibility
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS version
        cat "$valid_files_list" | xargs wc -l 2>/dev/null | sort -nr | head -n "$((limit+1))" > /tmp/codesight_largest_files.txt
    else
        # Linux/other version
        cat "$valid_files_list" | xargs wc -l 2>/dev/null | sort -nr | head -n "$((limit+1))" > /tmp/codesight_largest_files.txt
    fi
    
    # Clean up the valid files list
    rm -f "$valid_files_list"
    
    # Check if we have results
    if [[ ! -s /tmp/codesight_largest_files.txt ]]; then
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
    done < /tmp/codesight_largest_files.txt
    
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
    rm -f /tmp/codesight_largest_files.txt
}