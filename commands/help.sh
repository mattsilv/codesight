#!/bin/bash
# Help command functionality

function show_help() {
    echo "Usage: ./codesight.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  init                   Initialize CodeSight in the current directory"
    echo "  analyze [directory]    Analyze codebase and generate overview (default: current dir)"
    echo "  info                   Display information about the configuration"
    echo "  help                   Show this help message"
    echo ""
    echo "Options for analyze:"
    echo "  --output FILE          Specify output file (default: .codesight/codebase_overview.txt)"
    echo "  --extensions \"EXT...\"  Space-separated list of file extensions (e.g. \".py .js .md\")"
    echo "  --max-lines N          Maximum lines per file before truncation (default: $MAX_LINES_PER_FILE)"
    echo "  --max-files N          Maximum files to include (default: $MAX_FILES)"
    echo "  --max-size N           Maximum file size in bytes (default: $MAX_FILE_SIZE)"
    echo ""
    echo "Examples:"
    echo "  ./codesight.sh init"
    echo "  ./codesight.sh analyze --extensions \".py .js .html\""
    echo "  ./codesight.sh analyze ~/myproject --output myproject_overview.txt"
} 