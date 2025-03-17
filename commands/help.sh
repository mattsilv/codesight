#!/bin/bash
# Help command functionality

function show_help() {
    echo "Usage: ./codesight.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  init                   Initialize CodeSight in the current directory"
    echo "  analyze [directory]    Analyze codebase and generate overview (default: current dir)"
    echo "  visualize [type]       Visualize codebase statistics (files, extensions, etc.)"
    echo "  info                   Display information about the configuration"
    echo "  update                 Check for newer versions of CodeSight"
    echo "  help                   Show this help message"
    echo ""
    echo "Note: Running './codesight.sh' with no command will default to 'analyze'"
    echo ""
    echo "Options for analyze:"
    echo "  --output FILE          Specify output file (default: .codesight/codebase_overview.txt)"
    echo "  --extensions \"EXT...\"  Space-separated list of file extensions (e.g. \".py .js .md\")"
    echo "  --max-lines N          Maximum lines per file before truncation (default: $MAX_LINES_PER_FILE)"
    echo "  --max-files N          Maximum files to include (default: $MAX_FILES)"
    echo "  --max-size N           Maximum file size in bytes (default: $MAX_FILE_SIZE)"
    echo "  --gitignore            Enable .gitignore pattern respect (override config)"
    echo "  --no-gitignore         Disable .gitignore pattern respect (override config)"
    echo ""
    echo "File selection options (set in .codesight/config):"
    echo "  RESPECT_GITIGNORE           Honor .gitignore patterns (default: true)"
    echo ""
    echo "Token optimization options (set in .codesight/config):"
    echo "  ENABLE_ULTRA_COMPACT_FORMAT  Use ultra-compact output format (default: false)"
    echo "  REMOVE_COMMENTS              Remove comments from code (default: true)"
    echo "  REMOVE_EMPTY_LINES           Remove empty lines from code (default: true)"
    echo "  REMOVE_IMPORTS               Remove import statements (default: false)"
    echo "  ABBREVIATE_HEADERS           Use abbreviated headers (default: false)"
    echo "  TRUNCATE_PATHS               Shorten file paths (default: false)"
    echo "  MINIMIZE_METADATA            Reduce metadata in output (default: false)"
    echo "  SHORT_DATE_FORMAT            Use compact date format (default: true)"
    echo ""
    echo "Options for visualize:"
    echo "  files                  Show largest files by line count (default)"
    echo "  --limit, -n N          Limit results to N items (default: 10)"
    echo "  --directory, -d DIR    Analyze files in DIR (default: current directory)"
    echo ""
    echo "Examples:"
    echo "  ./codesight.sh init"
    echo "  ./codesight.sh analyze --extensions \".py .js .html\""
    echo "  ./codesight.sh analyze ~/myproject --output myproject_overview.txt"
    echo "  ./codesight.sh visualize files"
    echo "  ./codesight.sh visualize files --limit 15"
} 