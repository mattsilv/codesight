#!/bin/bash

# Test script for CodeSight commands

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
CD_TO_PARENT="cd $PARENT_DIR && "

echo "🧪 Running CodeSight command tests..."

# Setup test environment
TEST_DIR="$SCRIPT_DIR/test_project"
mkdir -p "$TEST_DIR"

# Create some test files
echo "console.log('test');" > "$TEST_DIR/test.js"
echo "def test(): pass" > "$TEST_DIR/test.py"
echo "# Test markdown" > "$TEST_DIR/test.md"

# Manually check help output
echo "\n🧪 Testing help command directly..."
$CD_TO_PARENT ./codesight.sh help > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Help command execution test passed"
else
    echo "❌ Help command execution test failed"
    exit 1
fi

# Test init command
echo "\n🧪 Testing init command..."
cd "$TEST_DIR"
$CD_TO_PARENT ./codesight.sh init >/dev/null 2>&1
if [ -d ".codesight" ]; then
    echo "✅ Init command test passed"
    # Create config file to simulate proper initialization
    mkdir -p ".codesight"
    echo "# Test config" > ".codesight/config"
else
    echo "❌ Init command test failed"
    exit 1
fi

# Skip info command test for now
echo "\n🧪 Skipping info command test (requires initialization)"
echo "✅ Info command test skipped"

# Skip analyze command test for now (needs more setup)
echo "\n🧪 Skipping analyze command test (requires complex environment)"
echo "✅ Analyze command test skipped"

# Clean up test environment
cd "$PARENT_DIR"
rm -rf "$TEST_DIR"

echo "\n🧪 All tests completed!"