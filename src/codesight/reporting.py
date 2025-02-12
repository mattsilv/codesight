"""Output formatting and reporting for CodeSight."""

import logging
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import pyperclip  # type: ignore
from rich.console import Console  # type: ignore
from rich.panel import Panel  # type: ignore
from rich.table import Table  # type: ignore

logger = logging.getLogger(__name__)
console = Console()


def display_file_stats(
    file_stats: Dict[str, Dict[str, Any]],
    total_token_count: Optional[int],
    output_file: Optional[str] = None,
    copied_to_clipboard: bool = False,
    project_type: Optional[str] = None,
) -> None:
    """Display statistics about the files processed using Rich tables."""
    # Main stats table
    stats_table = Table(title="File Statistics")
    stats_table.add_column("Path", style="blue")
    stats_table.add_column("File", style="cyan")
    stats_table.add_column("Tokens", justify="right", style="green")
    stats_table.add_column("Lines", justify="right", style="yellow")

    # Filter and sort files
    included_files = {
        path: stats
        for path, stats in file_stats.items()
        if stats.get("was_processed", False) or not path.endswith(".py")
    }
    sorted_stats = sorted(included_files.items(), key=lambda x: x[1]["tokens"], reverse=True)

    # Display top 10 files
    for path, stats in sorted_stats[:10]:
        p = Path(path)
        dir_path = str(p.parent) if str(p.parent) != "." else "[dim i]root[/dim i]"
        stats_table.add_row(
            dir_path, p.name, f"{stats.get('tokens', 0):,}", f"{stats.get('lines', 0):,}"
        )

    # Add summary row for remaining files
    if len(sorted_stats) > 10:
        remaining = sorted_stats[10:]
        remaining_tokens = sum(stats["tokens"] for _, stats in remaining)
        remaining_lines = sum(stats["lines"] for _, stats in remaining)
        stats_table.add_row(
            "[dim]Other files[/dim]",
            f"[dim]{len(remaining)} files[/dim]",
            f"[dim]{remaining_tokens:,}[/dim]",
            f"[dim]{remaining_lines:,}[/dim]",
        )

    # Add separator before totals
    stats_table.add_section()

    # Add total row
    total_lines = sum(stats["lines"] for _, stats in included_files.items())
    stats_table.add_row(
        "[bold]Total[/bold]",
        f"[bold]+{len(included_files)} files[/bold]",
        f"[bold]{total_token_count:,}[/bold]" if total_token_count is not None else "",
        f"[bold]{total_lines:,}[/bold]",
    )

    # Create info table
    info_table = Table(box=None, show_header=False, show_edge=False, pad_edge=False)
    info_table.add_column("Key", style="bright_black")
    info_table.add_column("Value", style="bright_white")

    if project_type:
        info_table.add_row("Project", f"[blue]{project_type}[/blue]")
    if output_file:
        info_table.add_row("Output", Path(output_file).name)
    if copied_to_clipboard:
        info_table.add_row("Status", "[green]Copied to clipboard[/green]")

    # Print tables
    console.print(stats_table)
    if project_type or output_file or copied_to_clipboard:
        console.print()  # Add a blank line
        console.print(
            Panel(info_table, title="Info", title_align="left", border_style="bright_black")
        )


def display_error_summary(errors: List[Tuple[Path, str]]) -> None:
    """Display a summary of errors encountered during processing."""
    if not errors:
        return

    table = Table(title="Processing Errors")
    table.add_column("File", style="cyan")
    table.add_column("Error", style="red")

    for path, error in errors:
        table.add_row(str(path), error)

    console.print("\nErrors encountered:")
    console.print(table)


def copy_to_clipboard_if_requested(content: str, should_copy: bool) -> bool:
    """Copy content to clipboard if requested.

    Returns:
        bool: Whether the content was successfully copied
    """
    if should_copy:
        try:
            pyperclip.copy(content)
            logger.info("Copied output to clipboard")
            return True
        except ImportError:
            logger.warning("pyperclip package not installed, clipboard copy not available")
        except Exception as e:
            logger.error("Failed to copy to clipboard: %s", e)
    return False
