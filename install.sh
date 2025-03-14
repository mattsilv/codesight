#!/bin/bash
# Installation script for CodeSight

echo "Installing CodeSight..."

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create directory structure
mkdir -p "$SCRIPT_DIR/commands"
mkdir -p "$SCRIPT_DIR/utils"
mkdir -p "$SCRIPT_DIR/docs"

# Check all script files and make them executable
find "$SCRIPT_DIR" -name "*.sh" -type f -exec chmod +x {} \;

# Create the full command path
FULL_COMMAND="$SCRIPT_DIR/codesight.sh"

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