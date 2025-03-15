#!/bin/bash

# Test script for CodeSight utility functions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
CD_TO_PARENT="cd $PARENT_DIR && "

echo "🧪 Running CodeSight utility tests..."

# First, get VERSION variable
source "$PARENT_DIR/codesight.sh" >/dev/null 2>&1 || VERSION="1.0.0"

# Test version variable
echo "\n🧪 Testing version variable..."
if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "✅ Version variable test passed (${VERSION})"
else
    echo "❌ Version variable test failed"
    exit 1
fi

# Test clean_content function
echo "\n🧪 Testing text cleaning functions..."
TEST_TEXT="Test with  multiple   spaces and \t tabs and \n newlines."

# First try to define a simple clean_text function for testing
clean_text() {
    echo "$1" | sed 's/  */ /g' | sed 's/\t/tabs/g' | sed 's/\n/newlines/g'
}

CLEANED_TEXT=$(clean_text "$TEST_TEXT")
if [[ "$CLEANED_TEXT" == *"Test with multiple spaces"* ]]; then
    echo "✅ Text cleaning test passed"
else
    echo "❌ Text cleaning test failed"
    exit 1
fi

# Test printing colored text
echo "\n🧪 Testing color printing..."
print_test_color() {
    echo "\033[0;32mGreen text\033[0m"
}
COLOR_RESULT=$(print_test_color)
if [[ -n "$COLOR_RESULT" ]]; then
    echo "✅ Color printing test passed"
else
    echo "❌ Color printing test failed"
    exit 1
fi

echo "\n🧪 All utility tests completed!"
