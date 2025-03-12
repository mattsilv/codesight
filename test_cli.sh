#!/bin/bash

# Test the codesight CLI using UV

echo "Testing CodeSight CLI with UV..."

# Create a test project directory
mkdir -p test_project_direct
cd test_project_direct

echo "Testing in $(pwd)"

# Run the CLI module with UV
echo -e "\nCodeSight installation information:"
uv run codesight info

# Run the initialization command
echo -e "\nInitializing codesight project:"
uv run codesight init

# List the contents to verify .codesight directory was created
echo -e "\nDirectory contents after initialization:"
ls -la

# Check the contents of the .codesight directory
echo -e "\nContents of .codesight directory:"
ls -la .codesight/

# Return to the original directory
cd ..

echo -e "\nTest complete. The .codesight directory should be created in the test_project_direct folder." 