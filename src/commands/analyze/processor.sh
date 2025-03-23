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
    
    # Update original stats - safer approach with nameref when possible
    if [[ "${BASH_VERSINFO[0]}" -ge 4 && "${BASH_VERSINFO[1]}" -ge 3 ]]; then
        declare -n original_lines_ref="$ref_original_lines"
        declare -n original_chars_ref="$ref_original_chars"
        original_lines_ref+=($file_lines)
        original_chars_ref+=($file_chars)
    else
        # Fallback to eval for older bash versions
        eval "$ref_original_lines+=($file_lines)"
        eval "$ref_original_chars+=($file_chars)"
    fi
    
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
    
    # Safer approach with nameref when possible
    if [[ "${BASH_VERSINFO[0]}" -ge 4 && "${BASH_VERSINFO[1]}" -ge 3 ]]; then
        declare -n total_lines_ref="$ref_total_lines"
        declare -n total_chars_ref="$ref_total_chars"
        declare -n total_words_ref="$ref_total_words"
        total_lines_ref+=($processed_lines)
        total_chars_ref+=($processed_chars)
        total_words_ref+=($processed_words)
    else
        # Fallback to eval for older bash versions
        eval "$ref_total_lines+=($processed_lines)"
        eval "$ref_total_chars+=($processed_chars)"
        eval "$ref_total_words+=($processed_words)"
    fi
    
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
    
    # Check if we can use GNU parallel for faster processing
    local use_parallel=false
    if command -v parallel &>/dev/null; then
        use_parallel=true
        echo "   Using parallel processing for faster execution"
    fi
    
    # Initialize variables for statistics
    local total_chars=0
    local total_lines=0
    local total_words=0
    local original_chars=0
    local original_lines=0
    
    # Get the files array - safer approach with nameref
    local files
    if [[ "${BASH_VERSINFO[0]}" -ge 4 && "${BASH_VERSINFO[1]}" -ge 3 ]]; then
        declare -n files_ref="$files_array_name"
        files=("${files_ref[@]}")
    else
        # Fallback to eval for older bash versions
        eval "files=(\"\${$files_array_name[@]}\")" 
    fi
    local file_counter=0
    
    if [[ "$use_parallel" == "true" ]]; then
        # Create a temp directory for parallel processing
        local temp_dir="/tmp/codesight_parallel_processing"
        mkdir -p "$temp_dir"
        
        # Create a temp file for each file to process
        > "$output_file"  # Initialize the output file
        local stats_file="$temp_dir/stats.txt"
        > "$stats_file"   # Initialize the stats file
        
        # Create the parallel worker script
        local worker_script="$temp_dir/process_file.sh"
        cat > "$worker_script" << 'EOF'
#!/bin/bash
file="$1"
max_lines="$2"
output_chunk="$3"
stats_file="$4"
ultra_compact="$5"
abbreviate_headers="$6"
truncate_paths="$7"
short_date="$8"
file_index="$9"
script_dir="${10}"

# Source required functions
source "$script_dir/src/commands/analyze/analyzer.sh"

# Get relative path
rel_path="${file#$PWD/}"
if [[ "$rel_path" == /* ]]; then
    rel_path=$(basename "$file")
fi

# Truncate paths if configured
if [[ "$truncate_paths" == "true" ]]; then
    rel_path=$(echo "$rel_path" | rev | cut -d'/' -f1-2 | rev)
fi

# Format date
if [[ "$short_date" == "true" ]]; then
    mod_time=$(date -r "$file" "+%y%m%d")
else
    mod_time=$(date -r "$file" "+%Y-%m-%d")
fi

# Get file stats
file_lines=$(wc -l < "$file")
file_chars=$(wc -c < "$file")

# Process file content
if [[ $file_lines -gt $max_lines ]]; then
    truncated="+"
    content=$(head -n $max_lines "$file")
else
    truncated=""
    content=$(cat "$file")
fi

# Clean content
cleaned_content=$(echo "$content" | clean_content)

# Get processed stats
processed_lines=$(echo "$cleaned_content" | wc -l)
processed_chars=$(echo "$cleaned_content" | wc -c)
processed_words=$(echo "$cleaned_content" | wc -w)

# Write stats to the stats file (with file index for ordering)
echo "$file_index|$processed_lines|$processed_chars|$processed_words|$file_lines|$file_chars" >> "$stats_file"

# Write to output chunk based on configuration
if [[ "$ultra_compact" == "true" ]]; then
    echo -e ">$rel_path" > "$output_chunk"
    echo "W$processed_words M$mod_time$truncated" >> "$output_chunk"
else
    if [[ "$abbreviate_headers" == "true" ]]; then
        echo -e ">$rel_path" > "$output_chunk"
        echo "# Words: $processed_words | Modified: $mod_time$truncated" >> "$output_chunk"
    else
        echo -e "# File: $rel_path" > "$output_chunk"
        echo "# Words: $processed_words | Lines: $processed_lines | Modified: $mod_time$truncated" >> "$output_chunk"
    fi
fi

echo "\`\`\`" >> "$output_chunk"
echo "$cleaned_content" >> "$output_chunk"
echo "\`\`\`" >> "$output_chunk"
echo "" >> "$output_chunk"
EOF
        chmod +x "$worker_script"
        
        # Process files in parallel
        local parallel_cmd=""
        local index=0
        for file in "${files[@]}"; do
            local output_chunk="$temp_dir/chunk_$index.txt"
            parallel_cmd+="$worker_script '$file' $max_lines '$output_chunk' '$stats_file' $ultra_compact $abbreviate_headers $truncate_paths $short_date $index '$SCRIPT_DIR' & "
            ((index++))
        done
        
        # Execute all processes and wait for completion
        eval "$parallel_cmd wait"
        
        # Combine output chunks in order
        for ((i=0; i<${#files[@]}; i++)); do
            if [[ -f "$temp_dir/chunk_$i.txt" ]]; then
                cat "$temp_dir/chunk_$i.txt" >> "$output_file"
            fi
        done
        
        # Process stats file
        if [[ -f "$stats_file" ]]; then
            while IFS='|' read -r _ lines chars words orig_lines orig_chars; do
                ((total_lines+=lines))
                ((total_chars+=chars))
                ((total_words+=words))
                ((original_lines+=orig_lines))
                ((original_chars+=orig_chars))
            done < "$stats_file"
        fi
        
        # Clean up temp files
        rm -rf "$temp_dir"
    else
        # Serial processing (original approach)
        for file in "${files[@]}"; do
            ((file_counter++))
            echo -ne "   Processing file $file_counter of ${#files[@]}...\r"
            
            # Process each file
            process_file "$file" "$max_lines" "$output_file" "$ultra_compact" "$abbreviate_headers" \
                "$truncate_paths" "$short_date" "total_lines" "total_chars" "total_words" \
                "original_lines" "original_chars"
        done
    fi
    
    # Return statistics in a standardized format
    echo "$total_lines|$total_chars|$total_words|$original_lines|$original_chars"
}