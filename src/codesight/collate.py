"""Main module for code collation and token estimation."""

import logging
from pathlib import Path
from typing import Any, Optional

import chardet
import pathspec
import tiktoken

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
    except Exception as e:
        logger.error("Failed to estimate token length: %s", e)
        return None


def validate_config(config: dict[str, Any]) -> None:
    """Validate configuration dictionary."""
    required_keys = {"include_extensions", "exclude_files", "include_files"}
    if not all(key in config for key in required_keys):
        raise ValueError("Missing required configuration keys")

    # Type checks
    if not isinstance(config["include_extensions"], list):
        raise ValueError("include_extensions must be a list")
    if not isinstance(config["exclude_files"], list):
        raise ValueError("exclude_files must be a list")
    if not isinstance(config["include_files"], list):
        raise ValueError("include_files must be a list")
    if "truncate_py_literals" in config and not isinstance(config["truncate_py_literals"], int):
        raise ValueError("truncate_py_literals must be an integer")


def gather_and_collate(
    root_folder: Path,
    config: dict[str, Any],
    gitignore_patterns: Optional[pathspec.PathSpec] = None,
) -> tuple[str, Optional[int], dict[str, dict[str, Any]]]:
    """Gather and collate code files from the root folder."""
    # Validate config first
    validate_config(config)

    if not root_folder.exists() or not root_folder.is_dir():
        raise ValueError(f"Root folder {root_folder} does not exist or is not a directory")

    if gitignore_patterns is None:
        gitignore_patterns = parse_gitignore(root_folder)

    result = []
    file_stats: dict[str, dict[str, Any]] = {}
    skipped_files = []

    # Add folder structure at the beginning
    folder_structure = generate_folder_structure(root_folder, gitignore_patterns, config)
    result.append(folder_structure)

    # Gather all files first
    all_files = []
    for file_path in root_folder.rglob("*"):
        if not file_path.is_file():
            continue

        relative_path = file_path.relative_to(root_folder)
        if should_ignore(relative_path, config, gitignore_patterns):
            skipped_files.append(str(relative_path))
            continue

        all_files.append(file_path)

    # Sort files in logical order
    all_files = sort_files(all_files, root_folder)

    # Process files in order
    for file_path in all_files:
        relative_path = file_path.relative_to(root_folder)
        try:
            with open(file_path, encoding="utf-8") as f:
                content = f.read()
                lines = content.count("\n") + 1
        except UnicodeDecodeError:
            logger.warning(
                "Failed to read %s with UTF-8 encoding, attempting detection", relative_path
            )
            with open(file_path, "rb") as f:
                raw_content = f.read()
                encoding = chardet.detect(raw_content)["encoding"] or "utf-8"
            with open(file_path, encoding=encoding) as f:
                content = f.read()
                lines = content.count("\n") + 1

        was_processed = False
        if file_path.suffix == ".py":
            content, was_processed = process_python_file(
                content, config.get("truncate_py_literals", 5)
            )

        # Calculate tokens for this file
        file_content = f"```{file_path.suffix[1:] if file_path.suffix else ''}\n{content}\n```"
        file_tokens = estimate_token_length(file_content) or 0

        result.append(f"\n### {relative_path}\n\n{file_content}")
        file_stats[str(relative_path)] = {
            "tokens": file_tokens,
            "lines": lines,
            "was_processed": was_processed,
        }

    if skipped_files:
        logger.debug("Skipped files: %s", ", ".join(skipped_files))

    collated = "\n".join(result)
    token_count = estimate_token_length(collated)

    return collated, token_count, file_stats
