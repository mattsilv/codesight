#!/usr/bin/env python3
"""
Main entry point for CodeSight.
When run directly as a script, this file provides CLI functionality.
For proper package use, use 'codesight' command after installation.
"""
import sys
from codesight import cli
from codesight import __version__

def main():
    """Main entry point for the CodeSight tool"""
    # Handle --version flag specifically
    if len(sys.argv) > 1 and sys.argv[1] == "--version":
        print(f"codesight version {__version__}")
        return
        
    # Use the CLI from the codesight package
    cli.main()

if __name__ == "__main__":
    main() 