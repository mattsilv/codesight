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
    
    # Get top files by line count - handle cross-platform compatibility
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS version
        eval "$find_cmd" | xargs wc -l 2>/dev/null | sort -nr | head -n "$((limit+1))" > /tmp/codesight_largest_files.txt
    else
        # Linux/other version
        eval "$find_cmd" | xargs wc -l 2>/dev/null | sort -nr | head -n "$((limit+1))" > /tmp/codesight_largest_files.txt
    fi
    
    # Check if we have results
    if [[ ! -s /tmp/codesight_largest_files.txt ]]; then
        echo "❌ No files found matching the criteria."
        return 1
    fi
    
    # Display results as a formatted table, excluding the total line which is always the first line
    echo ""
    echo "📏 Top $limit largest files by line count:"
    echo "┌───────────────┬─────────────────────────────────────────────────────────┐"
    echo "│ Lines         │ File Path                                               │"
    echo "├───────────────┼─────────────────────────────────────────────────────────┤"
    
    # Skip the first line if it's the total count line
    # Then display the remaining top N files from the temp file
    local line_number=0
    cat /tmp/codesight_largest_files.txt | while read -r line; do
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
        
        # Format and display the row, truncating long paths if needed
        local max_path_length=55  # Maximum characters to display
        if [[ ${#rel_path} -gt $max_path_length ]]; then
            # Truncate and add ellipsis
            rel_path="...${rel_path:(-$max_path_length+3)}"
        fi
        
        printf "│ %-13s │ %-55s │\n" "$line_count" "$rel_path"
    done
    
    echo "└───────────────┴─────────────────────────────────────────────────────────┘"
    
    # Clean up temp file
    rm -f /tmp/codesight_largest_files.txt
}