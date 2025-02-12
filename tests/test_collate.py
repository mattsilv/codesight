"""Tests for the collate module."""
from pathlib import Path
import pytest
from codesight.collate import (
    parse_gitignore,
    should_ignore,
    truncate_large_literals,
    process_python_file,
    gather_and_collate
)

def test_parse_gitignore(tmp_path):
    """Test parsing of .gitignore file."""
    gitignore = tmp_path / '.gitignore'
    gitignore.write_text("*.pyc\n#comment\n\n/build/\n")
    
    patterns = parse_gitignore(tmp_path)
    assert patterns == ['*.pyc', '/build/']
    
    # Test with no .gitignore
    empty_dir = tmp_path / 'empty'
    empty_dir.mkdir()
    assert parse_gitignore(empty_dir) == []

def test_should_ignore():
    """Test file ignore logic."""
    config = {
        'exclude_files': ['secret.txt'],
        'exclude_extensions': ['.pyc'],
        'exclude_patterns': ['**/temp/*']
    }
    
    assert should_ignore(Path('secret.txt'), [], config)
    assert should_ignore(Path('test.pyc'), [], config)
    assert should_ignore(Path('temp/file.txt'), [], config)
    assert not should_ignore(Path('normal.py'), [], config)

def test_process_python_file():
    """Test Python file processing with truncation."""
    content = """
data = [1, 2, 3, 4, 5, 6, 7, 8]
small = [1, 2]
nested = {'a': [1, 2, 3, 4, 5, 6]}
"""
    processed = process_python_file(content, 3)
    assert '[1, 2]' in processed  # Small list unchanged
    assert 'data = [1, 2, 3]' in processed  # Large list truncated
    assert "'a': [1, 2, 3]" in processed  # Nested list truncated

def test_gather_and_collate(tmp_path):
    """Test full file gathering and collation."""
    # Create test files
    (tmp_path / 'test.py').write_text("print('hello')")  # Use single quotes to match ast.unparse output
    (tmp_path / 'README.md').write_text('# Test')
    (tmp_path / 'ignore.pyc').write_text('binary')
    
    config = {
        'include_extensions': ['.py', '.md'],
        'exclude_extensions': ['.pyc'],
        'exclude_files': [],
        'exclude_patterns': [],
        'truncate_py_literals': 5,
        'include_files': []
    }
    
    result = gather_and_collate(tmp_path, config)
    
    assert 'test.py' in result
    assert 'README.md' in result
    assert "print('hello')" in result  # Match the single quotes used in the file
    assert '# Test' in result
    assert 'ignore.pyc' not in result 