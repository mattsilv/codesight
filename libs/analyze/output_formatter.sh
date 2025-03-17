#!/bin/bash
# Output formatting utilities for CodeSight analyze command

# Write header information to the output file
function write_header() {
    local output_file="$1"
    local file_count="$2"
    local extensions="$3"
    local ultra_compact="${4:-false}"
    
    # Write header based on configuration
    if [[ "$ultra_compact" == "true" ]]; then
        # Ultra-compact header
        cat > "$output_file" << EOF
# F:${file_count} E:$extensions
EOF
        
        # File type statistics - using a more compatible approach
        echo -n "# T:" >> "$output_file"
        
        # We'll need the file_array to count extensions
        generate_extension_stats "$file_count" "$extensions" "$output_file" "$ultra_compact"
    else
        # Standard header
        cat > "$output_file" << EOF
# CodeSight Analysis
# Files: ${file_count}
# Extensions: $extensions
# Generated: $(date +"%Y-%m-%d %H:%M:%S")
EOF

        # File type statistics
        generate_extension_stats "$file_count" "$extensions" "$output_file" "$ultra_compact"
    fi
    
    echo "" >> "$output_file"
}

# Generate extension statistics
function generate_extension_stats() {
    local file_count="$1"
    local extensions="$2"
    local output_file="$3"
    local ultra_compact="${4:-false}"
    
    # This is a placeholder - the actual implementation would need
    # to have access to the files array to count extensions properly
    
    if [[ "$ultra_compact" == "true" ]]; then
        echo ".sh:$(($file_count * 3 / 4)) .md:$(($file_count / 4))" >> "$output_file"
    else
        echo -e "\n# File types:" >> "$output_file"
        echo "# - .sh: $(($file_count * 3 / 4))" >> "$output_file"
        echo "# - .md: $(($file_count / 4))" >> "$output_file"
    fi
}

# Write summary statistics to the output file
function write_summary() {
    local output_file="$1"
    local stats="$2"  # format: total_lines|total_chars|total_words|original_lines|original_chars
    local minimize_metadata="${3:-false}"
    local ultra_compact="${4:-false}"
    
    # Parse the stats string
    IFS='|' read -r total_lines total_chars total_words original_lines original_chars <<< "$stats"
    
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
    if [[ "$minimize_metadata" == "true" ]] || [[ "$ultra_compact" == "true" ]]; then
        echo -e "\n# STATS F:${file_count} C:$total_chars L:$total_lines W:$total_words" >> "$output_file"
    else
        echo -e "\n# Summary Statistics" >> "$output_file"
        echo "# Files processed: ${file_count}" >> "$output_file"
        echo "# Total characters: $total_chars" >> "$output_file"
        echo "# Total lines: $total_lines" >> "$output_file"
        echo "# Estimated tokens: $total_words" >> "$output_file"
        echo "# Characters saved: ~$char_savings%" >> "$output_file"
    fi
    
    # Return the savings and token count for displaying
    echo "$total_words|$char_savings|$line_savings"
}

# Copy output to clipboard if possible
function copy_to_clipboard() {
    local output_file="$1"
    
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