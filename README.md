# CodeSight

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**CodeSight** extracts your codebase into a single text file for LLM analysis, code reviews, and suggestions.

## Why CodeSight?

- Complete codebase context for LLMs
- Smart token optimization with file truncation
- Flexible configuration for files and directories
- Works with any text-based code project

## Quick Start

**Mac/Linux Users:**

```bash
# Install CodeSight
./install.sh  # Type 'y' when prompted to set up alias

# Either restart your terminal or run
source ~/.zshrc  # or ~/.bashrc for Bash users

# Then use from anywhere
codesight
```

**Windows Users:**

```bash
# Install CodeSight
./install.sh

# Use full path or add to your PATH
/path/to/codesight.sh
# or if batch file was created
codesight.bat
```

Running `codesight` will:

1. Initialize if needed
2. Analyze your codebase
3. Generate a text file
4. Copy results to clipboard
5. Show confirmation

## Commands (Optional)

- `init` - Initialize CodeSight
- `analyze [directory]` - Analyze codebase
- `info` - Show configuration
- `help` - Show help message

## Configuration

After initialization, `.codesight/config` contains:

```bash
# File extensions
FILE_EXTENSIONS=".py .js .jsx .ts .tsx .html .css .md .json"

# Limits
MAX_LINES_PER_FILE=100
MAX_FILES=100
MAX_FILE_SIZE=100000

# Excluded patterns
EXCLUDED_FILES=("package-lock.json" "yarn.lock" ".DS_Store")
EXCLUDED_FOLDERS=("node_modules" "dist" ".git")
```

## Using with LLMs

1. Run `codesight` in your project
2. Paste the clipboard contents into an LLM
3. Ask for code review or suggestions

## Requirements

- Bash shell environment
- macOS, Windows (Git Bash), or Linux

## License

MIT License
