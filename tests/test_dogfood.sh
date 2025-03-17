#!/bin/bash
# Dogfooding/self-validation test for CodeSight
# This test ensures that the script can run in its own directory and validates path calculations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colored output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color

# Print header
echo -e "${YELLOW}=== 🍽️ Running Dogfooding Tests ===${NC}"
echo -e "${YELLOW}Testing script in its own directory to ensure paths are correct${NC}"

# Test 1: Validate SCRIPT_DIR calculation
echo -e "\n${YELLOW}Test 1: Validating path calculation in codesight.sh${NC}"
SCRIPT_DIR_TEST=$(grep -n "SCRIPT_DIR=" "$PROJECT_ROOT/codesight.sh" | head -1)

if [[ "$SCRIPT_DIR_TEST" == *"/.."* ]]; then
    echo -e "${RED}❌ FAIL: codesight.sh contains incorrect path calculation with '/..'${NC}"
    echo -e "   $SCRIPT_DIR_TEST"
    FAILURES=$((FAILURES+1))
else
    echo -e "${GREEN}✅ PASS: Path calculation looks correct${NC}"
fi

# Test 2: Validate that the script can run version command
echo -e "\n${YELLOW}Test 2: Testing version command execution${NC}"
VERSION_OUTPUT=$("$PROJECT_ROOT/codesight.sh" version 2>&1)
VERSION_EXIT_CODE=$?

if [[ $VERSION_EXIT_CODE -eq 0 && "$VERSION_OUTPUT" == *"version"* ]]; then
    echo -e "${GREEN}✅ PASS: Version command executed successfully${NC}"
    echo -e "   Output: $VERSION_OUTPUT"
else
    echo -e "${RED}❌ FAIL: Version command failed${NC}"
    echo -e "   Exit code: $VERSION_EXIT_CODE"
    echo -e "   Output: $VERSION_OUTPUT"
    FAILURES=$((FAILURES+1))
fi

# Test 3: Validate that the script can run help command
echo -e "\n${YELLOW}Test 3: Testing help command execution${NC}"
HELP_OUTPUT=$("$PROJECT_ROOT/codesight.sh" help 2>&1)
HELP_EXIT_CODE=$?

if [[ $HELP_EXIT_CODE -eq 0 && "$HELP_OUTPUT" == *"Usage"* ]]; then
    echo -e "${GREEN}✅ PASS: Help command executed successfully${NC}"
else
    echo -e "${RED}❌ FAIL: Help command failed${NC}"
    echo -e "   Exit code: $HELP_EXIT_CODE"
    echo -e "   Output: $HELP_OUTPUT"
    FAILURES=$((FAILURES+1))
fi

# Test 4: Check for basic directory structure
echo -e "\n${YELLOW}Test 4: Validating directory structure${NC}"
if [[ -d "$PROJECT_ROOT/src" && -d "$PROJECT_ROOT/src/commands" && -d "$PROJECT_ROOT/src/core" ]]; then
    echo -e "${GREEN}✅ PASS: Directory structure exists${NC}"
else
    echo -e "${RED}❌ FAIL: Directory structure is incorrect${NC}"
    echo -e "   Missing expected directories in $PROJECT_ROOT/src"
    FAILURES=$((FAILURES+1))
fi

# Results
echo -e "\n${YELLOW}=== 🍽️ Dogfooding Test Results ===${NC}"
if [[ $FAILURES -eq 0 ]]; then
    echo -e "${GREEN}✅ All dogfooding tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILURES dogfooding tests failed!${NC}"
    exit 1
fi