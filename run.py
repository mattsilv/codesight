#!/usr/bin/env python3
"""
Runner script for CodeSight.
This script allows running codesight from anywhere in the project.
"""
import os
import sys
import subprocess

def main():
    # Get path to the .codesight directory
    codesight_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Change working directory to .codesight
    os.chdir(codesight_dir)
    
    # Install dependencies with Poetry if needed
    try:
        # Check if Poetry is available
        subprocess.run(["poetry", "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        
        # Install dependencies with Poetry
        subprocess.run(["poetry", "install", "--no-root"], check=True)
        
        # Run main module with Poetry
        sys.exit(subprocess.call(["poetry", "run", "python", "__main__.py"] + sys.argv[1:]))
        
    except subprocess.CalledProcessError:
        print("Poetry not found. Trying to continue without it...")
        
        # Run main module directly as fallback
        from __main__ import main as codesight_main
        codesight_main()

if __name__ == "__main__":
    main() 