"""Command-line interface for CodeSight."""

import logging
from pathlib import Path
from typing import Any, Dict, cast

import click
from rich.console import Console
from rich.logging import RichHandler

from .collate import gather_and_collate
from .config import auto_detect_project_type, load_config
from .reporting import copy_to_clipboard_if_requested, display_file_stats

console = Console()
logger = logging.getLogger(__name__)


def setup_logging(verbose: bool) -> None:
    """Configure logging with appropriate level and formatting."""
    level = logging.DEBUG if verbose else logging.WARNING  # Only show warnings by default
    logging.basicConfig(
        level=level,
        format="%(message)s",
        handlers=[RichHandler(rich_tracebacks=True, show_time=False, show_path=False)],
    )


def write_output(output_path: str, content: str) -> None:
    """Write content to output file."""
    try:
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(content)
        logger.info("Output written to %s", output_path)
    except Exception as e:
        raise click.UsageError(f"Failed to write output file: {str(e)}")


@click.command()  # type: ignore
@click.option(
    "--root", default=".", help="Root folder to scan for code files. Defaults to current directory."
)
@click.option(
    "--output", default="codesight_source.txt", help="Output file path for the collated code."
)
@click.option(
    "--type",
    "project_type",
    default=None,
    help=(
        "Force a specific project type (python/javascript). "
        "By default, auto-detects based on project files."
    ),
)
@click.option(
    "--user-config", default=None, help="Path to TOML configuration file to override defaults."
)
@click.option(
    "--copy-to-clipboard", is_flag=True, help="Copy the collated output to system clipboard."
)
@click.option(
    "--model",
    default="gpt-4",
    help="OpenAI model name for token counting (e.g. gpt-4, gpt-3.5-turbo).",
)
@click.option("--verbose", is_flag=True, help="Enable detailed debug logging with rich tracebacks.")
def codesight(
    root: str,
    output: str,
    project_type: str | None,
    user_config: str | None,
    copy_to_clipboard: bool,
    model: str,
    verbose: bool,
) -> None:
    """CodeSight: Simple LLM-friendly code collation with minimal config required.

    Scans a directory for code files, collates them into a single document with proper
    formatting and documentation, and optionally estimates token usage for LLM context.

    Examples:
        codesight                     # Scan current directory
        codesight --root ./myproject  # Scan specific directory
        codesight --type python       # Force Python project type
        codesight --copy-to-clipboard # Copy output to clipboard
    """
    try:
        # Set up logging
        setup_logging(verbose)
        if verbose:
            logger.debug("Starting CodeSight with root directory: %s", root)

        root_path = Path(root).resolve()
        if not root_path.exists():
            raise click.UsageError(f"Root directory does not exist: {root_path}")

        # Load and validate config
        try:
            config = load_config(user_config)
            if user_config and verbose:
                logger.debug("Using custom configuration from %s", user_config)
        except Exception as e:
            raise click.UsageError(f"Configuration error: {str(e)}")

        # Auto-detect project type if not supplied by user
        if not project_type:
            project_type = auto_detect_project_type(root_path)
            if verbose:
                logger.debug("Detected project type: %s", project_type)

        # Merge template if project type is known
        if project_type in config["templates"]:
            config.update(config["templates"][project_type])

        # Process files
        try:
            final_text, token_count, file_stats = gather_and_collate(
                root_path, cast(Dict[str, Any], config)
            )
        except Exception as e:
            raise click.UsageError(f"Failed to process files: {str(e)}")

        # Write output
        try:
            write_output(output, final_text)
            if verbose:
                logger.debug("Successfully wrote output to %s", output)
        except Exception as e:
            raise click.UsageError(f"Failed to write output file: {str(e)}")

        # Display file statistics
        display_file_stats(
            file_stats,
            token_count,
            output_file=output,
            copied_to_clipboard=copy_to_clipboard_if_requested(final_text, copy_to_clipboard),
            project_type=project_type,
        )

        if verbose:
            logger.debug("CodeSight completed successfully")

    except click.UsageError as e:
        console.print(f"[red]Error:[/red] {str(e)}")
        if verbose:
            logger.exception("Detailed error information:")
        raise click.Abort()
    except Exception as e:
        console.print(f"[red]Unexpected error:[/red] {str(e)}")
        if verbose:
            logger.exception("Detailed error information:")
        raise click.Abort()


def main() -> None:
    """Entry point for the CLI."""
    codesight()
