#!/bin/bash
# Simplified utility functions for handling .gitignore folder exclusions

# Global variable to store parsed gitignore folder patterns
GITIGNORE_FOLDERS=()

# Parse a .gitignore file and extract folder patterns
function parse_gitignore_folders() {
    local gitignore_file="$1"
    
    # Check if the file exists
    if [[ ! -f "$gitignore_file" ]]; then
        return 1
    fi
    
    # Clear previous patterns
    GITIGNORE_FOLDERS=()
    
    # Read gitignore file and extract folder patterns
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Trim leading and trailing whitespace
        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # Skip empty lines after trimming
        if [[ -z "$line" ]]; then
            continue
        fi
        
        # Skip negated patterns
        if [[ "$line" == \!* ]]; then
            continue
        fi

        # Extract folder patterns with improved handling for various gitignore formats
        # Handle wildcards and slashes appropriately
        # First, remove leading slashes if present
        if [[ "$line" == /* ]]; then
            line="${line#/}"
        fi
            
        # Extract folder patterns:
        # 1. Those ending with a slash (explicit directories)
        # 2. Those without a dot (likely directories)
        # 3. Those containing wildcards like .*/
        if [[ "$line" == */ || 
              ("$line" != *.* && "$line" != *"*"*) || 
              "$line" == *"*/" ]]; then
            
            # Remove trailing slash if present
            line="${line%/}"
            
            # Skip if empty after removing slash
            if [[ -n "$line" ]]; then
                GITIGNORE_FOLDERS+=("$line")
            fi
        fi
    done < "$gitignore_file"
    
    return 0
}

# Main function to collect files respecting gitignore folder exclusions
function collect_files_respecting_gitignore() {
    local dir="$1"
    local extensions="$2"
    local output_array="$3"
    
    # First, parse gitignore folders if the file exists
    if [[ -f "$dir/.gitignore" ]]; then
        parse_gitignore_folders "$dir/.gitignore"
        echo "   Found ${#GITIGNORE_FOLDERS[@]} folder patterns in .gitignore"
        
        if [[ ${#GITIGNORE_FOLDERS[@]} -gt 0 ]]; then
            echo "   Excluded folders: ${GITIGNORE_FOLDERS[*]}"
        fi
    fi
    
    # Build a more efficient find command that excludes gitignore folders directly
    IFS=' ' read -ra ext_array <<< "$extensions"
    
    # Start find command with file type and extensions
    local find_cmd="find \"$dir\" -type f \\( -false"
    for ext in "${ext_array[@]}"; do
        find_cmd+=" -o -name \"*$ext\""
    done
    find_cmd+=" \\)"
    
    # Add prune conditions for gitignore folders with improved pattern handling
    for folder in "${GITIGNORE_FOLDERS[@]}"; do
        # Handle patterns with wildcards
        if [[ "$folder" == *"*"* ]]; then
            # Convert gitignore globbing syntax to regex for find's -not -path
            regex_pattern="${folder//\*/.*}"
            find_cmd+=" -not -regex \".*$regex_pattern.*\" -not -regex \".*$regex_pattern\""
        else
            # Standard folder exclusion
            find_cmd+=" -not -path \"*/$folder/*\" -not -path \"*/$folder\""
        fi
    done
    
    # Add prune conditions for default excluded folders
    for folder in "${EXCLUDED_FOLDERS[@]}"; do
        find_cmd+=" -not -path \"*/$folder/*\" -not -path \"*/$folder\""
    done
    
    # Execute the find command with timeout protection
    local count=0
    local timeout_seconds=60
    
    # Wrap the find command with timeout if available
    if command -v timeout &>/dev/null; then
        find_cmd="timeout $timeout_seconds $find_cmd"
    fi
    
    # Print the file collection started message
    echo "   Collecting files (this may take a moment)..."
    
    # Use process substitution with timeout protection
    while IFS= read -r file; do
        # Skip excluded files
        local basename=$(basename "$file")
        local exclude=false
        
        for pattern in "${EXCLUDED_FILES[@]}"; do
            if [[ "$basename" == $pattern ]]; then
                exclude=true
                break
            fi
        done
        
        if [[ "$exclude" == "false" ]]; then
            eval "$output_array+=(\"$file\")"
            ((count++))
            
            # Show progress indicator every 100 files
            if [[ $((count % 100)) -eq 0 ]]; then
                echo -ne "   Found $count files so far...\r"
            fi
        fi
    done < <(eval "$find_cmd" 2>/dev/null || echo "ERROR_TIMEOUT")
    
    # Check if we got a timeout
    if [[ ${#files[@]} -eq 0 && "$count" -eq 0 ]]; then
        echo "   ⚠️ File collection may have timed out or failed. Using alternative method."
        # Fall back to a simplified find without gitignore for safety
        local simple_find="find \"$dir\" -type f -path \"$dir\" | head -n 1000"
        while IFS= read -r file; do
            eval "$output_array+=(\"$file\")"
            ((count++))
        done < <(eval "$simple_find" 2>/dev/null)
    fi
    
    echo "   Found $count files after folder exclusion filtering"
}