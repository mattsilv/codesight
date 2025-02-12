"""Constants used across test files."""

# File group constants
CONFIG_GROUP = 2  # .env, config.py
CORE_GROUP = 1  # README.md, pyproject.toml
DOCS_GROUP = 6  # docs/, examples/
ENTRY_POINT_GROUP = 3  # __init__.py, main.py
SOURCE_GROUP = 4  # src/, lib/, core/
TEST_GROUP = 5  # test_*.py, tests/
BUILD_ARTIFACT_GROUP = 7  # dist/, build/, target/
OTHER_GROUP = 8  # Other files

# Test constants
DEFAULT_ENCODING = "utf-8"
DEFAULT_TRUNCATE_LENGTH = 5

# Remove unnecessary count constants as they're now handled directly in tests
