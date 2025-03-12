#!/bin/bash

# Install UV if not already installed
if ! command -v uv &> /dev/null; then
    echo "Installing UV..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Create a virtual environment using UV
echo "Creating virtual environment with UV..."
uv venv

# If a poetry.lock exists, convert it to UV format
if [ -f "poetry.lock" ]; then
    echo "Converting Poetry dependencies to UV..."
    # Create a new pyproject.toml for UV
    if [ -f "pyproject.toml" ]; then
        # Backup existing file
        cp pyproject.toml pyproject.toml.bak
        
        # Update build system section for UV
        sed -i '' 's/\[build-system\].*$/\[build-system\]\nrequires = ["hatchling"]\nbuild-backend = "hatchling.build"/g' pyproject.toml
        
        # Remove Poetry-specific sections
        sed -i '' '/\[tool\.poetry\]/,/^\[/d' pyproject.toml
    fi
    
    # Create a fresh lock file with UV
    uv lock
fi

# Generate requirements.txt
echo "Generating requirements.txt..."
uv run pip freeze > requirements.txt

# Install pre-commit if needed
echo "Setting up pre-commit..."
uv pip install pre-commit

# Update pre-commit configuration if it exists
if [ -f ".pre-commit-config.yaml" ]; then
    echo "Updating pre-commit configuration for UV..."
    # Backup existing config
    cp .pre-commit-config.yaml .pre-commit-config.yaml.bak
    
    # Replace Poetry hooks with UV hooks
    sed -i '' '/repo: https:\/\/github.com\/python-poetry\/poetry/,/^-/d' .pre-commit-config.yaml
    
    # Add UV pre-commit hooks
    cat >> .pre-commit-config.yaml << EOF
-   repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.5.4
    hooks:
    -   id: ruff
    -   id: ruff-format
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
    -   id: trailing-whitespace
    -   id: end-of-file-fixer
    -   id: check-yaml
    -   id: check-added-large-files
EOF
fi

# Install dependencies
echo "Installing dependencies with UV..."
uv pip install -e .

echo "UV setup complete!"
echo "Use 'uv pip install PACKAGE_NAME' to install packages"
echo "Use 'uv run COMMAND' to run commands in the virtual environment" 