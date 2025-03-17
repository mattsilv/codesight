#!/bin/bash
# File collection utilities for CodeSight analyze command

# Collect files matching the specified criteria 
function collect_files() {
    local directory="$1"
    local extensions="$2"
    local max_files="$3"
    local max_size="$4"
    local use_gitignore="$5"
    local files_array_name="$6"
    
    echo "📂 Collecting files..."
    
    # Check if using gitignore integration
    if [[ "$use_gitignore" == "true" && -f "$directory/.gitignore" ]]; then
        echo "   Using .gitignore patterns from $directory/.gitignore"
    fi
    
    # Find files based on configured extensions
    if [[ "$use_gitignore" == "true" && -f "$directory/.gitignore" ]]; then
        # Use the gitignore utility
        collect_files_respecting_gitignore "$directory" "$extensions" "$files_array_name"
        local total_files=${#files[@]}
        local included_files=$total_files
        
        # Limit to max files if needed
        if [[ $total_files -gt $max_files ]]; then
            # Create a new array with limited entries
            local temp_files=("${files[@]:0:$max_files}")
            eval "$files_array_name=(\"${temp_files[@]}\")"
            included_files=$max_files
        fi
    else
        # Traditional file collection without gitignore
        collect_files_traditional "$directory" "$extensions" "$max_files" "$max_size" "$files_array_name"
    fi
    
    # Get the count of files from the array
    eval "local included_files=\${#$files_array_name[@]}"
    echo "   Found $included_files files to include (from $total_files total)"
}

# Collect files using traditional find method
function collect_files_traditional() {
    local directory="$1"
    local extensions="$2"
    local max_files="$3"
    local max_size="$4"
    local files_array_name="$5"
    
    # Build find command for extensions
    IFS=' ' read -ra ext_array <<< "$extensions"
    find_cmd="find \"$directory\" -type f \\( -false"
    for ext in "${ext_array[@]}"; do
        find_cmd+=" -o -name \"*$ext\""
    done
    find_cmd+=" \\) | sort"
    
    # Initialize counters and arrays
    local total_files=0
    local included_files=0
    eval "$files_array_name=()"
    
    # Process each found file
    while IFS= read -r file; do
        ((total_files++))
        
        # Skip if exceeds max files
        eval "local current_count=\${#$files_array_name[@]}"
        if [[ $current_count -ge $max_files ]]; then
            continue
        fi
        
        # Get relative path - using a portable approach
        local rel_path="${file#$PWD/}"
        # If still absolute path, just use the file name
        if [[ "$rel_path" == /* ]]; then
            rel_path=$(basename "$file")
        fi
        
        # Check excluded folders
        local excluded=false
        for folder in "${EXCLUDED_FOLDERS[@]}"; do
            if [[ "$rel_path" == *"$folder"* ]]; then
                excluded=true
                break
            fi
        done
        
        # Check excluded files
        if [[ "$excluded" == "false" ]]; then
            for pattern in "${EXCLUDED_FILES[@]}"; do
                if [[ "$(basename "$rel_path")" == $pattern ]]; then
                    excluded=true
                    break
                fi
            done
        fi
        
        # Skip if excluded
        if [[ "$excluded" == "true" ]]; then
            continue
        fi
        
        # Skip if too large
        local file_size
        if command -v stat &>/dev/null; then
            # Try GNU stat format
            file_size=$(stat -c%s "$file" 2>/dev/null)
            
            # If that failed, try BSD stat format
            if [[ $? -ne 0 ]]; then
                file_size=$(stat -f%z "$file" 2>/dev/null)
            fi
            
            # If both failed, use wc as fallback
            if [[ $? -ne 0 ]]; then
                file_size=$(wc -c < "$file" 2>/dev/null)
            fi
        else
            # Use wc if stat command not available
            file_size=$(wc -c < "$file" 2>/dev/null)
        fi
        
        # Check if we got a valid size
        if [[ -n "$file_size" ]] && [[ "$file_size" =~ ^[0-9]+$ ]] && [[ $file_size -gt $max_size ]]; then
            continue
        fi
        
        # Skip binary files if configured
        if [[ "$SKIP_BINARY_FILES" == "true" ]] && is_binary_file "$file"; then
            continue
        fi
        
        # Add to files array
        eval "$files_array_name+=(\"$file\")"
        ((included_files++))
        
        # Show progress
        if [[ $((included_files % 10)) -eq 0 ]]; then
            echo -ne "   Progress: $included_files files included...\r"
        fi
    done < <(eval $find_cmd)
}