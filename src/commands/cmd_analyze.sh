#!/bin/bash
# CodeSight analyze command - main entry point

# Main analyze command wrapper
function analyze_command() {
    # Load the analyze module if not already loaded
    if ! command -v analyze_codebase &>/dev/null; then
        source "$SCRIPT_DIR/src/commands/analyze.sh" || {
            echo -e "\033[31m❌ Error: Could not load analyze module\033[0m"
            return 1
        }
    fi
    
    # Call the module implementation
    analyze_codebase "$@"
}