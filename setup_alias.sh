#!/bin/bash
# Setup script to automatically create an alias for CodeSight

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FULL_COMMAND="$SCRIPT_DIR/codesight.sh"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "Setting up CodeSight alias for Mac..."
    
    # Check if .zshrc exists
    if [[ -f "$HOME/.zshrc" ]]; then
        # Add alias to .zshrc if it doesn't already exist
        if ! grep -q "alias codesight=" "$HOME/.zshrc"; then
            echo "Adding alias to ~/.zshrc"
            echo "alias codesight=\"$FULL_COMMAND\"" >> "$HOME/.zshrc"
            echo "✅ Alias added to ~/.zshrc"
        else
            echo "⚠️ Alias already exists in ~/.zshrc"
        fi
        
        # Source the file to apply changes to current session
        echo "Reloading shell configuration..."
        source "$HOME/.zshrc" 2>/dev/null || echo "⚠️ Could not reload shell automatically. Please run: source ~/.zshrc"
        
        echo "✅ Setup complete! You can now use 'codesight' from any directory."
        echo "Try it now: codesight help"
    else
        echo "⚠️ ~/.zshrc not found. Creating it..."
        touch "$HOME/.zshrc"
        echo "alias codesight=\"$FULL_COMMAND\"" >> "$HOME/.zshrc"
        echo "✅ Created ~/.zshrc with CodeSight alias"
        echo "Please restart your terminal or run: source ~/.zshrc"
    fi
    
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows (Git Bash or similar)
    echo "Setting up CodeSight for Windows..."
    
    # For Windows, we'll create a batch file in the same directory
    echo "@echo off" > "$SCRIPT_DIR/codesight.bat"
    echo "\"$FULL_COMMAND\" %*" >> "$SCRIPT_DIR/codesight.bat"
    
    echo "✅ Created codesight.bat in the same directory"
    echo "You can copy this batch file to a location in your PATH to use 'codesight' from any directory."
    echo "Or use the full path: $FULL_COMMAND"
else
    # Other OS (Linux, etc.)
    echo "Detected non-Mac, non-Windows system."
    echo "Please add this alias manually to your shell profile:"
    echo "alias codesight=\"$FULL_COMMAND\""
fi 