# CodeSight

[![PyPI version](https://badge.fury.io/py/codesight.svg)](https://badge.fury.io/py/codesight)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python Version](https://img.shields.io/pypi/pyversions/codesight.svg)](https://pypi.org/project/codesight/)

**CodeSight** is a utility that helps you extract your entire codebase into a single text file. This makes it easy to share your code with Large Language Models (LLMs) like GPT-4 or Claude for comprehensive code reviews, analysis, and suggestions.

## Why CodeSight?

- **Complete Codebase Context**: Give LLMs the full picture of your code for more accurate assistance
- **Smart Token Optimization**: CodeSight intelligently truncates files to ensure you stay within token limits
- **Flexible Configuration**: Easily include or exclude specific files, directories, or file types
- **Works with Any Project**: Language-agnostic - works with Python, JavaScript, Go, or any text-based code

## Installation

```bash
pip install codesight
```

## Usage

### Quick Start

```bash
# Initialize CodeSight in your project 
cd your-project
codesight init

# Generate a codebase overview file
codesight analyze
```

This will create a `.codesight` directory in your project with configuration files and a `codebase_overview.txt` file containing your entire codebase.

### Command-line Options

```bash
# Analyze a specific directory
codesight analyze /path/to/project

# Only include specific file extensions
codesight analyze --extensions .py .js .ts

# Custom output file
codesight analyze --output my-overview.txt

# Customize token optimization settings
codesight analyze --max-lines 100 --max-files 200 --max-file-size 100000
```

## Configuration

After running `codesight init`, you'll have a `.codesight/codesight.config.json` file with settings like:

```json
{
  "ignore_patterns": ["*.pyc", "__pycache__", "venv", ".git"],
  "file_extensions": [".py", ".js", ".ts", ".jsx", ".tsx"],
  "token_optimization": {
    "max_lines_per_file": 500,
    "max_files": 1000,
    "max_file_size": 500000
  }
}
```

## Using with Language Models

1. Generate your codebase overview file:
   ```bash
   codesight analyze
   ```

2. Open the created file at `.codesight/codebase_overview.txt`

3. Copy the contents and paste into an LLM conversation

4. Ask for code review, architecture suggestions, improvements, etc.

## Requirements

- Python 3.8+

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.