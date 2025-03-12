#!/bin/bash

# Script to add dependencies to the project using UV

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 PACKAGE_NAME [PACKAGE_NAME2 ...]"
    echo "Example: $0 pandas matplotlib"
    exit 1
fi

echo "Adding dependencies with UV..."

# Add each package specified
for package in "$@"; do
    echo "Adding $package..."
    uv add "$package"
done

# Update lockfile
echo "Updating lockfile..."
uv lock

echo "Dependencies added successfully!"
echo "To use these packages, run Python scripts with 'uv run python your_script.py'" 