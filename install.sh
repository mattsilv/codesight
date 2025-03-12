#!/bin/bash

# Simple installation script for CodeSight

# Ensure any error stops the script
set -e

echo "Installing CodeSight..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not installed. Please install Python 3 and try again."
    exit 1
fi

# Check if pip is installed
if ! command -v pip &> /dev/null; then
    echo "Error: pip is required but not installed. Please install pip and try again."
    exit 1
fi

# Install CodeSight from PyPI
pip install codesight

# Test if the command is available
if ! command -v codesight &> /dev/null; then
    echo "Warning: The codesight command isn't available in PATH."
    echo "You might need to restart your terminal or add your Python bin directory to PATH."
    
    # Get the Python user base directory
    PYTHON_USER_BIN=$(python3 -c "import site; print(site.USER_BASE + '/bin')")
    echo "You can try running it from: $PYTHON_USER_BIN/codesight"
else
    echo "CodeSight installed successfully!"
    echo "Try running 'codesight init' to initialize a new project."
fi

echo ""
echo "Usage Guide:"
echo "1. Go to your project directory: cd your-project-directory"
echo "2. Initialize CodeSight: codesight init"
echo "3. Analyze your codebase: codesight analyze"
echo "4. Find the generated file: .codesight/codebase_overview.txt"
echo "5. Copy this file content and paste it into your LLM for code review!"