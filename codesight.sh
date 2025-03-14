#!/bin/bash
# CodeSight - A shell-based tool to extract your codebase into a single file for LLM analysis
# Main entry point script

VERSION="0.1.4"

# Get script directory (where the script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get current working directory (where the command is executed from)
CURRENT_DIR="$PWD"

# Source configuration and utilities
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils/common.sh"

# Source command modules
source "$SCRIPT_DIR/commands/init.sh"
source "$SCRIPT_DIR/commands/analyze.sh"
source "$SCRIPT_DIR/commands/info.sh"
source "$SCRIPT_DIR/commands/help.sh"

# Display help information
function show_help() {
    echo "Usage: ./codesight.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  init                   Initialize CodeSight in the current directory"
    echo "  analyze [directory]    Analyze codebase and generate overview (default: current dir)"
    echo "  info                   Display information about the configuration"
    echo "  help                   Show this help message"
    echo ""
    echo "Options for analyze:"
    echo "  --output FILE          Specify output file (default: .codesight/codebase_overview.txt)"
    echo "  --extensions \"EXT...\"  Space-separated list of file extensions (e.g. \".py .js .md\")"
    echo "  --max-lines N          Maximum lines per file before truncation (default: $MAX_LINES_PER_FILE)"
    echo "  --max-files N          Maximum files to include (default: $MAX_FILES)"
    echo "  --max-size N           Maximum file size in bytes (default: $MAX_FILE_SIZE)"
    echo ""
    echo "Examples:"
    echo "  ./codesight.sh init"
    echo "  ./codesight.sh analyze --extensions \".py .js .html\""
    echo "  ./codesight.sh analyze ~/myproject --output myproject_overview.txt"
}

# Initialize a new project
function init_project() {
    local force=false
    
    # Check for force flag
    if [[ "$1" == "--force" ]]; then
        force=true
    fi
    
    # Check if already initialized
    if [[ -d "$CURRENT_DIR/.codesight" && "$force" == "false" ]]; then
        echo "❌ Error: CodeSight already initialized in this directory."
        echo "   Use --force to reinitialize."
        return 1
    fi
    
    # Create directory
    mkdir -p "$CURRENT_DIR/.codesight"
    echo "✅ Created .codesight directory in $CURRENT_DIR"
    
    # Create config file
    cat > "$CURRENT_DIR/.codesight/config" << EOF
# CodeSight configuration
# Created on $(date)

# File extensions to include
FILE_EXTENSIONS="$FILE_EXTENSIONS"

# Maximum number of lines per file
MAX_LINES_PER_FILE=$MAX_LINES_PER_FILE

# Maximum number of files to include
MAX_FILES=$MAX_FILES

# Maximum file size in bytes
MAX_FILE_SIZE=$MAX_FILE_SIZE

# Skip binary files
SKIP_BINARY_FILES=$SKIP_BINARY_FILES

# Excluded file patterns
EXCLUDED_FILES=(
${EXCLUDED_FILES[@]/#/    \"}
${EXCLUDED_FILES[@]/%/\"}
)

# Excluded folder patterns
EXCLUDED_FOLDERS=(
${EXCLUDED_FOLDERS[@]/#/    \"}
${EXCLUDED_FOLDERS[@]/%/\"}
)
EOF
    
    echo "✅ Created configuration file"
    echo "✨ CodeSight initialized successfully!"
    echo "   Run './codesight.sh analyze' to analyze your codebase"
}

# Show project info
function show_info() {
    if [[ ! -d "$CURRENT_DIR/.codesight" ]]; then
        echo "❌ Error: CodeSight not initialized in this directory."
        echo "   Run '$SCRIPT_DIR/codesight.sh init' first."
        return 1
    fi
    
    echo "CodeSight Project Information"
    echo "----------------------------"
    echo "Working directory: $CURRENT_DIR"
    
    if [[ -f "$CURRENT_DIR/.codesight/config" ]]; then
        echo "Configuration:"
        grep -v "^#" "$CURRENT_DIR/.codesight/config" | grep -v "^$" | sed 's/^/  /'
    else
        echo "  No configuration file found"
    fi
    
    # Check for both possible output file locations
    if [[ -f "$CURRENT_DIR/codesight.txt" ]]; then
        local overview_size=$(du -h "$CURRENT_DIR/codesight.txt" | cut -f1)
        local overview_lines=$(wc -l < "$CURRENT_DIR/codesight.txt")
        local overview_date=$(date -r "$CURRENT_DIR/codesight.txt" "+%Y-%m-%d %H:%M:%S")
        
        echo ""
        echo "Last Analysis:"
        echo "  File: codesight.txt"
        echo "  Size: $overview_size"
        echo "  Lines: $overview_lines"
        echo "  Date: $overview_date"
    elif [[ -f "$CURRENT_DIR/.codesight/codebase_overview.txt" ]]; then
        local overview_size=$(du -h "$CURRENT_DIR/.codesight/codebase_overview.txt" | cut -f1)
        local overview_lines=$(wc -l < "$CURRENT_DIR/.codesight/codebase_overview.txt")
        local overview_date=$(date -r "$CURRENT_DIR/.codesight/codebase_overview.txt" "+%Y-%m-%d %H:%M:%S")
        
        echo ""
        echo "Last Analysis:"
        echo "  File: .codesight/codebase_overview.txt"
        echo "  Size: $overview_size"
        echo "  Lines: $overview_lines"
        echo "  Date: $overview_date"
    fi
}

# Analyze the codebase
function analyze_codebase() {
    local directory="$CURRENT_DIR"
    local output_file="$CURRENT_DIR/codesight.txt"
    local extensions="$FILE_EXTENSIONS"
    local max_lines=$MAX_LINES_PER_FILE
    local max_files=$MAX_FILES
    local max_size=$MAX_FILE_SIZE
    
    # Parse arguments
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
    IFS=' ' read -ra ext_array <<< "$extensions"
    
    # Build find command for extensions
    find_cmd="find \"$directory\" -type f"
    for ext in "${ext_array[@]}"; do
        find_cmd+=" -o -name \"*$ext\""
    done
    find_cmd+=" | sort"
    
    # Find files and filter excluded patterns
    local files=()
    local total_files=0
    local included_files=0
    
    while IFS= read -r file; do
        ((total_files++))
        
        # Skip if exceeds max files
        if [[ ${#files[@]} -ge $max_files ]]; then
            continue
        fi
        
        # Get relative path
        local rel_path=$(realpath --relative-to="$PWD" "$file")
        
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
        
        # Skip if too large
        local file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
        if [[ $file_size -gt $max_size ]]; then
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
    
    echo "   Found $included_files files to include (from $total_files total)"
    
    # Generate overview
    echo "📝 Generating codebase overview..."
    
    # Initialize variables for statistics
    local total_chars=0
    local total_lines=0
    local total_words=0 # as token approximation
    local original_chars=0
    local original_lines=0
    
    # Start with an overview header
    cat > "$output_file" << EOF
# PROJECT OVERVIEW
Files included: ${#files[@]}
Extensions: $extensions
Generated: $(date)

EOF
    
    # File type statistics
    echo "# FILE TYPES" >> "$output_file"
    declare -A file_types
    
    for file in "${files[@]}"; do
        local ext=$(echo "$file" | grep -o '\.[^.]\+$')
        file_types["$ext"]=$((file_types["$ext"] + 1))
    done
    
    for ext in "${!file_types[@]}"; do
        echo "$ext: ${file_types[$ext]} files" >> "$output_file"
    done
    echo "" >> "$output_file"
    
    # File contents
    echo "# FILE CONTENTS" >> "$output_file"
    
    file_counter=0
    for file in "${files[@]}"; do
        ((file_counter++))
        echo -ne "   Processing file $file_counter of ${#files[@]}...\r"
        
        local rel_path=$(realpath --relative-to="$PWD" "$file")
        local mod_time=$(date -r "$file" "+%Y-%m-%d %H:%M:%S")
        
        # Get file stats
        local file_lines=$(wc -l < "$file")
        local file_chars=$(wc -c < "$file")
        local file_words=$(wc -w < "$file")
        
        # Update totals
        original_lines=$((original_lines + file_lines))
        original_chars=$((original_chars + file_chars))
        
        # Process file content
        if [[ $file_lines -gt $max_lines ]]; then
            local truncated=" (truncated)"
            local content=$(head -n $max_lines "$file")
            local content_lines=$max_lines
        else
            local truncated=""
            local content=$(cat "$file")
            local content_lines=$file_lines
        fi
        
        # Clean content
        local cleaned_content=$(echo "$content" | clean_content)
        
        # Update processed stats
        local processed_lines=$(echo "$cleaned_content" | wc -l)
        local processed_chars=$(echo "$cleaned_content" | wc -c)
        local processed_words=$(echo "$cleaned_content" | wc -w)
        
        total_lines=$((total_lines + processed_lines))
        total_chars=$((total_chars + processed_chars))
        total_words=$((total_words + processed_words))
        
        # Write to output file
        echo -e "\n## $rel_path" >> "$output_file"
        echo "Words: $processed_words, Last modified: $mod_time$truncated" >> "$output_file"
        echo '```' >> "$output_file"
        echo "$cleaned_content" >> "$output_file"
        echo '```' >> "$output_file"
    done
    
    # Calculate savings
    local char_savings=0
    local line_savings=0
    
    if [[ $original_chars -gt 0 ]]; then
        char_savings=$(echo "scale=1; (1 - $total_chars / $original_chars) * 100" | bc)
    fi
    
    if [[ $original_lines -gt 0 ]]; then
        line_savings=$(echo "scale=1; (1 - $total_lines / $original_lines) * 100" | bc)
    fi
    
    # Print summary
    echo ""
    echo "✅ Analysis complete!"
    echo "   Overview saved to: $output_file"
    echo ""
    echo "   Statistics:"
    echo "   - Files included: ${#files[@]}"
    echo "   - Characters: $total_chars (saved $char_savings%)"
    echo "   - Lines: $total_lines (saved $line_savings%)"
    echo "   - Words (token approximation): $total_words"
    
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

# Main function
function main() {
    if [[ $# -eq 0 ]]; then
        # No command provided - run default action
        echo "🚀 Running CodeSight..."
        
        # Check if already initialized
        if [[ ! -d "$CURRENT_DIR/.codesight" ]]; then
            echo "📂 Directory not initialized. Setting up CodeSight..."
            init_project
            
            if [[ $? -ne 0 ]]; then
                echo "❌ Initialization failed. Please check errors above."
                exit 1
            fi
            
            echo "✅ Initialization complete."
        fi
        
        # Run analyze with default settings
        echo "🔍 Analyzing codebase..."
        local output_file="$CURRENT_DIR/codesight.txt"
        analyze_codebase
        
        # Ensure the user knows what happened
        echo ""
        echo "✨ CodeSight process complete!"
        echo "📄 Output file: $output_file"
        
        # Confirm clipboard status
        if command -v pbcopy &>/dev/null; then
            echo "📋 Results copied to clipboard (macOS)"
        elif command -v xclip &>/dev/null; then
            echo "📋 Results copied to clipboard (Linux)"
        elif command -v clip.exe &>/dev/null; then
            echo "📋 Results copied to clipboard (Windows)"
        else
            echo "⚠️ Could not copy to clipboard - no clipboard tool found"
            echo "   Please manually copy the contents of the output file."
        fi
        
        exit 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        init)
            init_project "$@"
            ;;
        analyze)
            analyze_codebase "$@"
            ;;
        info)
            show_info
            ;;
        help)
            show_help
            ;;
        version)
            echo "CodeSight version $VERSION"
            ;;
        *)
            echo "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"