#!/bin/bash
# Wrapper script for CodeSight
# This script properly resolves the path to bin/codesight

# Get the absolute path to this wrapper script
WRAPPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute the actual script with all arguments
exec "$WRAPPER_DIR/bin/codesight" "$@"