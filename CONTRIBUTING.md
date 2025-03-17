# Contributing to CodeSight

Thank you for your interest in contributing to CodeSight! This document provides guidelines and instructions for contributing to the project.

## Project Structure

CodeSight follows a modular structure for better maintainability:

```
codesight/
├── bin/           # Main executable
├── src/           # Source code
│   ├── commands/  # Command implementations
│   │   ├── analyze/    # Analyze command modules
│   │   └── visualize/  # Visualization modules
│   ├── core/      # Core functionality
│   └── utils/     # Utility functions
├── docs/          # Documentation
└── tests/         # Test scripts
```

## Development Guidelines

1. **Bash Practices**
   - Use POSIX shell features with Bash extensions when needed
   - Follow the `function name() {}` format for function declarations
   - Use UPPER_CASE for constants, lower_case for local variables
   - Quote all variable expansions: `"${var}"`
   - Include a comment header in all scripts explaining their purpose

2. **Code Style**
   - Use 4 spaces for indentation
   - Use color codes for terminal output (green for success, red for errors)
   - Prefix success messages with ✅ and errors with ❌
   - Keep functions modular with a single responsibility
   - Add error handling for edge cases

3. **Adding Features**
   - Create new commands in `src/commands/`
   - Update `bin/codesight` to include your command in the router
   - Add help information for your command
   - Write tests in the `tests/` directory

## Testing

Run all tests with:

```bash
./tests/run_tests.sh
```

## Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests to ensure functionality
5. Submit a pull request with a clear description of changes

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Respect intellectual property

## License

By contributing to CodeSight, you agree that your contributions will be licensed under the MIT License.