"""Main module for code collation and token estimation."""

import logging
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import chardet
import tiktoken

from .ignore import parse_gitignore, should_ignore
from .transform import process_python_file

__all__ = [
    "gather_and_collate",
    "estimate_token_length",
    "validate_config",
    "parse_gitignore",
    "process_python_file",
    "should_ignore",
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


def validate_config(config: Dict[str, Any]) -> None:
    """Validate configuration structure and values."""
    required_keys = {"include_extensions", "exclude_files", "include_files", "truncate_py_literals"}
    missing_keys = required_keys - set(config.keys())
    if missing_keys:
        raise ValueError(f"Missing required configuration keys: {missing_keys}")


def gather_and_collate(
    root_folder: Path,
    config: Dict[str, Any],
    gitignore_patterns: Optional[List[str]] = None,
) -> Tuple[str, Optional[int], Dict[str, Dict[str, Any]]]:
    """Gather and collate code files from the root folder."""
    # Validate config first
    validate_config(config)

    if not root_folder.exists() or not root_folder.is_dir():
        raise ValueError(f"Root folder {root_folder} does not exist or is not a directory")

    if gitignore_patterns is None:
        gitignore_patterns = parse_gitignore(root_folder)

    result = []
    file_stats: Dict[str, Dict[str, Any]] = {}
    skipped_files = []

    for file_path in root_folder.rglob("*"):
        if not file_path.is_file():
            continue

        relative_path = file_path.relative_to(root_folder)
        if should_ignore(relative_path, config, gitignore_patterns):
            skipped_files.append(str(relative_path))
            continue

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
                lines = content.count("\n") + 1
        except UnicodeDecodeError:
            logger.warning(
                "Failed to read %s with UTF-8 encoding, attempting detection", relative_path
            )
            with open(file_path, "rb") as f:
                raw_content = f.read()
                encoding = chardet.detect(raw_content)["encoding"] or "utf-8"
            with open(file_path, "r", encoding=encoding) as f:
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
