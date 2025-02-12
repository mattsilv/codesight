"""Command-line interface for CodeSight."""

import logging
import sys
from pathlib import Path
from typing import Optional

import click

from codesight.auto_detect import auto_detect_project_type
from codesight.collate import gather_and_collate
from codesight.config import DEFAULT_CONFIG, load_config
from codesight.ignore import parse_gitignore
from codesight.reporting import copy_to_clipboard_if_requested, display_file_stats
from codesight.validate import validate_config

logger = logging.getLogger(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)


def analyze_command(
    path: Path,
    config: Optional[Path] = None,
    output: Optional[Path] = None,
    clipboard: bool = False,
) -> None:
    """Generate a report analyzing the codebase.

    Args:
        path: Path to analyze
        config: Optional path to config file
        output: Optional path to output file
        clipboard: Whether to copy output to clipboard
    """
    try:
        config_dict = dict(DEFAULT_CONFIG.copy()) if config is None else load_config(config)
        validated_config = validate_config(config_dict)
        gitignore_spec = parse_gitignore(path)
        project_type = auto_detect_project_type(path)

        result = gather_and_collate(path, validated_config, gitignore_spec)
        if result is None:
            logger.error("Failed to gather files")
            sys.exit(1)

        content, token_count, file_stats = result

        if output:
            with open(output, "w", encoding="utf-8") as f:
                f.write(content)
        copied = copy_to_clipboard_if_requested(content, clipboard)

        display_file_stats(
            file_stats=file_stats,
            total_token_count=token_count,
            output_file=str(output) if output else None,
            copied_to_clipboard=copied,
            project_type=project_type,
        )

    except Exception as e:
        logger.error("Error during analysis: %s", e)
        sys.exit(1)


@click.command()
@click.argument(
    "path",
    type=click.Path(exists=True, path_type=Path),
    default=Path("."),
)
@click.option(
    "--config",
    "-c",
    type=click.Path(exists=True, path_type=Path),
    help="Path to configuration file",
)
@click.option(
    "--output",
    "-o",
    type=click.Path(path_type=Path),
    help="Path to output file",
)
@click.option(
    "--clipboard",
    is_flag=True,
    help="Copy output to clipboard",
)
def main(
    path: Path,
    config: Optional[Path] = None,
    output: Optional[Path] = None,
    clipboard: bool = False,
) -> None:
    """Analyze and understand your codebase with CodeSight."""
    analyze_command(path, config, output, clipboard)


if __name__ == "__main__":  # pragma: no cover
    main()
