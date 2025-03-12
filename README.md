# CodeSight

A tool for generating token-efficient codebase overviews.

## Usage

From the `.codesight` directory, run:

```bash
./run_codesight.sh [options]
```

### Options

- `--dir PATH`: Root directory of the project (default: parent directory)
- `--extensions EXT [EXT ...]`: File extensions to include (default: .ts, .toml, .css, .js, .json, .md)
- `--output FILE`: Output file name (default: codebase_overview.txt)
- `--max-lines N`: Maximum lines per file before truncation (default: 500)
- `--model MODEL`: Model to use for token counting (default: gpt-4)

### Examples

Analyze Python files in the parent directory:

```bash
./run_codesight.sh --extensions .py
```

Analyze JavaScript and TypeScript files in a specific directory:

```bash
./run_codesight.sh --dir /path/to/project --extensions .js .ts
```

## Installation

1. Install uv: `curl -LsSf https://astral.sh/uv/install.sh | sh`
2. Run `./install.sh` in the `.codesight` directory
3. Or manually: `uv venv .venv && uv pip install -r requirements.txt`
