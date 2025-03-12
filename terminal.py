#!/usr/bin/env python3
"""
Terminal-related functionality for CodeSight.
Handles all console output and styling.
"""
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.style import Style
from rich.text import Text
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn
from rich.box import DOUBLE, ROUNDED
from rich.align import Align
from rich.console import Group
import config
import os
import subprocess
import platform
from typing import Dict, List, Any

# Rich console setup with width constraint for better terminal compatibility
console = Console(width=100)

def copy_to_clipboard(text):
    """
    Copy text to clipboard based on the operating system
    
    Args:
        text: Text to copy to clipboard
    """
    system = platform.system()
    try:
        if system == 'Darwin':  # macOS
            process = subprocess.Popen(['pbcopy'], stdin=subprocess.PIPE)
            process.communicate(text.encode('utf-8'))
        elif system == 'Windows':
            process = subprocess.Popen(['clip'], stdin=subprocess.PIPE)
            process.communicate(text.encode('utf-8'))
        elif system == 'Linux':
            process = subprocess.Popen(['xclip', '-selection', 'clipboard'], stdin=subprocess.PIPE)
            process.communicate(text.encode('utf-8'))
        return True
    except Exception as e:
        console.print(f"[red]Failed to copy to clipboard: {e}[/red]")
        return False

def print_title():
    """Display retro-style title banner"""
    # Create a table for the logo with consistent borders
    logo_table = Table(
        show_header=False,
        box=ROUNDED,
        border_style="bright_cyan",
        width=85,
        padding=(1, 2)
    )
    
    # Add a single column for the logo text
    logo_table.add_column("logo", justify="center")
    
    # Add the logo text as a row
    logo_text = Text()
    logo_text.append("C O D E S I G H T", style="bold bright_yellow")
    logo_text.append(f" v{config.VERSION}", style="dim cyan")
    
    logo_table.add_row(logo_text)
    
    # Center the table and print it
    console.print(Align.center(logo_table))

def print_start_message():
    """Display mission start message"""
    panel = Panel(
        "[bold]Analyzing codebase...[/bold]", 
        border_style="green", 
        title="[bright_yellow]MISSION START[/bright_yellow]", 
        subtitle="[bright_blue]LOADING...[/bright_blue]",
        width=85  # Match the width of the MISSION COMPLETE panel
    )
    
    # Center the panel and print it
    console.print(Align.center(panel))

def create_progress():
    """Create and return a progress bar object"""
    return Progress(
        SpinnerColumn(),
        TextColumn("[bold green]Processing...[/bold green]"),
        BarColumn(bar_width=40),
        TextColumn("[bold]{task.percentage:.0f}%[/bold]"),
        TimeElapsedColumn(),
        console=console,
        expand=False
    )

def format_overview(analysis: dict) -> str:
    """
    Format analysis results into a text overview
    
    Args:
        analysis: Dictionary with analysis results
        
    Returns:
        Formatted overview text
    """
    # Extract data from analysis
    file_count = analysis['file_count']
    file_extensions = analysis['file_extensions']
    file_types = analysis['file_types']
    char_count = analysis['char_count']
    line_count = analysis['line_count']
    token_count = analysis['token_count']
    original_chars = analysis['original_chars']
    original_lines = analysis['original_lines']
    original_tokens = analysis['original_tokens']
    files_info = analysis['files_info']
    
    # Calculate savings
    char_savings = (1 - char_count / original_chars) * 100 if original_chars > 0 else 0
    line_savings = (1 - line_count / original_lines) * 100 if original_lines > 0 else 0
    token_savings = (1 - token_count / original_tokens) * 100 if original_tokens > 0 else 0
    
    # Format overview sections
    sections = []
    
    # Project overview section
    overview = [
        "# PROJECT OVERVIEW",
        f"Files included: {file_count}",
        f"Extensions: {', '.join(file_extensions)}",
        f"Characters: {char_count:,} ({char_savings:.1f}% savings)",
        f"Lines: {line_count:,} ({line_savings:.1f}% savings)",
        f"Tokens: {token_count:,} ({token_savings:.1f}% savings)",
        ""
    ]
    sections.append("\n".join(overview))
    
    # File types section
    file_types_section = ["# FILE TYPES"]
    for ext, count in file_types.items():
        file_types_section.append(f"{ext}: {count} files")
    file_types_section.append("")
    sections.append("\n".join(file_types_section))
    
    # File contents section
    file_contents_section = ["# FILE CONTENTS"]
    
    for file_info in files_info:
        path = file_info['path']
        tokens = file_info['token_count']
        time_ago = file_info.get('time_ago', '')
        truncated = " (truncated)" if file_info.get('truncated', False) else ""
        
        file_contents_section.append(f"\n## {path}")
        file_contents_section.append(f"Tokens: {tokens:,}, Last modified: {time_ago}{truncated}")
        file_contents_section.append("```")
        file_contents_section.append(file_info['content'])
        file_contents_section.append("```")
    
    sections.append("\n".join(file_contents_section))
    
    # Join all sections
    return "\n".join(sections)

def print_results(output_file, char_count, line_count, token_count, model, 
                  original_chars=0, original_lines=0, original_tokens=0, 
                  file_count=0, file_extensions=None, files_info=None):
    """
    Display results in a retro-style table
    
    Args:
        output_file: Path to the output file
        char_count: Character count in the output
        line_count: Line count in the output
        token_count: Token count in the output
        model: Model used for token counting
        original_chars: Original character count before optimization
        original_lines: Original line count before optimization
        original_tokens: Original token count before optimization
        file_count: Number of files included
        file_extensions: List of file extensions included
        files_info: List of dictionaries with file information
    """
    # Convert to relative path if possible
    try:
        rel_output_file = os.path.relpath(output_file)
    except ValueError:
        rel_output_file = output_file
    
    # Calculate savings if original values are provided
    char_savings = (1 - (char_count / original_chars)) * 100 if original_chars > 0 else 0
    line_savings = (1 - (line_count / original_lines)) * 100 if original_lines > 0 else 0
    token_savings = (1 - (token_count / original_tokens)) * 100 if original_tokens > 0 else 0
    
    # Format extension list
    extensions_str = ", ".join(file_extensions) if file_extensions else "None"
    
    # Create summary table
    summary_table = Table(show_header=False, border_style="bright_cyan", box=ROUNDED, width=75)
    summary_table.add_column("Property", style="bright_yellow", width=20)
    summary_table.add_column("Value", style="bright_white", width=55)
    
    # Output file and formats
    summary_table.add_row("Output File", rel_output_file)
    summary_table.add_row("File Extensions", extensions_str)
    summary_table.add_row("Files Included", f"{file_count:,}")
    
    # Add a separator
    summary_table.add_row("", "")
    
    # Add metrics showing savings
    if original_chars > 0:
        summary_table.add_row(
            "Characters", 
            f"{char_count:,} (Original: {original_chars:,}, Saved: {char_savings:.1f}%)"
        )
    else:
        summary_table.add_row("Characters", f"{char_count:,}")
        
    if original_lines > 0:
        summary_table.add_row(
            "Lines", 
            f"{line_count:,} (Original: {original_lines:,}, Saved: {line_savings:.1f}%)"
        )
    else:
        summary_table.add_row("Lines", f"{line_count:,}")
        
    if original_tokens > 0:
        summary_table.add_row(
            "Tokens", 
            f"{token_count:,} ({model}) (Original: {original_tokens:,}, Saved: {token_savings:.1f}%)"
        )
    else:
        summary_table.add_row("Tokens", f"{token_count:,} ({model})")
    
    # Create top files table if files_info is provided
    top_files_table = None
    if files_info:
        # Sort files by token count and get top 5
        sorted_files = sorted(files_info, key=lambda x: x.get('token_count', 0), reverse=True)[:5]
        
        if sorted_files:
            top_files_table = Table(
                title="Top 5 Files by Token Count",
                box=ROUNDED,
                border_style="bright_magenta",
                width=75
            )
            
            top_files_table.add_column("File", style="bright_white")
            top_files_table.add_column("Tokens", style="bright_yellow", justify="right")
            top_files_table.add_column("Last Modified", style="bright_cyan")
            
            for file_info in sorted_files:
                path = file_info.get('path', 'Unknown')
                tokens = file_info.get('token_count', 0)
                time_ago = file_info.get('time_ago', 'Unknown')
                
                # Try to get relative path
                try:
                    rel_path = os.path.relpath(path)
                except ValueError:
                    rel_path = path
                    
                top_files_table.add_row(
                    rel_path,
                    f"{tokens:,}",
                    time_ago
                )
    
    # Copy to clipboard if token count is under 50k
    clipboard_message = ""
    if token_count < 50000:
        try:
            with open(output_file, 'r', encoding='utf-8') as f:
                overview_content = f.read()
            
            if copy_to_clipboard(overview_content):
                clipboard_message = "\n[green]✓ Codebase overview copied to clipboard![/green]"
        except Exception as e:
            clipboard_message = f"\n[red]Failed to copy overview to clipboard: {e}[/red]"
    
    # Group components for final panel
    components = [summary_table]
    
    # Add top files table if available
    if top_files_table:
        components.append(top_files_table)
    
    # Add clipboard message if available
    if clipboard_message:
        components.append(Text(clipboard_message))
    
    # Final output with game-style success message
    results_panel = Panel(
        Group(*components),
        border_style="green", 
        title="[bright_yellow]MISSION COMPLETE![/bright_yellow]", 
        subtitle="[bright_magenta]SUMMARY[/bright_magenta]",
        width=85
    )
    
    # Center the panel
    console.print(Align.center(results_panel)) 