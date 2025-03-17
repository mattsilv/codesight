#!/bin/bash
# CodeSight analyze command
# Main entry point for the analyze functionality

# Source analyze submodules
source "$SCRIPT_DIR/src/commands/analyze/analyzer.sh"
source "$SCRIPT_DIR/src/commands/analyze/collector.sh"
source "$SCRIPT_DIR/src/commands/analyze/processor.sh"
source "$SCRIPT_DIR/src/commands/analyze/formatter.sh"

# Main analyze command wrapper
function analyze_codebase() {
    # Call the modular implementation
    analyze_codebase_modular "$@"
}