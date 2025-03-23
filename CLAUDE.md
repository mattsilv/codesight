# CodeSight - Developer Guide

## Version
Current version: 0.1.11

## Claude API Usage
- When available, use MCP (Machine Code Processor) APIs instead of classic Claude tools
- For filesystem operations:
  - Use `mcp__filesystem__read_file` instead of `View`
  - Use `mcp__filesystem__write_file` instead of `Replace`
  - Use `mcp__filesystem__edit_file` instead of `Edit`
  - Use `mcp__filesystem__list_directory` instead of `LS`
  - Use `mcp__filesystem__search_files` instead of `GlobTool`
- For testing file existence, use `mcp__filesystem__get_file_info`
- For GitHub operations, use the `mcp__github__*` tools when available

## Commands
- `./codesight.sh` - Analyze codebase in current directory (shortcut for analyze)
- `./codesight.sh init` - Initialize in current directory
- `./codesight.sh analyze [directory]` - Analyze codebase (default: current dir)
- `./codesight.sh visualize [type]` - Visualize codebase statistics
- `./codesight.sh info` - Display configuration information
- `./codesight.sh update` - Check for newer versions of CodeSight
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
- Use ShellCheck to validate all scripts:
  - Prefer printf over echo for escape sequences
  - Add error handling for cd commands: `cd dir || exit 1`
  - Check command exit status directly: `if command;` instead of `$?`
  - Use shellcheck directives for specific exceptions: `# shellcheck disable=CODE`

## CLI User Experience Guidelines
- All error messages should be actionable and user-friendly
- Before executing commands, validate that required files/directories exist
- Provide clear error messages with suggested solutions
- Use color coding consistently: red for errors, green for success, yellow for warnings
- Include verbose mode for debugging issues
- Validate paths before sourcing files and provide helpful error messages
- Check for common environment issues and provide solutions
- Test commands with various environments and user scenarios
- For file/path errors, show the actual error and check if the directory structure is correct

## Release Process
1. Update version number in codesight.sh and CLAUDE.md
2. Run the pre-release validation script: `./pre_release.sh`
3. Fix any issues identified by the validation script
4. Run all dogfooding tests to ensure CLI experience is optimal
5. Create a git tag for the new version
6. Push changes and tags to GitHub
7. Create a new release on GitHub with release notes

## Quality Assurance
- Every release MUST pass the pre-release validation script
- All tests must pass, including the dogfooding tests that verify real CLI usage
- The script must be tested by direct execution in its own directory
- Error messages must be clear and actionable
- Directory structure must follow the standard layout
- Old/deprecated files and directories must be removed before release
- All shell scripts must pass ShellCheck validation with no warnings
- Implement shellcheck directives (# shellcheck disable=CODE) only when necessary with explanatory comments

## Debug Commands
- Use `find . -type f -name "*.sh" | xargs wc -l` to count lines in all shell scripts
- Use `find . -name "*.sh" -not -path "*/\.*" | sort` to list all shell scripts excluding hidden directories
- Use `find . -name "*.sh" -not -path "*/\.*" -exec grep -l "pattern" {} \;` to find scripts containing a pattern
- For testing file collection: `find . -type f \( -name "*.sh" \) -not -path "*/\.*" | grep -v "node_modules\|dist\|build"`