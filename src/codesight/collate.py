"""Main module for code collation and token estimation."""

import logging
from pathlib import Path
from typing import Any, Optional, cast

import chardet
import pathspec
import tiktoken

from codesight.config import CodeSightConfig
from codesight.validate import validate_config

from .ignore import parse_gitignore, should_ignore
from .structure import generate_folder_structure, sort_files
from .transform import process_python_file

__all__ = [
    "gather_and_collate",
    "estimate_token_length",
]

logger = logging.getLogger(__name__)


def estimate_token_length(text: str, model: str = "gpt-4") -> Optional[int]:
    """Estimate the number of tokens in the text for a given model."""
    try:
        encoding = tiktoken.encoding_for_model(model)
        return len(encoding.encode(text))
    except Exception as err:
        logger.error("Failed to estimate token length: %s", err)
        return None


def _read_file_content(file_path: Path) -> tuple[str, int]:
    """Read file content and detect encoding."""
    raw_content = file_path.read_bytes()
    detected = chardet.detect(raw_content)
    encoding = detected["encoding"] or "utf-8"

    try:
        content = raw_content.decode(encoding)
        lines = len(content.splitlines())
        return content, lines
    except UnicodeDecodeError:
        logger.warning("Failed to decode %s with %s encoding", file_path, encoding)
        # Fallback to utf-8 with error handling
        content = raw_content.decode("utf-8", errors="replace")
        lines = len(content.splitlines())
        return content, lines


def _process_file(
    file_path: Path, root_folder: Path, config: CodeSightConfig
) -> Optional[tuple[str, int, bool]]:
    """Process a single file and return its content, line count and processing status."""
    try:
        content, lines = _read_file_content(file_path)
        was_processed = False

        if file_path.suffix == ".py":
            content, was_processed = process_python_file(
                content, config.get("truncate_py_literals", 5)
            )

        return content, lines, was_processed
    except Exception as err:
        logger.error("Failed to process file %s: %s", file_path.relative_to(root_folder), err)
        return None


def gather_and_collate(
    root_folder: Path,
    config: CodeSightConfig,
    gitignore_patterns: Optional[pathspec.PathSpec] = None,
) -> tuple[str, Optional[int], dict[str, dict[str, Any]]]:
    """Gather and collate code files from the root folder."""
    if not root_folder.exists() or not root_folder.is_dir():
        raise ValueError(f"Root folder {root_folder} does not exist or is not a directory")

    gitignore_patterns = gitignore_patterns or parse_gitignore(root_folder)

    # Generate structure first
    structure = generate_folder_structure(root_folder, gitignore_patterns, config)
    result = ["# Project Structure", structure]
    file_stats = {}

    # Get all valid files
    all_files = [
        f
        for f in root_folder.rglob("*")
        if f.is_file() and not should_ignore(f.relative_to(root_folder), config, gitignore_patterns)
    ]

    for file_path in sort_files(all_files, root_folder):
        relative_path = str(file_path.relative_to(root_folder))
        if processed := _process_file(file_path, root_folder, config):
            content, lines, was_processed = processed
            file_content = (
                f"\n### {relative_path}\n\n```{file_path.suffix[1:] or ''}\n{content}\n```"
            )
            result.append(file_content)

            file_stats[relative_path] = {
                "tokens": estimate_token_length(file_content) or 0,
                "lines": lines,
                "was_processed": was_processed,
            }

    collated = "\n".join(result)
    return collated, estimate_token_length(collated), file_stats
