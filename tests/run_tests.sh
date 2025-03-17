#!/bin/bash

# Main test runner for CodeSight

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== 🧪 Running CodeSight Test Suite ===\n"

# Make sure the test scripts are executable
chmod +x "$SCRIPT_DIR/test_commands.sh"
chmod +x "$SCRIPT_DIR/test_utils.sh"
chmod +x "$SCRIPT_DIR/test_dogfood.sh"
chmod +x "$SCRIPT_DIR/test_collection_coverage.sh"

# Run command tests
"$SCRIPT_DIR/test_commands.sh"
COMMAND_RESULT=$?

echo ""

# Run utility tests
"$SCRIPT_DIR/test_utils.sh"
UTIL_RESULT=$?

echo ""

# Run dogfooding tests
"$SCRIPT_DIR/test_dogfood.sh"
DOGFOOD_RESULT=$?

echo ""

# Run collection coverage tests
"$SCRIPT_DIR/test_collection_coverage.sh"
COVERAGE_RESULT=$?

echo -e "\n=== 🧪 Test Results Summary ==="

if [ $COMMAND_RESULT -eq 0 ] && [ $UTIL_RESULT -eq 0 ] && [ $DOGFOOD_RESULT -eq 0 ] && [ $COVERAGE_RESULT -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed!"
    exit 1
fi
