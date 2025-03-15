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

        # Extract folder patterns (those ending with a slash or without a dot)
        if [[ "$line" == */ || "$line" != *.* ]]; then
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
    
    # Add prune conditions for gitignore folders
    for folder in "${GITIGNORE_FOLDERS[@]}"; do
        find_cmd+=" -not -path \"$dir/$folder/*\" -not -path \"$dir/$folder\""
    done
    
    # Add prune conditions for default excluded folders
    for folder in "${EXCLUDED_FOLDERS[@]}"; do
        find_cmd+=" -not -path \"*/$folder/*\" -not -path \"*/$folder\""
    done
    
    # Execute the find command
    local count=0
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
        fi
    done < <(eval "$find_cmd")
    
    echo "   Found $count files after folder exclusion filtering"
}