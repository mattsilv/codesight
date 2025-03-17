#!/bin/bash
# File processing utilities for CodeSight analyze command

# Process a single file and add its content to the output
function process_file() {
    local file="$1"
    local max_lines="$2"
    local output_file="$3"
    local ultra_compact="$4"
    local abbreviate_headers="$5"
    local truncate_paths="$6"
    local short_date="$7"
    local ref_total_lines="$8"
    local ref_total_chars="$9"
    local ref_total_words="${10}"
    local ref_original_lines="${11}"
    local ref_original_chars="${12}"
    
    # Get relative path
    local rel_path="${file#$PWD/}"
    # If still absolute path, just use the file name
    if [[ "$rel_path" == /* ]]; then
        rel_path=$(basename "$file")
    fi
    
    # Truncate paths if configured
    if [[ "$truncate_paths" == "true" ]]; then
        # Keep only the last 2 path components
        rel_path=$(echo "$rel_path" | rev | cut -d'/' -f1-2 | rev)
    fi
    
    # Format date based on configuration
    if [[ "$short_date" == "true" ]]; then
        local mod_time=$(date -r "$file" "+%y%m%d")
    else
        local mod_time=$(date -r "$file" "+%Y-%m-%d")
    fi
    
    # Get file stats
    local file_lines=$(wc -l < "$file")
    local file_chars=$(wc -c < "$file")
    
    # Update original stats
    eval "$ref_original_lines+=($file_lines)"
    eval "$ref_original_chars+=($file_chars)"
    
    # Process file content
    if [[ $file_lines -gt $max_lines ]]; then
        local truncated="+"
        local content=$(head -n $max_lines "$file")
    else
        local truncated=""
        local content=$(cat "$file")
    fi
    
    # Clean content - more aggressive cleaning to reduce tokens
    local cleaned_content=$(echo "$content" | clean_content)
    
    # Update processed stats
    local processed_lines=$(echo "$cleaned_content" | wc -l)
    local processed_chars=$(echo "$cleaned_content" | wc -c)
    local processed_words=$(echo "$cleaned_content" | wc -w)
    
    eval "$ref_total_lines+=($processed_lines)"
    eval "$ref_total_chars+=($processed_chars)"
    eval "$ref_total_words+=($processed_words)"
    
    # Write to output file based on configuration
    if [[ "$ultra_compact" == "true" ]]; then
        # Ultra compact format
        echo -e ">$rel_path" >> "$output_file"
        echo "W$processed_words M$mod_time$truncated" >> "$output_file"
    else
        # Standard format
        if [[ "$abbreviate_headers" == "true" ]]; then
            echo -e ">$rel_path" >> "$output_file"
            echo "# Words: $processed_words | Modified: $mod_time$truncated" >> "$output_file"
        else
            echo -e "# File: $rel_path" >> "$output_file"
            echo "# Words: $processed_words | Lines: $processed_lines | Modified: $mod_time$truncated" >> "$output_file"
        fi
    fi
    
    echo "\`\`\`" >> "$output_file"
    echo "$cleaned_content" >> "$output_file"
    echo "\`\`\`" >> "$output_file"
    echo "" >> "$output_file"
}

# Process multiple files and write to output
function process_files() {
    local files_array_name="$1"
    local max_lines="$2" 
    local output_file="$3"
    local ultra_compact="${4:-false}"
    local abbreviate_headers="${5:-false}"
    local truncate_paths="${6:-false}"
    local short_date="${7:-true}"
    
    echo "📝 Generating codebase overview..."
    
    # Initialize variables for statistics
    local total_chars=0
    local total_lines=0
    local total_words=0
    local original_chars=0
    local original_lines=0
    
    # Get the files array
    eval "local files=(\"\${$files_array_name[@]}\")"
    local file_counter=0
    
    for file in "${files[@]}"; do
        ((file_counter++))
        echo -ne "   Processing file $file_counter of ${#files[@]}...\r"
        
        # Process each file
        process_file "$file" "$max_lines" "$output_file" "$ultra_compact" "$abbreviate_headers" \
            "$truncate_paths" "$short_date" "total_lines" "total_chars" "total_words" \
            "original_lines" "original_chars"
    done
    
    # Return statistics via nameref variables
    echo ""
    
    # Return statistics in a standardized format
    echo "$total_lines|$total_chars|$total_words|$original_lines|$original_chars"
}