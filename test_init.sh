#!/bin/bash

# Create a test project directory
mkdir -p test_project
cd test_project

echo "Testing codesight init in $(pwd)"

# Make sure we can run the codesight command
which codesight || { echo "codesight command not found. Make sure it's installed properly."; exit 1; }

# Run the info command to see installation details
echo -e "\nCodeSight installation information:"
codesight info

# Run the initialization command
echo -e "\nInitializing codesight project:"
codesight init

# List the contents to verify .codesight directory was created
echo -e "\nDirectory contents after initialization:"
ls -la

# Check the contents of the .codesight directory
echo -e "\nContents of .codesight directory:"
ls -la .codesight/

# Return to the original directory
cd ..

echo -e "\nTest complete. The .codesight directory should be created in the test_project folder." 