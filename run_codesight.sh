#!/bin/bash
# Simple script to run codesight from the .codesight directory

# Create and activate a virtual environment using uv if it doesn't exist
if [ ! -d ".venv" ]; then
    uv venv .venv
fi

# Install dependencies using uv
uv pip install -r requirements.txt

# Run the main module
.venv/bin/python __main__.py "$@" 