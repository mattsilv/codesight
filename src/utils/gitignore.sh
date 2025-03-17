#!/bin/bash
# GitIgnore pattern handling for CodeSight

# Function to check if a file should be ignored based on .gitignore patterns
function is_ignored_by_gitignore() {
    local file="$1"
    local gitignore_path="$2"
    local rel_path="${file#$PWD/}"
    
    echo "   Debug: Checking if $rel_path is ignored by $gitignore_path" >&2
    
    # Simple gitignore parser
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ -z "$line" || "$line" == \#* ]]; then
            continue
        fi
        
        # Remove trailing spaces
        line="${line%"${line##*[![:space:]]}"}"
        
        # Handle negation (!)
        local negate=false
        if [[ "$line" == !* ]]; then
            negate=true
            line="${line:1}"
        fi
        
        # Remove leading/trailing slashes for pattern matching
        line="${line#/}"
        line="${line%/}"
        
        # Convert simple globs to regex patterns
        # * matches anything except /
        local pattern="${line//\*/[^/]*}"
        # ** matches anything including /
        pattern="${pattern//\*\*/.*}"
        # ? matches any single character except /
        pattern="${pattern//\?/[^/]}"
        
        # Add anchors for directory matching
        if [[ "$line" == */* ]]; then
            # Pattern with path separator is anchored to base dir
            pattern="^$pattern"
        else
            # Pattern without path separator matches any path component
            pattern="(^|/)$pattern(/|$)"
        fi
        
        echo "   Debug: Pattern '$line' converted to regex: '$pattern'" >&2
        
        # Check if file matches the pattern
        if [[ "$rel_path" =~ $pattern ]]; then
            echo "   Debug: MATCH - File $rel_path matches pattern $line" >&2
            if [[ "$negate" == "true" ]]; then
                echo "   Debug: But pattern is negated with ! so NOT ignoring" >&2
                return 1  # Not ignored (negated match)
            else
                echo "   Debug: IGNORING file due to match" >&2
                return 0  # Ignored
            fi
        fi
    done < "$gitignore_path"
    
    return 1  # Not ignored
}

# Function to collect files while respecting .gitignore patterns
function collect_files_respecting_gitignore() {
    local directory="$1"
    local extensions="$2"
    local files_array_name="$3"
    
    # Add debug info
    echo "   Debug: Directory=$directory, Extensions=$extensions" >&2
    
    # Prepare file extensions for find command
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
    
    find_cmd+=" | sort"
    
    # Debug the find command
    echo "   Debug: Find command: $find_cmd" >&2
    
    # Get all files first
    local all_files=()
    while IFS= read -r file; do
        all_files+=("$file")
    done < <(eval $find_cmd)
    
    # Debug the found files
    echo "   Debug: Found ${#all_files[@]} raw files" >&2
    
    # Find .gitignore files in directory and parent directories
    local gitignore_files=()
    local current_dir="$directory"
    
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/.gitignore" ]]; then
            gitignore_files+=("$current_dir/.gitignore")
            echo "   Debug: Found gitignore at $current_dir/.gitignore" >&2
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    echo "   Debug: Found ${#gitignore_files[@]} gitignore files" >&2
    
    # Initialize output array
    eval "$files_array_name=()"
    
    # Filter files based on .gitignore patterns
    for file in "${all_files[@]}"; do
        local ignored=false
        
        # Check against all .gitignore files, starting from root
        for ((i=${#gitignore_files[@]}-1; i>=0; i--)); do
            if is_ignored_by_gitignore "$file" "${gitignore_files[$i]}"; then
                echo "   Debug: File $file ignored by ${gitignore_files[$i]}" >&2
                ignored=true
                break
            fi
        done
        
        # Skip if ignored
        if [[ "$ignored" == "true" ]]; then
            continue
        fi
        
        # Check excluded folders
        for folder in "${EXCLUDED_FOLDERS[@]}"; do
            # Only match actual folders, not substrings
            if [[ "$file" == *"/$folder/"* || "$file" == *"/$folder" || "$file" == "$folder/"* || "$file" == "$folder" ]]; then
                echo "   Debug: Excluded by folder in gitignore.sh: $folder" >&2
                ignored=true
                break
            fi
        done
        
        # Check excluded files
        if [[ "$ignored" == "false" ]]; then
            for pattern in "${EXCLUDED_FILES[@]}"; do
                # Check if we have a glob pattern (contains * or ?)
                if [[ "$pattern" == *[\*\?]* ]]; then
                    # Use glob matching
                    local filename=$(basename "$file")
                    if [[ "$filename" == $pattern ]]; then
                        ignored=true
                        break
                    fi
                else
                    # Exact match
                    if [[ "$(basename "$file")" == "$pattern" ]]; then
                        ignored=true
                        break
                    fi
                fi
            done
        fi
        
        # Skip if too large (if MAX_FILE_SIZE is defined)
        if [[ "$ignored" == "false" && -n "$MAX_FILE_SIZE" ]]; then
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
            
            # Check if we got a valid size and it's too large
            if [[ -n "$file_size" && "$file_size" =~ ^[0-9]+$ && $file_size -gt $MAX_FILE_SIZE ]]; then
                ignored=true
            fi
        fi
        
        # Skip binary files if configured
        if [[ "$ignored" == "false" && "$SKIP_BINARY_FILES" == "true" ]]; then
            if is_binary_file "$file"; then
                ignored=true
            fi
        fi
        
        # Add to result array if not ignored
        if [[ "$ignored" == "false" ]]; then
            eval "$files_array_name+=(\"$file\")"
        fi
    done
    
    # Get total files count for reference
    local total_files=${#all_files[@]}
    eval "local included_files=\${#$files_array_name[@]}"
    
    # Return the total file count through a global variable
    total_files=$total_files
}