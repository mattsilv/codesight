"""Command-line interface for CodeSight."""

import logging
from pathlib import Path
from typing import Any, Optional, cast

import click
import toml

from . import __version__
from .collate import gather_and_collate
from .config import auto_detect_project_type, load_config
from .reporting import copy_to_clipboard_if_requested, display_file_stats

logger = logging.getLogger(__name__)


def setup_logging(verbose: bool) -> None:
    """Configure logging based on verbosity level."""
    log_level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )


def validate_output_file(
    ctx: click.Context, param: click.Parameter, value: Optional[str]
) -> Optional[str]:
    """Validate output file path."""
    if not value:
        return None

    try:
        path = Path(value)
        if path.exists() and not path.is_file():
            raise click.BadParameter(f"Output path exists but is not a file: {value}")
        return value
    except Exception as err:
        raise click.BadParameter(f"Invalid output file path: {value}") from err


def validate_user_config(
    ctx: click.Context, param: click.Parameter, value: Optional[str]
) -> Optional[dict[str, Any]]:
    """Load and validate user configuration file."""
    if not value:
        return None

    try:
        path = Path(value)
        if not path.exists():
            raise click.BadParameter(f"Configuration file not found: {value}")
        if not path.is_file():
            raise click.BadParameter(f"Configuration path is not a file: {value}")

        with open(path) as f:
            return toml.load(f)
    except toml.TomlDecodeError as err:
        raise click.BadParameter(f"Invalid TOML in configuration file: {value}") from err
    except Exception as err:
        raise click.BadParameter(f"Failed to read configuration file: {value}") from err


@click.command()
@click.version_option(__version__)
@click.option(
    "-o",
    "--output",
    type=str,
    callback=validate_output_file,
    help="Output file path (default: print to console)",
)
@click.option(
    "-c",
    "--copy",
    is_flag=True,
    help="Copy output to clipboard",
)
@click.option(
    "-t",
    "--type",
    type=click.Choice(["python", "javascript"], case_sensitive=False),
    help="Force project type (default: auto-detect)",
)
@click.option(
    "-u",
    "--user-config",
    type=str,
    callback=validate_user_config,
    help="Path to user configuration file",
)
@click.option("-v", "--verbose", is_flag=True, help="Enable verbose logging")
def main(
    output: Optional[str],
    copy: bool,
    type: Optional[str],
    user_config: Optional[dict[str, Any]],
    verbose: bool,
) -> None:
    """Gather and format code for LLM context."""
    setup_logging(verbose)
    logger.debug("Starting CodeSight %s", __version__)

    try:
        root_folder = Path.cwd()
        project_type = type or auto_detect_project_type(root_folder)
        config = load_config(project_type, user_config)

        logger.info("Processing %s project at %s", project_type, root_folder)
        collated, token_count, file_stats = gather_and_collate(
            root_folder, cast(dict[str, Any], config)
        )

        if output:
            try:
                with open(output, "w") as f:
                    f.write(collated)
                logger.info("Output written to %s", output)
            except Exception as err:
                raise click.ClickException(f"Failed to write output file: {output}") from err

        was_copied = copy_to_clipboard_if_requested(collated, copy)
        display_file_stats(file_stats, token_count, output, was_copied, project_type)

    except Exception as err:
        logger.debug("Error details:", exc_info=True)
        raise click.ClickException(str(err)) from err
