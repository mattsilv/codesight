#!/usr/bin/env python3
"""
Core functionality for CodeSight.
Handles file analysis, filtering, and overview generation.
"""
import os
import re
import time
from typing import Dict, List, Tuple, Any, Optional
from pathlib import Path
import tiktoken

import exclusions
import formatter
import config

def is_binary_file(file_path: str) -> bool:
    """
    Check if a file is binary
    
    Args:
        file_path: Path to the file
        
    Returns:
        True if the file is binary, False otherwise
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            f.read(1024)  # Try to read as text
        return False
    except UnicodeDecodeError:
        return True

def count_tokens(text: str, model: str = "gpt-4") -> int:
    """
    Count tokens in text using tiktoken
    
    Args:
        text: Text to count tokens in
        model: Model to use for token counting
        
    Returns:
        Token count
    """
    try:
        encoding = tiktoken.encoding_for_model(model)
        return len(encoding.encode(text))
    except Exception:
        # Fallback to approximate token count
        return len(text.split())

def collect_files(root_dir: str, file_extensions: List[str]) -> List[str]:
    """
    Collect files from the directory tree
    
    Args:
        root_dir: Root directory to start from
        file_extensions: List of file extensions to include
        
    Returns:
        List of file paths
    """
    files = []
    ignore_patterns = exclusions.prepare_ignore_patterns(root_dir)
    
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Filter out directories that should be excluded
        dirnames[:] = [d for d in dirnames if not exclusions.should_exclude(os.path.join(dirpath, d), ignore_patterns)]
        
        for filename in filenames:
            file_path = os.path.join(dirpath, filename)
            rel_path = os.path.relpath(file_path, root_dir)
            
            # Skip if the file should be excluded
            if exclusions.should_exclude(rel_path, ignore_patterns):
                continue
                
            # Skip if the file doesn't have one of the specified extensions
            if not any(filename.endswith(ext) for ext in file_extensions):
                continue
                
            # Skip binary files if configured
            if config.TOKEN_OPTIMIZATION["SKIP_BINARY_FILES"] and is_binary_file(file_path):
                continue
                
            # Skip files larger than the maximum size
            if os.path.getsize(file_path) > config.TOKEN_OPTIMIZATION["MAX_FILE_SIZE"]:
                continue
                
            files.append(file_path)
            
            # Limit the number of files if configured
            if len(files) >= config.TOKEN_OPTIMIZATION["MAX_FILES"]:
                break
                
    return files

def analyze_codebase(
    root_dir: str, 
    file_extensions: Optional[List[str]] = None,
    model: str = "gpt-4",
    progress_callback = None
) -> Dict[str, Any]:
    """
    Analyze codebase and return structured results
    
    Args:
        root_dir: Root directory of the codebase
        file_extensions: List of file extensions to include
        model: Model to use for token counting
        progress_callback: Callback function for progress updates
        
    Returns:
        Dictionary with analysis results
    """
    if file_extensions is None:
        file_extensions = config.FILE_EXTENSIONS
        
    # Collect files
    files = collect_files(root_dir, file_extensions)
    
    # Initialize counters
    total_files = len(files)
    processed_files = 0
    char_count = 0
    line_count = 0
    token_count = 0
    original_chars = 0
    original_lines = 0
    original_tokens = 0
    
    # Initialize file type statistics
    file_types = {}
    
    # Initialize token counts by folder and file
    token_counts_by_folder = {}
    token_counts_by_file = {}
    
    # Process files
    files_info = []
    
    for file_path in files:
        try:
            # Get relative path
            rel_path = os.path.relpath(file_path, root_dir)
            
            # Get file extension
            _, ext = os.path.splitext(file_path)
            ext = ext.lower()
            
            # Update file type statistics
            if ext not in file_types:
                file_types[ext] = 0
            file_types[ext] += 1
            
            # Get file modification time
            mod_time = os.path.getmtime(file_path)
            
            # Read file content
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # Skip files with specific content patterns
            if any(pattern in content for pattern in config.TOKEN_OPTIMIZATION["SKIP_CONTENT_PATTERNS"]):
                continue
                
            # Count original metrics
            original_file_chars = len(content)
            original_file_lines = content.count('\n') + 1
            original_file_tokens = count_tokens(content, model)
            
            original_chars += original_file_chars
            original_lines += original_file_lines
            original_tokens += original_file_tokens
            
            # Process file content
            file_info = formatter.process_file_content(
                rel_path, 
                content, 
                config.TOKEN_OPTIMIZATION["MAX_LINES_PER_FILE"], 
                original_file_tokens,
                mod_time
            )
            
            # Update metrics with processed content
            processed_content = file_info['content']
            char_count += len(processed_content)
            line_count += processed_content.count('\n') + 1
            file_tokens = count_tokens(processed_content, model)
            token_count += file_tokens
            
            # Update token counts by folder
            folder = os.path.dirname(rel_path) or '.'
            if folder not in token_counts_by_folder:
                token_counts_by_folder[folder] = 0
            token_counts_by_folder[folder] += file_tokens
            
            # Update token counts by file
            token_counts_by_file[rel_path] = file_tokens
            
            # Add file info to the list
            files_info.append(file_info)
            
            # Update progress
            processed_files += 1
            if progress_callback:
                progress_callback(processed_files / total_files)
                
        except Exception as e:
            print(f"Error processing file {file_path}: {e}")
            
    # Sort files by token count
    files_info.sort(key=lambda x: x['token_count'], reverse=True)
    
    # Get top token folders and files
    top_token_folders = sorted(token_counts_by_folder.items(), key=lambda x: x[1], reverse=True)[:5]
    top_token_files = sorted(token_counts_by_file.items(), key=lambda x: x[1], reverse=True)[:5]
    
    # Return analysis results
    return {
        'file_count': len(files_info),
        'file_extensions': file_extensions,
        'file_types': file_types,
        'char_count': char_count,
        'line_count': line_count,
        'token_count': token_count,
        'original_chars': original_chars,
        'original_lines': original_lines,
        'original_tokens': original_tokens,
        'files_info': files_info,
        'top_token_folders': top_token_folders,
        'top_token_files': top_token_files
    }