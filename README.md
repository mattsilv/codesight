# CodeSight

[![CI](https://github.com/mattsilv/codesight/actions/workflows/ci.yml/badge.svg)](https://github.com/mattsilv/codesight/actions/workflows/ci.yml)
[![Python Version](https://img.shields.io/pypi/pyversions/codesight)](https://pypi.org/project/codesight/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Apple-simple code collation tool for LLM context generation.

## Installation

```bash
pip install codesight
```

## Usage

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

## Configuration

Create a `.codesight_config.toml` file to customize behavior:

```toml
# Example configuration
exclude_files = ["secret_credentials.txt"]
exclude_extensions = [".db", ".sqlite"]
truncate_py_literals = 10  # Truncate Python literals to 10 elements
```

## Features

- Auto-detects project type (Python/JavaScript)
- Respects `.gitignore` patterns
- Truncates large Python data structures
- Markdown-formatted output
- Optional clipboard integration
- Customizable via TOML config

## License

MIT
