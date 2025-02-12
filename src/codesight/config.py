"""Configuration management for CodeSight."""
from pathlib import Path
import toml
from typing import Dict, Any, List
import logging

logger = logging.getLogger(__name__)

DEFAULT_CONFIG = {
    "include_extensions": [".py", ".md", ".rst", ".sql", ".toml"],
    "exclude_files": [".gitignore"],  # Always exclude .gitignore from final output
    "include_files": ["pyproject.toml", "README.md", ".github"],  # Include .github by default
    "exclude_patterns": [],
    "truncate_py_literals": 5,
    "key_directories": [],  # Directories to focus on, empty means scan everything
    "file_docs": {},  # Documentation for specific files, format: {"path": "doc"}
    "templates": {
        "python": {
            "exclude_extensions": [".csv", ".pkl", ".db"],
            "key_directories": ["src", "tests"],
            "file_docs": {
                "pyproject.toml": "Project configuration and dependencies",
                "README.md": "Project documentation and usage guide"
            }
        },
        "javascript": {
            "exclude_extensions": [".map", ".lock"],
            "key_directories": ["src", "test"],
            "file_docs": {
                "package.json": "Project configuration and dependencies",
                "README.md": "Project documentation and usage guide"
            }
        }
    }
}

REQUIRED_CONFIG_KEYS = {
    'include_extensions',
    'exclude_files',
    'include_files',
    'truncate_py_literals'
}

def validate_config(config: Dict[str, Any]) -> None:
    """Validate configuration structure and values."""
    # Check required keys
    missing_keys = REQUIRED_CONFIG_KEYS - set(config.keys())
    if missing_keys:
        raise ValueError(f"Missing required configuration keys: {missing_keys}")
    
    # Validate types
    if not isinstance(config['include_extensions'], list):
        raise ValueError("'include_extensions' must be a list")
    if not isinstance(config['exclude_files'], list):
        raise ValueError("'exclude_files' must be a list")
    if not isinstance(config['include_files'], list):
        raise ValueError("'include_files' must be a list")
    if not isinstance(config['truncate_py_literals'], int):
        raise ValueError("'truncate_py_literals' must be an integer")
    
    # Validate extension format
    for ext in config['include_extensions']:
        if not isinstance(ext, str) or not ext.startswith('.'):
            raise ValueError(f"Invalid extension format: {ext}. Extensions must be strings starting with '.'")
    
    # Validate templates if present
    if 'templates' in config:
        if not isinstance(config['templates'], dict):
            raise ValueError("'templates' must be a dictionary")
        for template_name, template_config in config['templates'].items():
            logger.debug("Validating template: %s", template_name)
            validate_template(template_name, template_config)

def validate_template(name: str, template: Dict[str, Any]) -> None:
    """Validate a template configuration."""
    # Check for valid keys in template
    valid_keys = {'exclude_extensions', 'key_directories', 'file_docs'}
    invalid_keys = set(template.keys()) - valid_keys
    if invalid_keys:
        raise ValueError(f"Invalid keys in template '{name}': {invalid_keys}")
    
    # Validate types
    if 'exclude_extensions' in template:
        if not isinstance(template['exclude_extensions'], list):
            raise ValueError(f"Template '{name}': exclude_extensions must be a list")
        for ext in template['exclude_extensions']:
            if not isinstance(ext, str) or not ext.startswith('.'):
                raise ValueError(f"Template '{name}': Invalid extension format: {ext}")
    
    if 'key_directories' in template:
        if not isinstance(template['key_directories'], list):
            raise ValueError(f"Template '{name}': key_directories must be a list")
        for dir_name in template['key_directories']:
            if not isinstance(dir_name, str):
                raise ValueError(f"Template '{name}': Invalid directory name: {dir_name}")
    
    if 'file_docs' in template:
        if not isinstance(template['file_docs'], dict):
            raise ValueError(f"Template '{name}': file_docs must be a dictionary")
        for file_path, doc in template['file_docs'].items():
            if not isinstance(file_path, str) or not isinstance(doc, str):
                raise ValueError(f"Template '{name}': Invalid file documentation entry: {file_path}")

def parse_user_config(config_path: str) -> dict:
    """Parse user configuration file."""
    path = Path(config_path)
    if not path.exists():
        raise FileNotFoundError(f"Configuration file not found: {path}")
    
    if path.suffix == '.toml':
        try:
            config = toml.load(path)
            logger.debug("Successfully loaded configuration from %s", path)
            return config
        except Exception as e:
            raise ValueError(f"Failed to parse TOML configuration: {e}")
    raise ValueError(f"Unsupported config file format: {path.suffix}")

def merge_configs(base: dict, override: dict) -> dict:
    """Merge override config into base config."""
    for key, value in override.items():
        if isinstance(value, dict) and key in base and isinstance(base[key], dict):
            merge_configs(base[key], value)
        else:
            base[key] = value
    return base

def load_config(user_config_path=None) -> dict:
    """Load default config and merge in user overrides if provided."""
    config = dict(DEFAULT_CONFIG)
    if user_config_path:
        try:
            user_overrides = parse_user_config(user_config_path)
            merge_configs(config, user_overrides)
            logger.debug("Successfully merged user configuration")
        except Exception as e:
            logger.error("Failed to load user configuration: %s", e)
            raise
    
    # Validate the final configuration
    validate_config(config)
    return config

def auto_detect_project_type(root_folder: Path) -> str:
    """Detect Python vs. JavaScript or default to unopinionated if ambiguous."""
    if (root_folder / "pyproject.toml").exists():
        return "python"
    elif (root_folder / "package.json").exists():
        return "javascript"
    return "unopinionated" 