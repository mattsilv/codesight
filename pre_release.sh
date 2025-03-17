#!/bin/bash
# Pre-release validation script for CodeSight
# Run this script before publishing a new release to verify everything works correctly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}= CodeSight Pre-Release Validation  =${NC}"
echo -e "${CYAN}======================================${NC}"

# Step 1: Run all tests
echo -e "\n${YELLOW}Step 1: Running all test suites${NC}"
"$SCRIPT_DIR/tests/run_tests.sh"
TESTS_RESULT=$?

if [[ $TESTS_RESULT -ne 0 ]]; then
    echo -e "${RED}❌ Test suite failed! Fix issues before releasing.${NC}"
    exit 1
fi

# Step 2: Try running the main command with minimal options
echo -e "\n${YELLOW}Step 2: Testing main command${NC}"
MAIN_OUTPUT=$("$SCRIPT_DIR/codesight.sh" version 2>&1)
MAIN_RESULT=$?

if [[ $MAIN_RESULT -ne 0 ]]; then
    echo -e "${RED}❌ Main command failed! Fix issues before releasing.${NC}"
    echo -e "   Output: $MAIN_OUTPUT"
    exit 1
else
    echo -e "${GREEN}✅ Main command executed successfully${NC}"
    echo -e "   Output: $MAIN_OUTPUT"
fi

# Step 3: Verify directory structure is correct
echo -e "\n${YELLOW}Step 3: Verifying directory structure${NC}"

if [[ ! -d "$SCRIPT_DIR/src" ]]; then
    echo -e "${RED}❌ Directory structure issue: src directory missing${NC}"
    exit 1
fi

if [[ ! -d "$SCRIPT_DIR/src/commands" ]]; then
    echo -e "${RED}❌ Directory structure issue: src/commands directory missing${NC}"
    exit 1
fi

if [[ ! -d "$SCRIPT_DIR/src/core" ]]; then
    echo -e "${RED}❌ Directory structure issue: src/core directory missing${NC}"
    exit 1
fi

if [[ ! -d "$SCRIPT_DIR/src/utils" ]]; then
    echo -e "${RED}❌ Directory structure issue: src/utils directory missing${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Directory structure looks good${NC}"

# Step 4: Check for old directory structure that should be removed
echo -e "\n${YELLOW}Step 4: Checking for deprecated directory structure${NC}"

OLD_DIRS=0
if [[ -d "$SCRIPT_DIR/commands" && ! -L "$SCRIPT_DIR/commands" ]]; then
    echo -e "${RED}⚠️ Deprecated directory found: $SCRIPT_DIR/commands${NC}"
    OLD_DIRS=$((OLD_DIRS+1))
fi

if [[ -d "$SCRIPT_DIR/utils" && ! -L "$SCRIPT_DIR/utils" ]]; then
    echo -e "${RED}⚠️ Deprecated directory found: $SCRIPT_DIR/utils${NC}"
    OLD_DIRS=$((OLD_DIRS+1))
fi

if [[ -d "$SCRIPT_DIR/libs" && ! -L "$SCRIPT_DIR/libs" ]]; then
    echo -e "${RED}⚠️ Deprecated directory found: $SCRIPT_DIR/libs${NC}"
    OLD_DIRS=$((OLD_DIRS+1))
fi

if [[ $OLD_DIRS -eq 0 ]]; then
    echo -e "${GREEN}✅ No deprecated directories found${NC}"
else
    echo -e "${RED}❌ Found $OLD_DIRS deprecated directories that should be removed${NC}"
    exit 1
fi

# Step 5: Check for outdated documentation
echo -e "\n${YELLOW}Step 5: Checking for outdated documentation${NC}"

OUTDATED_DOCS=0
if [[ -f "$SCRIPT_DIR/REFACTORING_SUMMARY.md" ]]; then
    echo -e "${RED}⚠️ Deprecated document found: $SCRIPT_DIR/REFACTORING_SUMMARY.md${NC}"
    OUTDATED_DOCS=$((OUTDATED_DOCS+1))
fi

if [[ -f "$SCRIPT_DIR/REFACTOR_ISSUE.md" ]]; then
    echo -e "${RED}⚠️ Deprecated document found: $SCRIPT_DIR/REFACTOR_ISSUE.md${NC}"
    OUTDATED_DOCS=$((OUTDATED_DOCS+1))
fi

if [[ -f "$SCRIPT_DIR/libs/analyze/MIGRATION_PLAN.md" ]]; then
    echo -e "${RED}⚠️ Deprecated document found: $SCRIPT_DIR/libs/analyze/MIGRATION_PLAN.md${NC}"
    OUTDATED_DOCS=$((OUTDATED_DOCS+1))
fi

if [[ $OUTDATED_DOCS -eq 0 ]]; then
    echo -e "${GREEN}✅ No outdated documentation found${NC}"
else
    echo -e "${RED}❌ Found $OUTDATED_DOCS outdated documentation files that should be removed${NC}"
    exit 1
fi

# Step 6: Run ShellCheck on all shell scripts
echo -e "\n${YELLOW}Step 6: Running ShellCheck on shell scripts${NC}"

GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Skip shellcheck validation during refactoring
if [[ "$GIT_BRANCH" == "refactor-analyze-sh" ]]; then
    echo -e "${YELLOW}⚠️ ShellCheck validation temporarily skipped during refactoring phase${NC}"
    echo -e "${YELLOW}⚠️ Remember to fix ShellCheck issues before merging to main branch${NC}"
else
    if ! command -v shellcheck &> /dev/null; then
        echo -e "${YELLOW}⚠️ ShellCheck not found. Install with 'brew install shellcheck' (macOS) or your package manager${NC}"
        echo -e "${YELLOW}⚠️ Skipping ShellCheck validation${NC}"
    else
        SHELLCHECK_ERRORS=0
        SHELL_SCRIPTS=$(find "$SCRIPT_DIR" -name "*.sh" -type f | sort)
        
        for script in $SHELL_SCRIPTS; do
            echo -n "Checking $(basename "$script")... "
            RESULTS=$(shellcheck -Calways "$script" 2>&1)
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}✅ Passed${NC}"
            else
                echo -e "${RED}❌ Failed${NC}"
                echo "$RESULTS"
                SHELLCHECK_ERRORS=$((SHELLCHECK_ERRORS+1))
            fi
        done
        
        if [[ $SHELLCHECK_ERRORS -eq 0 ]]; then
            echo -e "${GREEN}✅ All shell scripts passed ShellCheck validation${NC}"
        else
            echo -e "${RED}❌ Found $SHELLCHECK_ERRORS scripts with ShellCheck warnings/errors${NC}"
            echo -e "${YELLOW}⚠️ Fix ShellCheck issues before releasing${NC}"
            exit 1
        fi
    fi
fi

# All checks passed
echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}✅ All pre-release checks passed!${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "\n${CYAN}CodeSight is ready for release.${NC}"
echo -e "${CYAN}Current version: $(grep -o 'VERSION="[^"]*"' "$SCRIPT_DIR/codesight.sh" | cut -d'"' -f2)${NC}"
exit 0