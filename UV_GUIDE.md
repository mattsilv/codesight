# UV Guide - Python Package Manager

## Overview

UV is a modern, fast Python package installer and resolver designed as a replacement for pip, Poetry, and other package managers.

## Setup

1. Make the setup script executable:

   ```
   chmod +x setup_uv.sh
   ```

2. Run the setup script:
   ```
   ./setup_uv.sh
   ```

## Common UV Commands

### Installing Packages

```
uv pip install package_name
```

### Adding Development Dependencies

```
uv pip install -e ".[dev]"
```

### Creating/Updating a lockfile

```
uv lock
```

### Syncing Your Environment with Dependencies

```
uv pip sync
```

### Running Commands in Virtual Environment

```
uv run python script.py
```

### Exporting Requirements to requirements.txt

```
uv pip export --frozen > requirements.txt
```

## PyProject.toml Format

Your pyproject.toml should look something like this:

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "codesight"
version = "0.1.4"
description = "Your project description"
authors = [
    {name = "Your Name", email = "your.email@example.com"},
]
dependencies = [
    "requests>=2.28.0",
    # Add your dependencies here
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "black>=23.0.0",
    # Add your dev dependencies here
]
```

## Pre-commit Integration

UV works well with pre-commit. The setup script has already configured this for you.

## More Information

- [UV GitHub](https://github.com/astral-sh/uv)
- [UV Documentation](https://astral.sh/uv/docs)
