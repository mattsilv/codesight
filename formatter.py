#!/usr/bin/env python3
"""
Text formatting functionality for CodeSight.
Handles content cleaning and formatting.
"""
import re
import time
from datetime import datetime
from typing import Dict, Any, List
import os

def clean_content(content: str) -> str:
    """
    Clean content to reduce token usage
    
    Args:
        content: Raw text content
        
    Returns:
        Cleaned content with reduced whitespace
    """
    # Replace multiple consecutive empty lines with a single one
    content = re.sub(r'\n\s*\n', '\n', content)
    
    # Remove trailing whitespace
    content = re.sub(r'[ \t]+$', '', content, flags=re.MULTILINE)
    
    # Additional optimizations to reduce token usage:
    
    # 1. Remove comment blocks (multi-line comments)
    content = re.sub(r'/\*[\s\S]*?\*/', '', content)  # Remove /* ... */ comments
    content = re.sub(r'^\s*\/\/.*$', '', content, flags=re.MULTILINE)  # Remove // comments
    content = re.sub(r'^\s*#.*$', '', content, flags=re.MULTILINE)  # Remove # comments
    
    # 2. Collapse multiple spaces into a single space
    content = re.sub(r' {2,}', ' ', content)
    
    # 3. Remove empty lines after comment removal
    content = re.sub(r'\n\s*\n', '\n', content)
    
    # 4. Remove import/require statements that are often not needed for understanding
    content = re.sub(r'^\s*import\s+.*$', '', content, flags=re.MULTILINE)
    content = re.sub(r'^\s*from\s+.*\s+import\s+.*$', '', content, flags=re.MULTILINE)
    content = re.sub(r'^\s*require\s*\(.*\);?$', '', content, flags=re.MULTILINE)
    
    # 5. Remove common boilerplate patterns
    content = re.sub(r'^\s*@.*$', '', content, flags=re.MULTILINE)  # Remove decorators
    
    return content.strip()

def format_time_ago(timestamp: float) -> str:
    """
    Format a timestamp as a human-readable time ago string
    
    Args:
        timestamp: Unix timestamp
        
    Returns:
        Human-readable string like "2 hours ago"
    """
    now = datetime.now().timestamp()
    diff = now - timestamp
    
    if diff < 60:
        return "just now"
    elif diff < 3600:
        minutes = diff / 60
        return f"{minutes:.0f} minute{'s' if minutes != 1 else ''} ago"
    elif diff < 86400:
        hours = diff / 3600
        return f"{hours:.0f} hour{'s' if hours != 1 else ''} ago"
    else:
        days = diff / 86400
        return f"{days:.1f} days ago"

def should_skip_file(file_path: str, content: str) -> bool:
    """
    Determine if a file should be skipped entirely based on content analysis
    
    Args:
        file_path: Path to the file
        content: File content
        
    Returns:
        True if the file should be skipped, False otherwise
    """
    # Skip files that are likely to be auto-generated
    if "DO NOT EDIT" in content or "AUTO-GENERATED" in content or "GENERATED FILE" in content:
        return True
    
    # Skip files that are mostly comments or documentation
    comment_lines = len(re.findall(r'^\s*(//|#|/\*|\*)', content, re.MULTILINE))
    total_lines = content.count('\n') + 1
    if total_lines > 0 and comment_lines / total_lines > 0.7:  # More than 70% comments
        return True
    
    # Skip files that are likely to be configuration or build files
    config_patterns = [
        r'\.config\.',
        r'\.conf\.',
        r'\.lock$',
        r'\.yaml$',
        r'\.yml$',
        r'\.ini$',
        r'\.env$',
        r'\.properties$'
    ]
    for pattern in config_patterns:
        if re.search(pattern, file_path, re.IGNORECASE):
            return True
    
    # Skip files that are likely to be minified or bundled
    if len(content) > 5000 and content.count('\n') < 10:  # Long content with few line breaks
        return True
    
    return False

def extract_key_sections(content: str, file_ext: str) -> str:
    """
    Extract only the most important sections from a file based on its type
    
    Args:
        content: File content
        file_ext: File extension
        
    Returns:
        Extracted key sections
    """
    # For JavaScript/TypeScript files
    if file_ext in ['.js', '.ts', '.jsx', '.tsx']:
        # Extract function and class definitions
        functions = re.findall(r'(function\s+\w+\s*\([^)]*\)\s*{[^{]*})', content)
        classes = re.findall(r'(class\s+\w+\s*{[^{]*})', content)
        exports = re.findall(r'(export\s+(?:const|let|var|function|class)\s+\w+\s*[=({])', content)
        
        # Combine the extracted sections
        extracted = "\n".join(functions + classes + exports)
        if extracted:
            return extracted
    
    # For Python files
    elif file_ext == '.py':
        # Extract function and class definitions
        functions = re.findall(r'(def\s+\w+\s*\([^)]*\)\s*:.*?(?=\n\S|$))', content, re.DOTALL)
        classes = re.findall(r'(class\s+\w+.*?:.*?(?=\n\S|$))', content, re.DOTALL)
        
        # Combine the extracted sections
        extracted = "\n".join(functions + classes)
        if extracted:
            return extracted
    
    # For HTML/XML files
    elif file_ext in ['.html', '.xml', '.svg']:
        # Extract only the structure, removing content
        structure = re.sub(r'>([^<]*)<', '><', content)
        return structure
    
    # For CSS/SCSS files
    elif file_ext in ['.css', '.scss', '.less']:
        # Extract only the selectors
        selectors = re.findall(r'([^{]+){[^}]*}', content)
        return "\n".join(selectors)
    
    # Default: return the original content
    return content

def process_file_content(file_path: str, content: str, max_lines: int, token_count: int, mod_time: float) -> Dict[str, Any]:
    """
    Process file content and create a structured representation
    
    Args:
        file_path: Path to the file
        content: Raw file content
        max_lines: Maximum number of lines before truncation
        token_count: Token count for the file
        mod_time: Modification timestamp
        
    Returns:
        Dictionary with processed file information
    """
    # Check if file should be skipped entirely
    if should_skip_file(file_path, content):
        return {
            'path': file_path,
            'time_ago': format_time_ago(mod_time),
            'token_count': token_count,
            'content': "[File skipped - likely auto-generated or configuration]",
            'truncated': False
        }
    
    # Get file extension
    _, ext = os.path.splitext(file_path)
    
    # Try to extract key sections first
    extracted_content = extract_key_sections(content, ext.lower())
    if extracted_content and len(extracted_content) < len(content):
        content = extracted_content
    
    lines = content.splitlines(True)  # Keep line endings
    time_ago = format_time_ago(mod_time)
    
    # Handle truncation for long files
    if len(lines) > max_lines:
        truncated_content = "".join(lines[:max_lines])
        cleaned_content = clean_content(truncated_content)
        return {
            'path': file_path,
            'time_ago': time_ago,
            'token_count': token_count,
            'content': cleaned_content,
            'truncated': True,
            'truncated_lines': len(lines) - max_lines
        }
    else:
        cleaned_content = clean_content(content)
        return {
            'path': file_path,
            'time_ago': time_ago,
            'token_count': token_count,
            'content': cleaned_content,
            'truncated': False
        }

def organize_by_directory(files_info: List[Dict[str, Any]]) -> Dict[str, List[Dict[str, Any]]]:
    """
    Organize files by directory
    
    Args:
        files_info: List of file information dictionaries
        
    Returns:
        Dictionary mapping directories to lists of file information
    """
    directory_structure = {}
    
    for file_info in files_info:
        # Get the directory path
        filename = os.path.basename(file_info['path'])
        
        # Use '.' for root directory
        if not os.path.dirname(file_info['path']):
            directory = '.'
        else:
            directory = os.path.dirname(file_info['path'])
        
        # Create a simplified file info for directory structure
        simple_info = {
            'filename': filename,
            'path': file_info['path'],
            'time_ago': file_info.get('time_ago', ''),
            'token_count': file_info.get('token_count', 0),
            'truncated': file_info.get('truncated', False)
        }
        
        # Add to directory structure
        if directory not in directory_structure:
            directory_structure[directory] = []
        directory_structure[directory].append(simple_info)
    
    return directory_structure 