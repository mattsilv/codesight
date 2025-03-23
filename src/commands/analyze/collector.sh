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
        eval "local included_files=\${#$files_array_name[@]}"
        
        # Limit to max files if needed
        if [[ $included_files -gt $max_files ]]; then
            # Create a new array with limited entries
            eval "local temp_files=(\"\${$files_array_name[@]:0:$max_files}\")"
            eval "$files_array_name=(\"${temp_files[@]}\")"
            included_files=$max_files
        fi
    else
        # Traditional file collection without gitignore
        collect_files_traditional "$directory" "$extensions" "$max_files" "$max_size" "$files_array_name"
        total_files=${total_files:-0}  # Ensure total_files has a default value
        eval "local included_files=\${#$files_array_name[@]}"
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
    
    # Debug the find command if in verbose mode
    if [[ -n "$CODESIGHT_VERBOSE" ]]; then
        echo "   Debug: Find command: $find_cmd" >&2
    fi
    
    # Check if we can use parallel for faster processing
    local use_parallel=false
    if command -v parallel &>/dev/null; then
        use_parallel=true
        if [[ -n "$CODESIGHT_VERBOSE" ]]; then
            echo "   Using GNU parallel for faster processing"
        fi
    fi
    
    if [[ "$use_parallel" == "true" ]]; then
        # Parallel processing approach
        # First collect all files
        local temp_file="/tmp/codesight_all_files.txt"
        eval $find_cmd > "$temp_file"
        total_files=$(wc -l < "$temp_file")
        
        # Create a temporary results file
        local results_file="/tmp/codesight_included_files.txt"
        > "$results_file"
        
        # Create a temporary script for parallel to use
        local parallel_script="/tmp/codesight_parallel_file_check.sh"
        cat > "$parallel_script" << EOF
#!/bin/bash
file="\$1"
max_size="$max_size"
dir="$directory"
results_file="$results_file"

# Skip if file doesn't exist
if [[ ! -f "\$file" ]]; then
    echo "❌ File not found: \$file" >&2
    exit 0
fi

# Get relative path
rel_path="\${file#$PWD/}"
if [[ "\$rel_path" == /* ]]; then
    rel_path=\$(basename "\$file")
fi

# Check excluded folders
for folder in ${EXCLUDED_FOLDERS[@]}; do
    if [[ "\$rel_path" == *"/\$folder/"* || "\$rel_path" == *"/\$folder" || "\$rel_path" == "\$folder/"* || "\$rel_path" == "\$folder" ]]; then
        exit 0
    fi
done

# Check excluded files
file_basename=\$(basename "\$rel_path")
for pattern in ${EXCLUDED_FILES[@]}; do
    if [[ "\$file_basename" == "\$pattern" ]]; then
        exit 0
    fi
    if [[ "\$pattern" == *"*"* && "\$file_basename" == \$pattern ]]; then
        exit 0
    fi
done

# Check file size
file_size=0
if command -v stat &>/dev/null; then
    file_size=\$(stat -c%s "\$file" 2>/dev/null || stat -f%z "\$file" 2>/dev/null)
else
    file_size=\$(wc -c < "\$file" 2>/dev/null)
fi

if [[ -n "\$file_size" ]] && [[ "\$file_size" =~ ^[0-9]+\$ ]] && [[ \$file_size -gt $max_size ]]; then
    exit 0
fi

# Check if binary file
if [[ "$SKIP_BINARY_FILES" == "true" ]]; then
    # Simple check for binary content
    if file "\$file" | grep -q "binary"; then
        exit 0
    fi
fi

# File passed all checks, add to results
echo "\$file" >> "\$results_file"
EOF
        chmod +x "$parallel_script"
        
        # Use parallel to process files (use all available cores with -j+0)
        # Use a progress bar with --bar if in verbose mode
        if [[ -n "$CODESIGHT_VERBOSE" ]]; then
            cat "$temp_file" | parallel --bar -j+0 "$parallel_script" {}
        else
            cat "$temp_file" | parallel -j+0 "$parallel_script" {}
        fi
        
        # Read results into array
        if [[ -f "$results_file" ]]; then
            # Limit to max files
            if [[ $max_files -gt 0 ]]; then
                head -n "$max_files" "$results_file" > "${results_file}.limited"
                mv "${results_file}.limited" "$results_file"
            fi
            
            # Create array with results
            included_files=$(wc -l < "$results_file")
            
            # Read into specified array
            while IFS= read -r file; do
                eval "$files_array_name+=(\"$file\")"
            done < "$results_file"
        fi
        
        # Clean up temporary files
        rm -f "$temp_file" "$results_file" "$parallel_script"
    else
        # Sequential processing (original approach)
        # Process each found file
        while IFS= read -r file; do
            ((total_files++))
            if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                echo "   Debug: Processing file: $file" >&2
            fi
            
            # Skip if exceeds max files
            eval "local current_count=\${#$files_array_name[@]}"
            if [[ $current_count -ge $max_files ]]; then
                if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                    echo "   Debug: Skipping - max files exceeded" >&2
                fi
                continue
            fi
            
            # Get relative path - using a portable approach
            local rel_path="${file#$PWD/}"
            # If still absolute path, just use the file name
            if [[ "$rel_path" == /* ]]; then
                rel_path=$(basename "$file")
            fi
            if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                echo "   Debug: Relative path: $rel_path" >&2
            fi
            
            # Check if file exists before proceeding
            if [[ ! -f "$file" ]]; then
                echo "❌ File not found: $file" >&2
                continue
            fi
            
            # Check excluded folders
            local excluded=false
            for folder in "${EXCLUDED_FOLDERS[@]}"; do
                # Only match actual folders, not substrings - use more explicit matching
                if [[ "$rel_path" == *"/$folder/"* || "$rel_path" == *"/$folder" || "$rel_path" == "$folder/"* || "$rel_path" == "$folder" ]]; then
                    if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                        echo "   Debug: Excluded by folder: $folder for path $rel_path" >&2
                    fi
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
                        if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                            echo "   Debug: Excluded by file pattern (exact): $pattern" >&2
                        fi
                        excluded=true
                        break
                    fi
                    
                    # Then try pattern match if pattern contains wildcards
                    if [[ "$pattern" == *"*"* && "$file_basename" == $pattern ]]; then
                        if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                            echo "   Debug: Excluded by file pattern (wildcard): $pattern" >&2
                        fi
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
            
            if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                echo "   Debug: File size: $file_size, Max size: $max_size" >&2
            fi
            
            # Check if we got a valid size
            if [[ -n "$file_size" ]] && [[ "$file_size" =~ ^[0-9]+$ ]] && [[ $file_size -gt $max_size ]]; then
                if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                    echo "   Debug: Skipping file - too large" >&2
                fi
                continue
            fi
            
            # Skip binary files if configured
            if [[ "$SKIP_BINARY_FILES" == "true" ]] && is_binary_file "$file"; then
                continue
            fi
            
            # Add to files array
            if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                echo "   Debug: Adding file to array: $file with array name $files_array_name" >&2
            fi
            
            # Direct approach without eval
            case "$files_array_name" in
                files)
                    files+=("$file")
                    ;;
                *)
                    eval "$files_array_name+=(\"$file\")"
                    ;;
            esac
            
            ((included_files++))
            
            # Debug - check current array size
            if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                eval "local current_array_size=\${#$files_array_name[@]}"
                echo "   Debug: Current array size: $current_array_size" >&2
            fi
            
            # Show progress
            if [[ $((included_files % 10)) -eq 0 ]]; then
                echo -ne "   Progress: $included_files files included...\r"
            fi
        done < <(eval $find_cmd)
    fi
    
    # Set global total_files for caller
    total_files=$total_files
}