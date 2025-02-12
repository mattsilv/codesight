# Contributing to CodeSight

## Development Setup

1. Fork and clone the repository
2. Install dependencies:

```bash
poetry install
```

3. Install pre-commit hooks:

```bash
poetry run pre-commit install
```

## Development Workflow

1. Create a branch for your changes
2. Make your changes
3. Ensure tests pass and linting is clean:

```bash
# Run tests with coverage
poetry run pytest --cov=src/codesight --cov-report=term-missing

# Run linting
poetry run ruff .
poetry run black .
poetry run mypy src tests
```

4. Commit your changes (pre-commit hooks will run automatically)
5. Push and create a pull request

## Code Style

- Code is formatted with Black (line length 100)
- Imports are sorted with isort
- Type hints are required
- Docstrings follow Google style
- String quotes: single quotes for code, double quotes for docstrings
- F-strings: use double quotes for outer strings when nesting

## Project Structure

The project follows a src-layout:

```
codesight/
├── src/
│   └── codesight/        # Main package code
├── tests/                # Test suite
├── docs/                 # Documentation
└── meta/                # Project meta information
```

## File Organization

Files are organized into priority groups:

1. Core project files (README, pyproject.toml, etc.)
2. Configuration and hidden files
3. Entry points (**init**.py, main.py)
4. Core source code (src/, lib/, core/)
5. Tests (test\_\*.py, tests/)
6. Documentation and examples
7. Build artifacts
8. Other files

## Testing

- Write tests for all new functionality
- Include edge cases and error conditions
- Test Unicode and special characters
- Test configuration validation thoroughly
- Aim for high test coverage

## Documentation

- Keep README.md up to date
- Document all public functions and classes
- Include examples in docstrings
- Update CHANGELOG.md for notable changes
- Use type hints consistently

## Release Process

1. Update version in pyproject.toml
2. Update CHANGELOG.md
3. Create and push a tag
4. CI will automatically publish to PyPI

## Questions?

Feel free to open an issue for any questions or concerns.
