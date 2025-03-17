#!/bin/bash
# Analyze command functionality
# This file now serves as a wrapper for the modular analyze functionality

# Source the main analysis module 
source "$SCRIPT_DIR/libs/analyze/analyze_main.sh"

# Function wrapper for backward compatibility
function analyze_codebase() {
    # Simply delegate to the modular implementation
    # This ensures backward compatibility with code that calls analyze_codebase
    analyze_codebase_modular "$@"
}