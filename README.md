# CodeSight

[![CI](https://github.com/mattsilv/codesight/actions/workflows/ci.yml/badge.svg)](https://github.com/mattsilv/codesight/actions/workflows/ci.yml)
[![PyPI version](https://badge.fury.io/py/codesight.svg)](https://badge.fury.io/py/codesight)
[![Python Version](https://img.shields.io/pypi/pyversions/codesight)](https://pypi.org/project/codesight/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![codecov](https://codecov.io/gh/mattsilv/codesight/branch/main/graph/badge.svg)](https://codecov.io/gh/mattsilv/codesight)

CodeSight is a developer tool designed to enhance your LLM-powered coding experience. When you're stuck in a complex debugging session or need help understanding a codebase, CodeSight makes it easy to get assistance from powerful LLMs like ChatGPT, Claude, or other AI models.

## What's New in 0.1.1

- **Improved File Organization**: Enhanced file grouping logic with 8 distinct categories for better code organization
- **Better Error Messages**: Configuration validation now provides clear, actionable error messages
- **Unicode Support**: Full support for Unicode paths and filenames
- **Enhanced Testing**: Comprehensive test suite with edge case coverage
- **Improved CI**: Clean environment builds with full linting and test coverage

See the [CHANGELOG](CHANGELOG.md) for full details.

## See it in Action

![Sample CodeSight Report](docs/assets/sample-report.png)
_A clean, organized summary of your codebase with file statistics and token counts_

![Sample Structure View](docs/assets/sample-structure.png)
_Automatically generated project structure for better context_

![Sample Code View](docs/assets/sample-code.png)
_Neatly formatted code snippets with syntax highlighting_

With a single command (`codesight`), it:

- Intelligently gathers all relevant code from your project
- Formats it for optimal LLM consumption
- Copies it to your clipboard, ready to paste into any AI assistant
- Provides a summary of files and token usage

This is particularly useful when:

- You're stuck in a complex debugging loop in Cursor or your IDE
- You need to escalate to a more powerful model like GPT-4 or Claude
- You want to get a second opinion on your code from a different LLM
- You need to share your codebase context with an AI assistant quickly

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
codesight -t python
```

Use custom configuration:

```bash
codesight -u .codesight_config.toml
```

Copy output to clipboard:

```bash
codesight -c
```

Get detailed logging:

```bash
codesight -v
```

## Configuration

Create a `.codesight_config.toml` file to customize behavior. Here's a complete example with all available options:

```toml
# File extensions to include (must start with '.')
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
- Full Unicode support for paths and filenames
- Comprehensive error messages

## File Organization

CodeSight organizes files into priority groups for better context:

1. Core project files (README, pyproject.toml, etc.)
2. Configuration and hidden files
3. Entry points (**init**.py, main.py)
4. Core source code (src/, lib/, core/)
5. Tests (test\_\*.py, tests/)
6. Documentation and examples
7. Build artifacts
8. Other files

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

MIT
