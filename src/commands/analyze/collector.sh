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
    
    # Default value for total files
    local total_files=0
    
    # Check if using gitignore integration
    if [[ "$use_gitignore" == "true" && -f "$directory/.gitignore" ]]; then
        echo "   Using .gitignore patterns from $directory/.gitignore"
    fi
    
    # Find files based on configured extensions
    if [[ "$use_gitignore" == "true" && -f "$directory/.gitignore" ]]; then
        # Use the gitignore utility
        collect_files_respecting_gitignore "$directory" "$extensions" "$files_array_name"
        total_files=${total_files:-0}  # Ensure total_files has a default value
        local included_files
        included_files=$(eval "echo \${#$files_array_name[@]}")
        
        # Limit to max files if needed
        if [[ $included_files -gt $max_files ]]; then
            # Create a new array with limited entries - use a more secure approach with temp file
            local temp_file
            temp_file=$(mktemp)
            
            # Export array to temp file and then read back limited entries
            eval "printf '%s\\0' \"\${$files_array_name[@]:0:$max_files}\"" > "$temp_file"
            
            # Clear the array and read back limited entries
            eval "$files_array_name=()"
            while IFS= read -r -d '' entry; do
                local escaped_entry
                printf -v escaped_entry '%q' "$entry"
                eval "$files_array_name+=($escaped_entry)"
            done < "$temp_file"
            
            # Clean up
            rm -f "$temp_file"
            included_files=$max_files
        fi
    else
        # Traditional file collection without gitignore
        collect_files_traditional "$directory" "$extensions" "$max_files" "$max_size" "$files_array_name"
        total_files=${total_files:-0}  # Ensure total_files has a default value
        local included_files
        included_files=$(eval "echo \${#$files_array_name[@]}")
    fi
    
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
    find_cmd="find \"$directory\" -type f "
    
    # Only add pattern if we have extensions
    if [[ ${#ext_array[@]} -gt 0 ]]; then
        find_cmd+=" \\( -false"
        for ext in "${ext_array[@]}"; do
            # Handle dot in extension correctly
            if [[ "$ext" == .* ]]; then
                find_cmd+=" -o -name \"*$ext\""
            else
                find_cmd+=" -o -name \"*.$ext\""
            fi
        done
        find_cmd+=" \\)"
    fi
    
    # Don't exclude src directory!
    find_cmd+=" -not -path \"*/\.git/*\" -not -path \"*/node_modules/*\" | sort"
    
    # Initialize counters and arrays
    local total_files=0
    local included_files=0
    eval "$files_array_name=()"
    
    # Debug the find command
    echo "   Debug: Find command: $find_cmd" >&2
    
    # Process each found file
    while IFS= read -r file; do
        ((total_files++))
        echo "   Debug: Processing file: $file" >&2
        
        # Skip if exceeds max files - use safer command substitution
        local current_count
        current_count=$(eval "echo \${#$files_array_name[@]}")
        if [[ $current_count -ge $max_files ]]; then
            echo "   Debug: Skipping - max files exceeded" >&2
            continue
        fi
        
        # Get relative path - using a portable approach
        local rel_path="${file#$PWD/}"
        # If still absolute path, just use the file name
        if [[ "$rel_path" == /* ]]; then
            rel_path=$(basename "$file")
        fi
        echo "   Debug: Relative path: $rel_path" >&2
        
        # Check excluded folders
        local excluded=false
        for folder in "${EXCLUDED_FOLDERS[@]}"; do
            # Only match actual folders, not substrings - use more explicit matching
            if [[ "$rel_path" == *"/$folder/"* || "$rel_path" == *"/$folder" || "$rel_path" == "$folder/"* || "$rel_path" == "$folder" ]]; then
                echo "   Debug: Excluded by folder: $folder for path $rel_path" >&2
                excluded=true
                break
            fi
        done
        
        # Check excluded files
        if [[ "$excluded" == "false" ]]; then
            local file_basename=$(basename "$rel_path")
            for pattern in "${EXCLUDED_FILES[@]}"; do
                # Try exact match first
                if [[ "$file_basename" == "$pattern" ]]; then
                    echo "   Debug: Excluded by file pattern (exact): $pattern" >&2
                    excluded=true
                    break
                fi
                
                # Then try pattern match if pattern contains wildcards
                if [[ "$pattern" == *"*"* && "$file_basename" == $pattern ]]; then
                    echo "   Debug: Excluded by file pattern (wildcard): $pattern" >&2
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
        
        echo "   Debug: File size: $file_size, Max size: $max_size" >&2
        
        # Check if we got a valid size
        if [[ -n "$file_size" ]] && [[ "$file_size" =~ ^[0-9]+$ ]] && [[ $file_size -gt $max_size ]]; then
            echo "   Debug: Skipping file - too large" >&2
            continue
        fi
        
        # Skip binary files if configured
        if [[ "$SKIP_BINARY_FILES" == "true" ]] && is_binary_file "$file"; then
            continue
        fi
        
        # Add to files array
        echo "   Debug: Adding file to array: $file with array name $files_array_name" >&2
        
        # Securely add to array using printf to properly escape filename
        case "$files_array_name" in
            files)
                files+=("$file")
                ;;
            *)
                # Use printf %q to properly escape the filename for eval
                local escaped_file
                printf -v escaped_file '%q' "$file"
                eval "$files_array_name+=($escaped_file)"
                ;;
        esac
        
        ((included_files++))
        
        # Debug - check current array size using safer command substitution
        local current_array_size
        current_array_size=$(eval "echo \${#$files_array_name[@]}")
        echo "   Debug: Current array size: $current_array_size" >&2
        
        # Show progress
        if [[ $((included_files % 10)) -eq 0 ]]; then
            echo -ne "   Progress: $included_files files included...\r"
        fi
    done < <(eval $find_cmd)
    
    # Set global total_files for caller
    total_files=$total_files
}