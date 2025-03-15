# CodeSight - Developer Guide

## Version
Current version: 0.1.6

## Commands
- `./codesight.sh` - Analyze codebase in current directory (shortcut for analyze)
- `./codesight.sh init` - Initialize in current directory
- `./codesight.sh analyze [directory]` - Analyze codebase (default: current dir)
- `./codesight.sh visualize [type]` - Visualize codebase statistics
- `./codesight.sh info` - Display configuration information
- `./codesight.sh help` - Show help message

## Options for analyze
- `--output FILE` - Specify output file (default: codesight.txt)
- `--extensions "EXT..."` - Space-separated list of file extensions
- `--max-lines N` - Maximum lines per file before truncation
- `--max-files N` - Maximum files to include
- `--max-size N` - Maximum file size in bytes

## Code Style Guidelines
- Shell scripts follow POSIX shell standards with Bash extensions
- Functions use the `function name() {}` format
- Variables use UPPER_CASE for constants, lower_case for locals
- Error handling uses echo with colored output (❌ prefix)
- Success messages use green output (✅ prefix)
- All scripts should include a comment header describing purpose
- Indent with 4 spaces for readability
- Quote all variable expansions for safety: "${var}"