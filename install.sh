#!/bin/bash
# Installation script for CodeSight

echo "Installing CodeSight..."

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create directory structure if it doesn't exist
echo "Setting up directory structure..."
mkdir -p "$SCRIPT_DIR/bin"
mkdir -p "$SCRIPT_DIR/src/commands/analyze"
mkdir -p "$SCRIPT_DIR/src/commands/visualize"
mkdir -p "$SCRIPT_DIR/src/core"
mkdir -p "$SCRIPT_DIR/src/utils"
mkdir -p "$SCRIPT_DIR/docs"
mkdir -p "$SCRIPT_DIR/tests"

# Make sure the main executable is present
if [[ ! -f "$SCRIPT_DIR/bin/codesight" ]]; then
    echo "Creating main executable..."
    cat > "$SCRIPT_DIR/bin/codesight" << 'EOF'
#!/bin/bash
# CodeSight - A shell-based tool to extract your codebase into a single file for LLM analysis
# Main entry point script

VERSION="0.1.9"

# Get script directory (where the script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Get current working directory (where the command is executed from)
CURRENT_DIR="$PWD"

# Source core modules
source "$SCRIPT_DIR/src/core/config.sh"
source "$SCRIPT_DIR/src/utils/common.sh"
source "$SCRIPT_DIR/src/utils/gitignore.sh"
source "$SCRIPT_DIR/src/core/update.sh"

# Source command modules
for command_file in "$SCRIPT_DIR"/src/commands/*.sh; do
    if [[ -f "$command_file" ]]; then
        source "$command_file"
    fi
done

# Source command subdirectories
for cmd_dir in "$SCRIPT_DIR"/src/commands/*/; do
    if [[ -d "$cmd_dir" ]]; then
        for cmd_file in "$cmd_dir"*.sh; do
            if [[ -f "$cmd_file" ]]; then
                source "$cmd_file"
            fi
        done
    fi
done

# Main function
function main() {
    if [[ $# -eq 0 ]]; then
        # No command provided - default to analyze on current directory
        echo "🔍 Running CodeSight analyze on current directory..."
        analyze_codebase
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
        visualize)
            visualize_command "$@"
            ;;
        version)
            echo "CodeSight version $VERSION"
            ;;
        update)
            echo "Checking for updates..."
            perform_update_check
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
EOF
fi

# Make all shell scripts executable
find "$SCRIPT_DIR" -name "*.sh" -type f -exec chmod +x {} \;
chmod +x "$SCRIPT_DIR/bin/codesight" 2>/dev/null || true

# Create symlink for backward compatibility
if [[ ! -L "$SCRIPT_DIR/codesight.sh" ]] && [[ -f "$SCRIPT_DIR/codesight.sh" ]]; then
    # Backup the old file if it exists and is not a symlink
    cp "$SCRIPT_DIR/codesight.sh" "$SCRIPT_DIR/codesight.sh.bak"
    rm "$SCRIPT_DIR/codesight.sh"
    ln -s "$SCRIPT_DIR/bin/codesight" "$SCRIPT_DIR/codesight.sh"
    echo "Created symlink for backward compatibility"
elif [[ ! -e "$SCRIPT_DIR/codesight.sh" ]]; then
    ln -s "$SCRIPT_DIR/bin/codesight" "$SCRIPT_DIR/codesight.sh"
    echo "Created symlink for backward compatibility"
fi

# Get the full command path
FULL_COMMAND="$SCRIPT_DIR/bin/codesight"

echo "Installation complete!"
echo ""
echo "You can run CodeSight from any directory using this command:"
echo "$FULL_COMMAND"
echo ""

# Copy to clipboard if possible
if command -v pbcopy &>/dev/null || command -v xclip &>/dev/null || command -v clip.exe &>/dev/null; then
    if command -v pbcopy &>/dev/null; then
        echo "$FULL_COMMAND" | pbcopy
    elif command -v xclip &>/dev/null; then
        echo "$FULL_COMMAND" | xclip -selection clipboard
    elif command -v clip.exe &>/dev/null; then
        echo "$FULL_COMMAND" | clip.exe
    fi
    echo "✅ Command copied to clipboard"
fi

echo ""
echo "Would you like to set up an alias for easier use? (y/n)"
read -r setup_alias

if [[ "$setup_alias" == "y" || "$setup_alias" == "Y" ]]; then
    # Run the setup_alias script
    "$SCRIPT_DIR/setup_alias.sh"
else
    echo ""
    echo "You can set up an alias later by running:"
    echo "./setup_alias.sh"
    echo ""
    echo "See README.md and docs/setup_guide.md for more details"
fi