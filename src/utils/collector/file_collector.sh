#!/bin/bash
# Consolidated file collection utility for CodeSight
# This module provides a unified interface for finding and filtering files

# Global file collection function that supports multiple modes and filters
# Parameters:
#   directory - The directory to search in
#   extensions - Space-separated list of file extensions to include
#   max_files - Maximum number of files to return (0 for no limit)
#   max_size - Maximum file size in bytes (0 for no limit)
#   respect_gitignore - Whether to respect .gitignore patterns if Git is available
#   skip_binary - Whether to skip binary files
#   output_array - Name of the array variable to store results in
function collect_files_unified() {
    local directory="${1:-$PWD}"
    local extensions="${2:-$FILE_EXTENSIONS}"
    local max_files="${3:-$MAX_FILES}"
    local max_size="${4:-$MAX_FILE_SIZE}"
    local respect_gitignore="${5:-$RESPECT_GITIGNORE}"
    local skip_binary="${6:-$SKIP_BINARY_FILES}"
    local output_array="${7:-files}"
    
    # Ensure directory exists
    if [[ ! -d "$directory" ]]; then
        echo "❌ Directory not found: $directory" >&2
        return 1
    fi
    
    # Initialize counters
    local total_files=0
    local included_files=0
    
    # Reset the output array
    if [[ "${BASH_VERSINFO[0]}" -ge 4 && "${BASH_VERSINFO[1]}" -ge 3 ]]; then
        declare -n array_ref="$output_array"
        array_ref=()
    else
        eval "$output_array=()"
    fi
    
    # Check if using .gitignore integration
    local use_git=false
    local gitignore_exists=false
    
    # Only try to use Git if explicitly requested
    if [[ "$respect_gitignore" == "true" ]]; then
        if [[ -f "$directory/.gitignore" ]]; then
            gitignore_exists=true
            if command -v git &>/dev/null; then
                use_git=true
                echo "   Using Git's built-in .gitignore handling"
            else
                echo "   .gitignore found but Git not available. Patterns will be ignored."
            fi
        else
            echo "   No .gitignore found. Using standard exclusion rules."
        fi
    fi
    
    # Build find command for file extensions
    IFS=' ' read -ra ext_array <<< "$extensions"
    local find_cmd="find \"$directory\" -type f "
    
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
    
    # Add standard exclusions for hidden and common directories to avoid
    find_cmd+=" -not -path \"*/\\.git/*\" -not -path \"*/node_modules/*\" | sort"
    
    # Debug output
    if [[ -n "$CODESIGHT_VERBOSE" ]]; then
        echo "   Debug: Find command: $find_cmd" >&2
    fi
    
    # Determine if we can use parallel processing
    local use_parallel=false
    if command -v parallel &>/dev/null; then
        use_parallel=true
        if [[ -n "$CODESIGHT_VERBOSE" ]]; then
            echo "   Using GNU parallel for faster processing"
        fi
    fi
    
    # Check if a file should be ignored by git
    is_ignored_by_git() {
        local file="$1"
        if [[ "$use_git" == "true" ]]; then
            if git check-ignore -q "$file"; then
                return 0  # File is ignored
            fi
        fi
        return 1  # File is not ignored
    }
    
    # Check if a file should be excluded based on the folder it's in
    is_excluded_by_folder() {
        local file_path="$1"
        local rel_path="${file_path#$PWD/}"
        
        # If still absolute path, just use the file name
        if [[ "$rel_path" == /* ]]; then
            rel_path=$(basename "$file_path")
        fi
        
        for folder in "${EXCLUDED_FOLDERS[@]}"; do
            if [[ "$rel_path" == *"/$folder/"* || "$rel_path" == *"/$folder" || 
                  "$rel_path" == "$folder/"* || "$rel_path" == "$folder" ]]; then
                return 0  # File is in excluded folder
            fi
        done
        
        return 1  # File is not in excluded folder
    }
    
    # Check if a file should be excluded based on its name
    is_excluded_by_name() {
        local file_path="$1"
        local file_basename=$(basename "$file_path")
        
        for pattern in "${EXCLUDED_FILES[@]}"; do
            # Try exact match first
            if [[ "$file_basename" == "$pattern" ]]; then
                return 0  # File is excluded
            fi
            
            # Then try pattern match if pattern contains wildcards
            if [[ "$pattern" == *"*"* && "$file_basename" == $pattern ]]; then
                return 0  # File is excluded by pattern
            fi
        done
        
        return 1  # File is not excluded
    }
    
    # Check if a file is too large
    is_too_large() {
        local file="$1"
        local max="$2"
        
        # Skip size check if max is 0 (unlimited)
        if [[ "$max" -eq 0 ]]; then
            return 1  # Not too large
        fi
        
        local file_size=0
        # Try different stat commands based on OS
        if command -v stat &>/dev/null; then
            # Try GNU stat format first
            file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
        fi
        
        # Fall back to wc if stat failed
        if [[ -z "$file_size" || ! "$file_size" =~ ^[0-9]+$ ]]; then
            file_size=$(wc -c < "$file" 2>/dev/null)
        fi
        
        # Check if size exceeds max
        if [[ -n "$file_size" && "$file_size" =~ ^[0-9]+$ && $file_size -gt $max ]]; then
            return 0  # File is too large
        fi
        
        return 1  # File is not too large
    }
    
    # Process files in parallel
    if [[ "$use_parallel" == "true" ]]; then
        # Create temporary files for processing
        local temp_file="/tmp/codesight_all_files.txt"
        local results_file="/tmp/codesight_included_files.txt"
        > "$results_file"  # Create empty results file
        
        # Get all files matching basic criteria
        eval $find_cmd > "$temp_file"
        total_files=$(wc -l < "$temp_file")
        
        # Create parallel processing script
        local parallel_script="/tmp/codesight_parallel_file_check.sh"
        cat > "$parallel_script" << EOF
#!/bin/bash
file="\$1"
max_size="$max_size"
use_git="$use_git"
skip_binary="$skip_binary"
results_file="$results_file"

# Skip if file doesn't exist
if [[ ! -f "\$file" ]]; then
    exit 0
fi

# Get relative path
rel_path="\${file#$PWD/}"
if [[ "\$rel_path" == /* ]]; then
    rel_path=\$(basename "\$file")
fi

# Check if git ignores this file
if [[ "$use_git" == "true" ]]; then
    if git check-ignore -q "\$file"; then
        exit 0
    fi
fi

# Check excluded folders
for folder in ${EXCLUDED_FOLDERS[@]}; do
    if [[ "\$rel_path" == *"/\$folder/"* || "\$rel_path" == *"/\$folder" || 
          "\$rel_path" == "\$folder/"* || "\$rel_path" == "\$folder" ]]; then
        exit 0
    fi
done

# Check excluded files
file_basename=\$(basename "\$rel_path")
for pattern in ${EXCLUDED_FILES[@]}; do
    # Try exact match first
    if [[ "\$file_basename" == "\$pattern" ]]; then
        exit 0
    fi
    # Then try pattern match if pattern contains wildcards
    if [[ "\$pattern" == *"*"* && "\$file_basename" == \$pattern ]]; then
        exit 0
    fi
done

# Check file size
if [[ $max_size -gt 0 ]]; then
    file_size=0
    if command -v stat &>/dev/null; then
        file_size=\$(stat -c%s "\$file" 2>/dev/null || stat -f%z "\$file" 2>/dev/null)
    else
        file_size=\$(wc -c < "\$file" 2>/dev/null)
    fi

    if [[ -n "\$file_size" ]] && [[ "\$file_size" =~ ^[0-9]+\$ ]] && [[ \$file_size -gt $max_size ]]; then
        exit 0
    fi
fi

# Check if binary file
if [[ "$skip_binary" == "true" ]]; then
# Special handling for text files we know aren't binary
if [[ "\$file" == *.sh || "\$file" == *.py || "\$file" == *.js || "\$file" == *.html || \
  "\$file" == *.css || "\$file" == *.md || "\$file" == *.txt || "\$file" == *.json ]]; then
    # These file types are definitely text
    # Do nothing, continue processing
    :  # No-op
else
    # For other files, check if they might be binary
            if file "\$file" | grep -q "binary"; then
                exit 0
            fi
            # Additional check for null bytes
            if grep -q $'\x00' "\$file" 2>/dev/null; then
                exit 0
            fi
        fi
fi

# File passed all checks, add to results
echo "\$file" >> "\$results_file"
EOF
        chmod +x "$parallel_script"
        
        # Run parallel processing
        if [[ -n "$CODESIGHT_VERBOSE" ]]; then
            cat "$temp_file" | parallel --bar -j+0 "$parallel_script" {}
        else
            cat "$temp_file" | parallel -j+0 "$parallel_script" {}
        fi
        
        # Read results into array
        if [[ -f "$results_file" ]]; then
            # Limit to max files if needed
            if [[ $max_files -gt 0 ]]; then
                head -n "$max_files" "$results_file" > "${results_file}.limited"
                mv "${results_file}.limited" "$results_file"
            fi
            
            # Count included files
            included_files=$(wc -l < "$results_file")
            
            # Read into specified array using appropriate method
            if [[ "${BASH_VERSINFO[0]}" -ge 4 && "${BASH_VERSINFO[1]}" -ge 3 ]]; then
                declare -n array_ref="$output_array"
                while IFS= read -r file; do
                    array_ref+=("$file")
                done < "$results_file"
            else
                while IFS= read -r file; do
                    eval "$output_array+=(\"$file\")"
                done < "$results_file"
            fi
        fi
        
        # Clean up temporary files
        rm -f "$temp_file" "$results_file" "$parallel_script"
    else
        # Sequential processing for systems without GNU parallel
        while IFS= read -r file; do
            ((total_files++))
            
            # Skip if file doesn't exist
            if [[ ! -f "$file" ]]; then
                continue
            fi
            
            # Skip if exceeds max files
            if [[ $max_files -gt 0 ]]; then
                if [[ "${BASH_VERSINFO[0]}" -ge 4 && "${BASH_VERSINFO[1]}" -ge 3 ]]; then
                    declare -n array_ref="$output_array"
                    current_count=${#array_ref[@]}
                else
                    eval "current_count=\${#$output_array[@]}"
                fi
                
                if [[ $current_count -ge $max_files ]]; then
                    if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                        echo "   Debug: Skipping - max files exceeded" >&2
                    fi
                    continue
                fi
            fi
            
            # Check if git should ignore this file
            if is_ignored_by_git "$file"; then
                if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                    echo "   Debug: Ignored by git: $file" >&2
                fi
                continue
            fi
            
            # Check excluded folders
            if is_excluded_by_folder "$file"; then
                if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                    echo "   Debug: Excluded by folder: $file" >&2
                fi
                continue
            fi
            
            # Check excluded files
            if is_excluded_by_name "$file"; then
                if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                    echo "   Debug: Excluded by name: $file" >&2
                fi
                continue
            fi
            
            # Check file size
            if is_too_large "$file" "$max_size"; then
                if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                    echo "   Debug: File too large: $file" >&2
                fi
                continue
            fi
            
            # Skip binary files if configured
            if [[ "$skip_binary" == "true" ]]; then
                # Check if this is a known text file by extension
                local file_ext="${file##*.}"
                case "$file_ext" in
                    sh|py|js|jsx|ts|tsx|html|css|md|txt|json|yaml|yml|xml|csv|toml|ini)
                        # Definitely text, don't skip
                        ;;
                    *)
                        # Check if binary
                        if is_binary_file "$file"; then
                            if [[ -n "$CODESIGHT_VERBOSE" ]]; then
                                echo "   Debug: Skipping binary file: $file" >&2
                            fi
                            continue
                        fi
                        ;;
                esac
            fi
            
            # File passed all checks - add to array
            if [[ "${BASH_VERSINFO[0]}" -ge 4 && "${BASH_VERSINFO[1]}" -ge 3 ]]; then
                declare -n array_ref="$output_array"
                array_ref+=("$file")
            else
                eval "$output_array+=(\"$file\")"
            fi
            
            ((included_files++))
            
            # Show progress
            if [[ $((included_files % 10)) -eq 0 ]]; then
                echo -ne "   Progress: $included_files files included...\r"
            fi
        done < <(eval $find_cmd)
    fi
    
    echo "   Found $included_files files to include (from $total_files total)"
    return 0
}

# Simplified API for collecting files with standard parameters
function collect_files_standard() {
    local directory="${1:-$PWD}"
    local extensions="${2:-$FILE_EXTENSIONS}"
    local output_array="${3:-files}"
    
    # Use standard config values for other parameters
    collect_files_unified "$directory" "$extensions" "$MAX_FILES" "$MAX_FILE_SIZE" \
                        "$RESPECT_GITIGNORE" "$SKIP_BINARY_FILES" "$output_array"
}

# Function to collect only specific file types regardless of config
function collect_files_by_type() {
    local directory="${1:-$PWD}"
    local file_type="$2"  # e.g., "sh", "py", "js", etc.
    local output_array="${3:-files}"
    
    # Convert file type to extension with dot
    local extension=".$file_type"
    
    # Use unlimited files and default size limits
    collect_files_unified "$directory" "$extension" "0" "$MAX_FILE_SIZE" \
                        "$RESPECT_GITIGNORE" "$SKIP_BINARY_FILES" "$output_array"
}

# Collect only the largest files for visualization
function collect_largest_files() {
    local directory="${1:-$PWD}"
    local limit="${2:-10}"
    local extensions="${3:-$FILE_EXTENSIONS}"
    local output_array="${4:-files}"
    
    # Use unlimited max size to get all files, then we'll sort by size
    local temp_array_name="temp_files_by_size"
    eval "$temp_array_name=()"
    
    # Collect all files without size limit
    collect_files_unified "$directory" "$extensions" "0" "0" \
                        "$RESPECT_GITIGNORE" "$SKIP_BINARY_FILES" "$temp_array_name"
    
    # Process collected files to get their sizes
    local size_file="/tmp/codesight_file_sizes.txt"
    > "$size_file"  # Create empty file
    
    # Get size for each file
    if [[ "${BASH_VERSINFO[0]}" -ge 4 && "${BASH_VERSINFO[1]}" -ge 3 ]]; then
        declare -n temp_array="$temp_array_name"
        for file in "${temp_array[@]}"; do
            if [[ ! -f "$file" ]]; then continue; fi
            
            local file_size=0
            if command -v stat &>/dev/null; then
                file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
            else
                file_size=$(wc -c < "$file" 2>/dev/null)
            fi
            
            if [[ -n "$file_size" && "$file_size" =~ ^[0-9]+$ ]]; then
                echo "$file_size $file" >> "$size_file"
            fi
        done
    else
        eval "for file in \"\${$temp_array_name[@]}\"; do
            if [[ ! -f \"\$file\" ]]; then continue; fi
            
            local file_size=0
            if command -v stat &>/dev/null; then
                file_size=\$(stat -c%s \"\$file\" 2>/dev/null || stat -f%z \"\$file\" 2>/dev/null)
            else
                file_size=\$(wc -c < \"\$file\" 2>/dev/null)
            fi
            
            if [[ -n \"\$file_size\" && \"\$file_size\" =~ ^[0-9]+\$ ]]; then
                echo \"\$file_size \$file\" >> \"$size_file\"
            fi
        done"
    fi
    
    # Sort by size (numeric) and get top N
    if [[ "${BASH_VERSINFO[0]}" -ge 4 && "${BASH_VERSINFO[1]}" -ge 3 ]]; then
        declare -n array_ref="$output_array"
        array_ref=()
        
        # Sort by size (largest first) and get top N files
        while read -r size file; do
            array_ref+=("$file")
            if [[ ${#array_ref[@]} -ge $limit ]]; then
                break
            fi
        done < <(sort -rn "$size_file" | head -n "$limit")
    else
        eval "$output_array=()"
        
        # Sort by size (largest first) and get top N files
        local count=0
        while read -r size file; do
            eval "$output_array+=(\"$file\")"
            ((count++))
            if [[ $count -ge $limit ]]; then
                break
            fi
        done < <(sort -rn "$size_file" | head -n "$limit")
    fi
    
    # Clean up
    rm -f "$size_file"
    
    # Return success
    return 0
}