# CodeSight

[![CI](https://github.com/mattsilv/codesight/actions/workflows/ci.yml/badge.svg)](https://github.com/mattsilv/codesight/actions/workflows/ci.yml)
[![PyPI version](https://badge.fury.io/py/codesight.svg)](https://badge.fury.io/py/codesight)
[![Python Version](https://img.shields.io/pypi/pyversions/codesight)](https://pypi.org/project/codesight/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A code collation tool for LLM context generation. It takes all of the code in your project and collates it into a single file so you can paste it into your favorite LLM for debugging, testing, or other purposes.

## Installation

```bash
pip install codesight
```

## Quick Start

Basic usage (auto-detects project type):

```bash
codesight
```

Force a specific project type:

```bash
codesight --type python
```

Use custom configuration:

```bash
codesight --user-config .codesight_config.toml
```

Copy output to clipboard:

```bash
codesight --copy-to-clipboard
```

Get detailed logging:

```bash
codesight --verbose
```

## Configuration

Create a `.codesight_config.toml` file to customize behavior. Here's a complete example with all available options:

```toml
# File extensions to include
include_extensions = [".py", ".md", ".rst", ".sql", ".toml"]

# Files to always exclude (supports glob patterns)
exclude_files = ["*.pyc", "*.pyo", "*.pyd", "*.so"]

# Files to always include, even if they match exclude patterns
include_files = ["README.md", "pyproject.toml"]

# Additional glob patterns to exclude
exclude_patterns = ["**/temp/*", "**/cache/*"]

# Maximum number of elements to keep in Python literals (lists/dicts)
truncate_py_literals = 5

# Key directories to focus on (empty means scan everything)
key_directories = ["src", "tests"]

# Documentation for specific files
file_docs = {
    "README.md" = "Project documentation and usage guide",
    "pyproject.toml" = "Project configuration and dependencies"
}

# Project type templates
[templates.python]
exclude_extensions = [".csv", ".pkl", ".db"]
key_directories = ["src", "tests"]
file_docs = {
    "pyproject.toml" = "Project configuration and dependencies",
    "README.md" = "Project documentation and usage guide"
}

[templates.javascript]
exclude_extensions = [".map", ".lock"]
key_directories = ["src", "test"]
file_docs = {
    "package.json" = "Project configuration and dependencies",
    "README.md" = "Project documentation and usage guide"
}
```

## Features

- Auto-detects project type (Python/JavaScript)
- Respects `.gitignore` patterns
- Truncates large Python data structures
- Markdown-formatted output
- Optional clipboard integration
- Customizable via TOML config
- Token counting for LLM context limits
- Rich console output with file statistics

## Advanced Usage

### Project Type Detection

CodeSight automatically detects your project type:

- Python: Detected by presence of `pyproject.toml`
- JavaScript: Detected by presence of `package.json`
- Unopinionated: Used when no specific markers are found

### Token Counting

Specify the LLM model for accurate token counting:

```bash
codesight --model gpt-4
```

### Custom Output Location

Save the collated output to a specific file:

```bash
codesight --output my_codebase.txt
```

### Combining Options

You can combine multiple options:

```bash
codesight --root ./myproject --type python --copy-to-clipboard --verbose
```

## Error Handling

CodeSight handles various error conditions gracefully:

- Files with non-UTF8 encodings are detected and processed
- Malformed configuration files produce clear error messages
- File access errors are logged with details
- Python parsing errors are handled with warnings

## License

MIT
