#!/usr/bin/env python3
"""
Main entry point for CodeSight.
When run directly as a script, this file provides CLI functionality.
For proper package use, use 'codesight' command after installation.
"""
import os
import argparse
import sys
from pathlib import Path

# Import modules from the codesight package
from codesight import cli
from codesight import config
from codesight import core
from codesight import terminal
from codesight import exclusions

def main():
    """Main entry point for the CodeSight tool"""
    # Use the CLI from the codesight package
    cli.main()

if __name__ == "__main__":
    main() 