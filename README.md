# CodeSight

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**CodeSight** extracts your codebase into a single text file for LLM analysis, code reviews, and architecture planning. With CodeSight, you can easily copy your entire codebase to the clipboard and share it with large language models (like ChatGPT, Claude, etc.) to get guidance on fixing complex problems or designing new solutions.

## Why CodeSight?

- Provides complete codebase context for LLMs with one command
- Smart token optimization with file truncation for LLM context limits
- Respects .gitignore files to exclude irrelevant code
- Flexible configuration for including specific files and directories
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
# Install CodeSight (using Git Bash or similar)
./install.sh

# Option 1: Use the batch file created during installation
codesight.bat

# Option 2: Add the script directory to your PATH environment variable
# Then you can use either:
codesight.bat
# or
codesight.sh
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
# File extensions to include
FILE_EXTENSIONS=".py .js .jsx .ts .tsx .html .css .md .json"

# Limits (for token optimization)
MAX_LINES_PER_FILE=100  # Truncate files longer than this
MAX_FILES=100           # Maximum number of files to process
MAX_FILE_SIZE=100000    # Skip files larger than this (bytes)

# Excluded patterns
EXCLUDED_FILES=("package-lock.json" "yarn.lock" ".DS_Store")
EXCLUDED_FOLDERS=("node_modules" "dist" ".git")

# Gitignore support
RESPECT_GITIGNORE=true  # Exclude folders listed in .gitignore
```

You can modify these settings to customize how CodeSight processes your codebase.

## Using with LLMs

1. Run `codesight` in your project root directory
2. CodeSight will generate a formatted summary and copy it to your clipboard
3. Paste the clipboard contents into your preferred LLM (ChatGPT, Claude, etc.)
4. Ask for assistance with your code, for example:
   - "Review this codebase and suggest improvements"
   - "Help me diagnose why this feature isn't working"
   - "How should I architect a new feature for this project?"
   - "Explain how this code works and what it does"

## Requirements

- Bash shell environment (built-in on Mac/Linux, Git Bash on Windows)
- macOS, Linux, or Windows with Git Bash installed
- Standard command line tools:
  - `find` - for locating files
  - `grep` - for searching file contents
  - `wc` - for counting lines and file sizes
  - Clipboard commands (`pbcopy`, `xclip`, or `clip.exe`) - optional, for automatic clipboard copy

## How It Works

CodeSight simplifies sharing your codebase with AI:

1. **Smart file selection** - Collects files based on extensions and respects .gitignore
2. **Token optimization** - Truncates files to fit within AI context limits
3. **Consistent formatting** - Presents code with file paths and appropriate separators
4. **One-command workflow** - Initializes, analyzes, and copies to clipboard automatically

This makes it easy to get assistance from AI tools without manually copying and pasting individual files.

## License

MIT License
