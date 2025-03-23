# CodeSight

[![ShellCheck](https://img.shields.io/badge/ShellCheck-Enabled-brightgreen.svg)](https://www.shellcheck.net)

CodeSight is a shell-based tool for analyzing code repositories to produce optimized context files for LLMs (Large Language Models). It helps extract the most relevant code for LLM prompts while managing token usage efficiently.

## Features

- Fast analysis of code repositories
- Intelligent gitignore-aware file traversal
- Customizable file extension filters
- Size and line count limits
- Pretty output formatting
- Visualization of code statistics

## Installation

```bash
# Clone the repository
git clone https://github.com/mattsilv/codesight.git
cd codesight

# Run the installer
./install.sh
```

Or quick installation:

```bash
curl -fsSL https://raw.githubusercontent.com/mattsilv/codesight/main/install.sh | bash
```

## Usage

```bash
# Analysis command (default)
codesight [directory]

# Initialize in current directory
codesight init

# Show help
codesight help

# Show configuration info
codesight info

# Visualize code statistics
codesight visualize
```

### Analysis options

```
--output FILE      Specify output file (default: codesight.txt)
--extensions "EXT" Space-separated list of file extensions
--max-lines N      Maximum lines per file before truncation
--max-files N      Maximum files to include
--max-size N       Maximum file size in bytes
```

## Development

```bash
# Run tests
./tests/run_tests.sh

# Run ShellCheck to validate scripts
shellcheck *.sh */*.sh

# Fix common ShellCheck issues
./fix_shellcheck.sh --auto-fix

# Run pre-release checks
./pre_release.sh
```

## Code Quality

CodeSight uses ShellCheck for code quality and linting. Common standards include:

- ShellCheck compliance for all shell scripts
- Proper exit code handling and error reporting
- Thorough testing with automated validation
- User-friendly error messages
- Comprehensive documentation

## License

MIT