#!/bin/bash
# Common utilities for CodeSight

# ASCII logo for CodeSight
CODESIGHT_LOGO=" ██████╗ ██████╗ ██████╗ ███████╗███████╗██╗ ██████╗ ██╗  ██╗████████╗
██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝██║██╔════╝ ██║  ██║╚══██╔══╝
██║     ██║   ██║██║  ██║█████╗  ███████╗██║██║  ███╗███████║   ██║   
██║     ██║   ██║██║  ██║██╔══╝  ╚════██║██║██║   ██║██╔══██║   ██║   
╚██████╗╚██████╔╝██████╔╝███████╗███████║██║╚██████╔╝██║  ██║   ██║   
 ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   "

# Display the CodeSight logo
function display_logo() {
    # Only display logo once per session using a temporary file as a flag
    local logo_shown_file="/tmp/codesight_logo_shown"
    local current_session_id="$(date +%Y%m%d)"
    
    # Check if we already showed the logo this session
    if [[ -f "$logo_shown_file" ]] && [[ "$(cat "$logo_shown_file")" == "$current_session_id" ]]; then
        return 0
    fi
    
    # If TERM is not dumb and we're not in a pipeline, show the logo with color
    if [[ "$TERM" != "dumb" ]] && [[ -t 1 ]]; then
        echo -e "\033[0;36m$CODESIGHT_LOGO\033[0m"
        echo "" # Add a blank line for spacing
    fi
    
    # Mark logo as shown for this session
    echo "$current_session_id" > "$logo_shown_file"
}

# Print colored text
function print_color() {
    local color="$1"
    local text="$2"
    
    case "$color" in
        "red")
            echo -e "\033[0;31m$text\033[0m"
            ;;
        "green")
            echo -e "\033[0;32m$text\033[0m"
            ;;
        "yellow")
            echo -e "\033[0;33m$text\033[0m"
            ;;
        "blue")
            echo -e "\033[0;34m$text\033[0m"
            ;;
        "magenta")
            echo -e "\033[0;35m$text\033[0m"
            ;;
        "cyan")
            echo -e "\033[0;36m$text\033[0m"
            ;;
        *)
            echo "$text"
            ;;
    esac
}

# Print a success message
function print_success() {
    print_color "green" "✅ $1"
}

# Print an error message
function print_error() {
    print_color "red" "❌ $1"
}

# Print a warning message
function print_warning() {
    print_color "yellow" "⚠️ $1"
}

# Print an info message
function print_info() {
    print_color "blue" "ℹ️ $1"
}

# Check if a command exists
function command_exists() {
    command -v "$1" &>/dev/null
}

# Get absolute path
function get_absolute_path() {
    local path="$1"
    
    # If already absolute, return as is
    if [[ "$path" == /* ]]; then
        echo "$path"
        return
    fi
    
    # Convert to absolute path
    echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
}

# Get relative path
function get_relative_path() {
    local target="$1"
    local base="${2:-$PWD}"
    
    # Get absolute paths
    local target_abs=$(get_absolute_path "$target")
    local base_abs=$(get_absolute_path "$base")
    
    # If they're the same, return "."
    if [[ "$target_abs" == "$base_abs" ]]; then
        echo "."
        return
    fi
    
    # If base is a prefix of target, return the remainder
    if [[ "$target_abs" == "$base_abs"/* ]]; then
        echo "${target_abs#$base_abs/}"
        return
    fi
    
    # Otherwise, use Python if available for a more robust solution
    if command_exists python; then
        python -c "import os.path; print(os.path.relpath('$target_abs', '$base_abs'))"
        return
    fi
    
    # Fallback to just returning the basename
    basename "$target_abs"
}