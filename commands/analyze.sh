#!/bin/bash
# Analyze command functionality

function analyze_codebase() {
    local directory="$CURRENT_DIR"
    local output_file="$CURRENT_DIR/codesight.txt"
    local extensions="$FILE_EXTENSIONS"
    local max_lines=$MAX_LINES_PER_FILE
    local max_files=$MAX_FILES
    local max_size=$MAX_FILE_SIZE
    
    # Parse arguments
    local use_gitignore=$RESPECT_GITIGNORE
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output)
                output_file="$2"
                shift 2
                ;;
            --extensions)
                extensions="$2"
                shift 2
                ;;
            --max-lines)
                max_lines="$2"
                shift 2
                ;;
            --max-files)
                max_files="$2"
                shift 2
                ;;
            --max-size)
                max_size="$2"
                shift 2
                ;;
            --gitignore)
                use_gitignore=true
                shift
                ;;
            --no-gitignore)
                use_gitignore=false
                shift
                ;;
            *)
                # Assume it's the directory
                if [[ ! "$1" == -* ]]; then
                    directory="$1"
                    shift
                else
                    echo "Unknown option: $1"
                    show_help
                    return 1
                fi
                ;;
        esac
    done
    
    # Check if initialized
    if [[ ! -d "$CURRENT_DIR/.codesight" ]]; then
        echo "❌ Error: CodeSight not initialized in this directory."
        echo "   Run '$SCRIPT_DIR/codesight.sh init' first."
        return 1
    fi
    
    # Load project config if exists
    if [[ -f "$CURRENT_DIR/.codesight/config" ]]; then
        source "$CURRENT_DIR/.codesight/config"
    fi
    
    # Create output directory
    mkdir -p "$(dirname "$output_file")"
    
    echo "🔍 Analyzing codebase in '$directory'..."
    echo "   Extensions: $extensions"
    echo "   Max lines: $max_lines, Max files: $max_files"
    
    # Collect files
    echo "📂 Collecting files..."

    # Check if using gitignore integration
    if [[ "$use_gitignore" == "true" && -f "$directory/.gitignore" ]]; then
        echo "   Using .gitignore patterns from $directory/.gitignore"
    fi
    
    # Build find command for extensions - properly structured
    IFS=' ' read -ra ext_array <<< "$extensions"
    find_cmd="find \"$directory\" -type f \\( -false"
    for ext in "${ext_array[@]}"; do
        find_cmd+=" -o -name \"*$ext\""
    done
    find_cmd+=" \\) | sort"
    
    # Find files and filter excluded patterns
    local files=()
    local total_files=0
    local included_files=0
    
    if [[ "$use_gitignore" == "true" && -f "$directory/.gitignore" ]]; then
        # Use the gitignore utility to collect files
        collect_files_respecting_gitignore "$directory" "$extensions" "files"
        total_files=${#files[@]}
        included_files=$total_files
        
        # Limit to max files if needed
        if [[ $total_files -gt $max_files ]]; then
            # Create a new array with limited entries
            local temp_files=("${files[@]:0:$max_files}")
            files=("${temp_files[@]}")
            included_files=$max_files
        fi
    else
        # Use traditional file collection method
        while IFS= read -r file; do
            ((total_files++))
            
            # Skip if exceeds max files
            if [[ ${#files[@]} -ge $max_files ]]; then
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
            
            # Skip if too large - handle different stat commands across platforms
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
            files+=("$file")
            ((included_files++))
            
            # Show progress
            if [[ $((included_files % 10)) -eq 0 ]]; then
                echo -ne "   Progress: $included_files files included...\r"
            fi
        done < <(eval $find_cmd)
    fi
    
    echo "   Found $included_files files to include (from $total_files total)"
    
    # Generate overview
    echo "📝 Generating codebase overview..."
    
    # Initialize variables for statistics
    local total_chars=0
    local total_lines=0
    local total_words=0 # as token approximation
    local original_chars=0
    local original_lines=0
    
    # Write header based on configuration
    if [[ "$ENABLE_ULTRA_COMPACT_FORMAT" == "true" ]]; then
        # Ultra-compact header
        cat > "$output_file" << EOF
# F:${#files[@]} E:$extensions
EOF
        
        # File type statistics - using a more compatible approach
        echo -n "# T:" >> "$output_file"
        
        # Count file extensions without associative arrays for better compatibility
        for ext in $(for file in "${files[@]}"; do echo "$file" | grep -o '\.[^.]\+$'; done | sort | uniq); do
            local count=0
            for file in "${files[@]}"; do
                if [[ "$file" == *"$ext" ]]; then
                    ((count++))
                fi
            done
            echo -n "$ext:$count " >> "$output_file"
        done
        echo "" >> "$output_file"
    else
        # Standard header
        cat > "$output_file" << EOF
# CodeSight Analysis
# Files: ${#files[@]}
# Extensions: $extensions
# Generated: $(date +"%Y-%m-%d %H:%M:%S")
EOF

        # File type statistics - using a more compatible approach
        echo -e "\n# File types:" >> "$output_file"
        
        # Count file extensions without associative arrays for better compatibility
        for ext in $(for file in "${files[@]}"; do echo "$file" | grep -o '\.[^.]\+$'; done | sort | uniq); do
            local count=0
            for file in "${files[@]}"; do
                if [[ "$file" == *"$ext" ]]; then
                    ((count++))
                fi
            done
            echo "# - $ext: $count" >> "$output_file"
        done
    fi
    
    echo "" >> "$output_file"
    
    file_counter=0
    for file in "${files[@]}"; do
        ((file_counter++))
        echo -ne "   Processing file $file_counter of ${#files[@]}...\r"
        
        local rel_path="${file#$PWD/}"
        # If still absolute path, just use the file name
        if [[ "$rel_path" == /* ]]; then
            rel_path=$(basename "$file")
        fi
        
        # Truncate paths if configured
        if [[ "$TRUNCATE_PATHS" == "true" ]]; then
            # Keep only the last 2 path components
            rel_path=$(echo "$rel_path" | rev | cut -d'/' -f1-2 | rev)
        fi
        
        # Format date based on configuration
        if [[ "$SHORT_DATE_FORMAT" == "true" ]]; then
            local mod_time=$(date -r "$file" "+%y%m%d")
        else
            local mod_time=$(date -r "$file" "+%Y-%m-%d")
        fi
        
        # Get file stats
        local file_lines=$(wc -l < "$file")
        local file_chars=$(wc -c < "$file")
        
        # Update totals
        original_lines=$((original_lines + file_lines))
        original_chars=$((original_chars + file_chars))
        
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
        
        total_lines=$((total_lines + processed_lines))
        total_chars=$((total_chars + processed_chars))
        total_words=$((total_words + processed_words))
        
        # Write to output file based on configuration
        if [[ "$ENABLE_ULTRA_COMPACT_FORMAT" == "true" ]]; then
            # Ultra compact format
            echo -e ">$rel_path" >> "$output_file"
            echo "W$processed_words M$mod_time$truncated" >> "$output_file"
        else
            # Standard format
            if [[ "$ABBREVIATE_HEADERS" == "true" ]]; then
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
    done
    
    # Calculate savings
    local char_savings=0
    local line_savings=0
    
    # Check if bc is available for precise calculations
    if command -v bc &>/dev/null; then
        if [[ $original_chars -gt 0 ]]; then
            char_savings=$(echo "scale=1; (1 - $total_chars / $original_chars) * 100" | bc)
        fi
        
        if [[ $original_lines -gt 0 ]]; then
            line_savings=$(echo "scale=1; (1 - $total_lines / $original_lines) * 100" | bc)
        fi
    else
        # Fallback to integer arithmetic if bc not available
        if [[ $original_chars -gt 0 ]]; then
            char_savings=$(( (original_chars - total_chars) * 100 / original_chars ))
        fi
        
        if [[ $original_lines -gt 0 ]]; then
            line_savings=$(( (original_lines - total_lines) * 100 / original_lines ))
        fi
    fi
    
    # Add summary to file based on configuration
    if [[ "$MINIMIZE_METADATA" == "true" ]] || [[ "$ENABLE_ULTRA_COMPACT_FORMAT" == "true" ]]; then
        echo -e "\n# STATS F:${#files[@]} C:$total_chars L:$total_lines W:$total_words" >> "$output_file"
    else
        echo -e "\n# Summary Statistics" >> "$output_file"
        echo "# Files processed: ${#files[@]}" >> "$output_file"
        echo "# Total characters: $total_chars" >> "$output_file"
        echo "# Total lines: $total_lines" >> "$output_file"
        echo "# Estimated tokens: $total_words" >> "$output_file"
        echo "# Characters saved: ~$char_savings%" >> "$output_file"
    fi
    
    # Print summary
    echo ""
    echo "✅ Analysis complete!"
    echo "   Overview saved to: $output_file"
    echo "   Stats: ${#files[@]} files, $total_words tokens (saved ~$char_savings%)"
    
    # Copy to clipboard if possible
    if command -v pbcopy &>/dev/null; then
        cat "$output_file" | pbcopy
        echo "   - Overview copied to clipboard (macOS)"
    elif command -v xclip &>/dev/null; then
        cat "$output_file" | xclip -selection clipboard
        echo "   - Overview copied to clipboard (Linux with xclip)"
    elif command -v clip.exe &>/dev/null; then
        cat "$output_file" | clip.exe
        echo "   - Overview copied to clipboard (Windows)"
    fi
}