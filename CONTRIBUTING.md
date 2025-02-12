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
3. Ensure tests pass:

```bash
poetry run pytest
```

4. Commit your changes (pre-commit hooks will run automatically)
5. Push and create a pull request

## Code Style

- Code is formatted with Black (line length 100)
- Imports are sorted with isort
- Type hints are required
- Docstrings follow Google style
