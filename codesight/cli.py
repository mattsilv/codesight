#!/usr/bin/env python3

import os
import sys
import json
import click
import shutil
import importlib
from pathlib import Path
from . import __version__
from . import config
from . import core

@click.group()
def main():
    """CodeSight: Code analysis and visualization tool."""
    pass

@main.command()
@click.option('--force', is_flag=True, help='Force initialize even if a .codesight directory exists')
def init(force):
    """Initialize CodeSight in the current directory."""
    cwd = os.getcwd()
    codesight_dir = os.path.join(cwd, '.codesight')
    
    if os.path.exists(codesight_dir) and not force:
        click.echo(f".codesight directory already exists in {cwd}")
        click.echo("Use --force to reinitialize")
        return
    
    # Create .codesight directory
    os.makedirs(codesight_dir, exist_ok=True)
    click.echo(f"Created .codesight directory in {cwd}")
    
    # Create default configuration
    config = {
        "ignore_patterns": ["*.pyc", "__pycache__", "venv", ".git"],
        "analysis_depth": 3,
        "visualization_type": "dependency-graph"
    }
    
    with open(os.path.join(codesight_dir, 'codesight.config.json'), 'w') as f:
        json.dump(config, f, indent=2)
        click.echo(f"Created configuration file: {os.path.join(codesight_dir, 'codesight.config.json')}")
    
    # Copy template files from package data if they exist
    template_dir = Path(__file__).parent / 'templates'
    if template_dir.exists():
        files_copied = 0
        for template_file in template_dir.glob('*'):
            dest_path = os.path.join(codesight_dir, os.path.basename(template_file))
            shutil.copy(template_file, dest_path)
            files_copied += 1
            click.echo(f"Copied template: {os.path.basename(template_file)}")
        
        click.echo(f"Copied {files_copied} template files to {codesight_dir}")
    else:
        click.echo(f"Warning: Template directory not found at {template_dir}")
    
    # Create a README file in the .codesight directory
    readme_content = f"""# CodeSight Project Configuration

This directory contains configuration and templates for your CodeSight project.
Created on: {import_time_module().strftime('%Y-%m-%d %H:%M:%S')}

## Files

- codesight.config.json: Main configuration file
- Additional template files for analysis and visualization

For more information, see the CodeSight documentation.
"""
    
    with open(os.path.join(codesight_dir, 'README.md'), 'w') as f:
        f.write(readme_content)
        click.echo(f"Created README in {codesight_dir}")
    
    click.echo(f"\nCodeSight successfully initialized in {cwd}")
    click.echo(f"The .codesight directory has been created with configuration and template files.")
    click.echo(f"Run 'codesight analyze' to analyze your codebase.")

@main.command()
def info():
    """Show information about CodeSight installation."""
    click.echo("CodeSight Installation Information")
    click.echo("=" * 40)
    
    # Package information
    click.echo(f"Version: {__version__}")
    
    # Installation location
    module_path = os.path.dirname(os.path.abspath(__file__))
    click.echo(f"Installed at: {module_path}")
    
    # Template information
    template_dir = Path(module_path) / 'templates'
    if template_dir.exists():
        templates = list(template_dir.glob('*'))
        click.echo(f"Template directory: {template_dir}")
        click.echo(f"Available templates: {len(templates)}")
        for template in templates:
            click.echo(f"  - {template.name}")
    else:
        click.echo(f"Template directory not found: {template_dir}")
    
    # Current project information
    cwd = os.getcwd()
    codesight_dir = os.path.join(cwd, '.codesight')
    if os.path.exists(codesight_dir):
        click.echo(f"\nProject .codesight directory found at: {codesight_dir}")
        files = list(Path(codesight_dir).glob('*'))
        click.echo(f"Files in project .codesight directory: {len(files)}")
        for file in files:
            click.echo(f"  - {file.name}")
    else:
        click.echo(f"\nNo .codesight directory found in current directory.")
        click.echo(f"Run 'codesight init' to initialize a new project.")

@main.command()
@click.argument('directory', required=False)
@click.option('--extensions', '-e', multiple=True, help='File extensions to include (e.g. .py .js .ts)')
@click.option('--output', '-o', help='Output file path (defaults to .codesight/codebase_overview.txt)')
@click.option('--max-lines', type=int, default=config.TOKEN_OPTIMIZATION["MAX_LINES_PER_FILE"], 
              help='Maximum lines per file before truncation')
@click.option('--max-files', type=int, default=config.TOKEN_OPTIMIZATION["MAX_FILES"],
              help='Maximum files to include in the overview')
@click.option('--max-file-size', type=int, default=config.TOKEN_OPTIMIZATION["MAX_FILE_SIZE"],
              help='Skip files larger than this size in bytes')
def analyze(directory, extensions, output, max_lines, max_files, max_file_size):
    """Analyze the current codebase."""
    if not os.path.exists('.codesight'):
        click.echo("CodeSight not initialized in this directory. Run 'codesight init' first.")
        return
    
    # Set the root directory
    root_dir = os.path.abspath(directory) if directory else os.getcwd()
    
    # Set the output file path
    if not output:
        output = os.path.join(root_dir, '.codesight', 'codebase_overview.txt')
    
    # Convert extensions to proper format if provided
    if extensions:
        file_extensions = [ext if ext.startswith(".") else f".{ext}" for ext in extensions]
    else:
        file_extensions = config.FILE_EXTENSIONS
    
    # Update configuration with command-line arguments
    config.TOKEN_OPTIMIZATION["MAX_LINES_PER_FILE"] = max_lines
    config.TOKEN_OPTIMIZATION["MAX_FILES"] = max_files
    config.TOKEN_OPTIMIZATION["MAX_FILE_SIZE"] = max_file_size
    
    click.echo(f"Analyzing codebase in {root_dir}...")
    
    # Process the codebase
    analysis = core.analyze_codebase(
        root_dir=root_dir,
        file_extensions=file_extensions
    )
    
    # Format the overview
    from . import terminal
    overview_text = terminal.format_overview(analysis)
    
    # Write the overview to the output file
    os.makedirs(os.path.dirname(output), exist_ok=True)
    with open(output, "w", encoding="utf-8") as f:
        f.write(overview_text)
    
    click.echo(f"Analysis complete! Overview saved to {output}")
    click.echo(f"Found {analysis['file_count']} files with approximately {analysis['token_count']} tokens.")

@main.command()
def visualize():
    """Visualize the current codebase."""
    if not os.path.exists('.codesight'):
        click.echo("CodeSight not initialized in this directory. Run 'codesight init' first.")
        return
    
    click.echo("Generating visualization...")
    # Placeholder for actual visualization code
    click.echo("Visualization complete!")

def import_time_module():
    """Import datetime module dynamically to avoid import overhead."""
    from datetime import datetime
    return datetime.now()

if __name__ == '__main__':
    main() 