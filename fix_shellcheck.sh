#!/bin/bash
# Script to fix common ShellCheck issues in CodeSight

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

# Check if shellcheck is installed
if ! command -v shellcheck &> /dev/null; then
    echo -e "${RED}❌ ShellCheck not found. Install with 'brew install shellcheck' (macOS) or your package manager${NC}"
    exit 1
fi

# Find all shell scripts
SHELL_SCRIPTS=$(find "$SCRIPT_DIR" -name "*.sh" -type f | sort)

echo -e "${CYAN}=== CodeSight ShellCheck Fixer ===${NC}"
echo -e "${YELLOW}This script will help fix common ShellCheck issues.${NC}"
echo -e "${YELLOW}Found $(echo "$SHELL_SCRIPTS" | wc -l | tr -d ' ') shell scripts to process.${NC}\n"

# Fix option
if [[ "$1" == "--auto-fix" ]]; then
    echo -e "${YELLOW}Auto-fix mode enabled. Fixing common issues...${NC}\n"

    for script in $SHELL_SCRIPTS; do
        BASENAME=$(basename "$script")
        echo -e "Processing $BASENAME..."
        
        # Create backup
        cp "$script" "$script.bak"
        
        # Fix SC2028: echo with escape sequences -> printf
        sed -i.tmp -E 's/echo "\\n/printf "\\n/g' "$script"
        sed -i.tmp -E 's/echo -e "\\n/printf "\\n/g' "$script"
        
        # Fix SC2164: Unsafe cd -> cd with || exit
        sed -i.tmp -E 's/^([[:space:]]*)cd ([^|]+)$/\1cd \2 || exit 1/g' "$script"
        
        # Fix SC2181: $? check -> direct command check
        sed -i.tmp -E 's/if \[ \$\? -eq 0 \]; then/if command_status=$?; [ "$command_status" -eq 0 ]; then/g' "$script"
        
        # Remove temporary files
        rm -f "$script.tmp"
        
        # Check if fixes worked
        if shellcheck -Calways "$script" &> /dev/null; then
            echo -e "  ${GREEN}✅ Fixed successfully${NC}"
            rm -f "$script.bak"
        else
            echo -e "  ${YELLOW}⚠️ Some issues remain. Restoring backup.${NC}"
            mv "$script.bak" "$script"
        fi
    done
    
    echo -e "\n${YELLOW}Auto-fix completed. Some issues may still need manual attention.${NC}"
    echo -e "${YELLOW}Review your changes with 'git diff' and run shellcheck manually.${NC}"
    
else
    # Check-only mode (default)
    echo -e "${YELLOW}Running in check-only mode. Use --auto-fix for automatic fixing.${NC}\n"
    
    cat << 'EOF'
Common ShellCheck issues and how to fix them:

1. SC2028: echo may not expand escape sequences
   Change: echo "\n..." → printf "\n..."

2. SC2164: cd without error handling
   Change: cd dir → cd dir || exit 1

3. SC2181: Checking $? instead of command directly
   Change: command; if [ $? -eq 0 ] → if command

4. SC1091: Not following sourced files
   Fix: Add # shellcheck source=./path/to/actual/file.sh above source lines
   
5. SC2155: Declare and assign separately
   Change: local var=$(cmd) → local var; var=$(cmd)

Run with --auto-fix to attempt automatic fixes.
EOF
    
    echo -e "\n${YELLOW}Current ShellCheck status:${NC}"
    for script in $SHELL_SCRIPTS; do
        BASENAME=$(basename "$script")
        if shellcheck -Calways "$script" &> /dev/null; then
            echo -e "${GREEN}✅ $BASENAME: No issues${NC}"
        else
            COUNT=$(shellcheck -Calways "$script" 2>&1 | grep -c "^In ")
            echo -e "${RED}❌ $BASENAME: $COUNT issue(s)${NC}"
        fi
    done
fi

echo -e "\n${CYAN}=== ShellCheck Fixer Complete ===${NC}"
echo -e "${YELLOW}Read docs/shellcheck_guide.md for more information.${NC}"