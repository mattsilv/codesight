"""Command-line interface for CodeSight."""
import click
import pyperclip
import logging
from pathlib import Path
from rich.console import Console
from rich.table import Table
from rich.logging import RichHandler
from .config import load_config, auto_detect_project_type, validate_config
from .collate import gather_and_collate
from typing import Optional

console = Console()

def setup_logging(verbose: bool):
    """Configure logging with appropriate level and formatting."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(message)s",
        handlers=[RichHandler(rich_tracebacks=True)]
    )

def display_file_stats(file_stats: list[tuple[Path, int]], total_token_count: Optional[int]):
    """Display statistics about the files processed using Rich tables."""
    table = Table(title="File Statistics")
    table.add_column("File", style="cyan")
    table.add_column("Tokens", justify="right", style="green")
    
    # Sort files by token count in descending order
    sorted_stats = sorted(file_stats, key=lambda x: x[1], reverse=True)
    
    # Add summary row
    console.print(f"\nTotal files included: {len(file_stats)}")
    if total_token_count is not None:
        console.print(f"Total tokens: {total_token_count:,}")
    
    if sorted_stats:
        console.print("\nTop 5 files by token count:")
        for path, tokens in sorted_stats[:5]:
            table.add_row(str(path), f"{tokens:,}")
        
        console.print(table)

@click.command()
@click.option('--root', default='.', help='Root folder to scan.')
@click.option('--output', default='codesight_source.txt', help='Output file path.')
@click.option('--type', 'project_type', default=None, help='Force a project type (e.g. python, javascript).')
@click.option('--user-config', default=None, help='Path to user config file.')
@click.option('--copy-to-clipboard', is_flag=True, help='Copy the final result to the clipboard.')
@click.option('--model', default='gpt-3.5-turbo', help='Model name for token counting.')
@click.option('--verbose', is_flag=True, help='Enable verbose logging output.')
def codesight(root, output, project_type, user_config, copy_to_clipboard, model, verbose):
    """CodeSight: Simple LLM-friendly code collation with minimal config required."""
    try:
        # Set up logging
        setup_logging(verbose)
        logger = logging.getLogger(__name__)
        
        root_path = Path(root).resolve()
        if not root_path.exists():
            raise click.UsageError(f"Root directory does not exist: {root_path}")

        # Load and validate config
        try:
            config = load_config(user_config)
            validate_config(config)  # New function to validate config structure
        except Exception as e:
            raise click.UsageError(f"Configuration error: {str(e)}")

        # Auto-detect project type if not supplied by user
        if not project_type:
            project_type = auto_detect_project_type(root_path)
            logger.info("Detected project type: %s", project_type)

        # Merge template if project type is known
        if project_type in config["templates"]:
            config.update(config["templates"][project_type])

        # Collate
        try:
            final_text, token_count, file_stats = gather_and_collate(root_path, config)
        except Exception as e:
            raise click.UsageError(f"Error during file collation: {str(e)}")

        # Write output
        try:
            with open(output, 'w', encoding='utf-8') as f:
                f.write(final_text)
            logger.info("Output written to %s", output)
        except Exception as e:
            raise click.UsageError(f"Failed to write output file: {str(e)}")

        # Display file statistics
        display_file_stats(file_stats, token_count)

        # Show token count if available
        if token_count is not None:
            logger.info("Estimated token count (%s): %s", model, token_count)
        else:
            logger.info("Note: Install tiktoken to get token count estimation")

        # Optional copy to clipboard
        if copy_to_clipboard:
            try:
                pyperclip.copy(final_text)
                logger.info("Copied output to clipboard")
            except pyperclip.PyperclipException:
                logger.warning("Clipboard copy not supported on this system")
            except Exception as e:
                logger.error("Failed to copy to clipboard: %s", e)

    except click.UsageError as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        raise click.Abort()
    except Exception as e:
        console.print(f"[red]Unexpected error:[/red] {str(e)}")
        if verbose:
            logger.exception("Detailed error information:")
        raise click.Abort()

def main():
    """Entry point for the CLI."""
    codesight() 