#!/bin/bash
# CodeSight help command
# Displays usage information

function show_help() {
    cat << EOF
Usage: codesight [command] [options]

Commands:
  init                   Initialize CodeSight in the current directory
  analyze [directory]    Analyze codebase and generate overview (default: current dir)
  visualize [type]       Visualize codebase statistics (files, extensions, etc.)
  info                   Display information about the configuration
  update                 Check for newer versions of CodeSight
  help                   Show this help message

Note: Running 'codesight' with no command will default to 'analyze'

Options for analyze:
  --output FILE          Specify output file (default: .codesight/codebase_overview.txt)
  --extensions "EXT..."  Space-separated list of file extensions (e.g. ".py .js .md")
  --max-lines N          Maximum lines per file before truncation (default: 1000)
  --max-files N          Maximum files to include (default: 100)
  --max-size N           Maximum file size in bytes (default: 100000)
  --gitignore            Enable .gitignore pattern respect (override config)
  --no-gitignore         Disable .gitignore pattern respect (override config)
  -c, --clipboard        Copy output to clipboard

File selection options (set in .codesight/config):
  RESPECT_GITIGNORE           Honor .gitignore patterns (default: true)

Token optimization options (set in .codesight/config):
  ENABLE_ULTRA_COMPACT_FORMAT  Use ultra-compact output format (default: false)
  REMOVE_COMMENTS              Remove comments from code (default: true)
  REMOVE_EMPTY_LINES           Remove empty lines from code (default: true)
  REMOVE_IMPORTS               Remove import statements (default: false)
  ABBREVIATE_HEADERS           Use abbreviated headers (default: false)
  TRUNCATE_PATHS               Shorten file paths (default: false)
  MINIMIZE_METADATA            Reduce metadata in output (default: false)
  SHORT_DATE_FORMAT            Use compact date format (default: true)

Options for visualize:
  files                  Show largest files by line count (default)
  tokens                 Show files with highest token counts and optimization potential
  --limit, -n N          Limit results to N items (default: 10)
  --directory, -d DIR    Analyze files in DIR (default: current directory)

Examples:
  codesight init
  codesight analyze --extensions ".py .js .html"
  codesight analyze ~/myproject --output myproject_overview.txt
  codesight visualize files
  codesight visualize tokens --limit 5
  codesight visualize files --limit 15
EOF
}