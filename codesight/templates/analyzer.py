#!/usr/bin/env python3
"""
Example analyzer module that will be copied to the user's .codesight directory.
This is just a template file to demonstrate what gets copied.
"""

def analyze_file(filename):
    """Simple analyzer that counts lines of code."""
    try:
        with open(filename, 'r') as f:
            lines = f.readlines()
        
        code_lines = len([line for line in lines if line.strip() and not line.strip().startswith('#')])
        comment_lines = len([line for line in lines if line.strip().startswith('#')])
        blank_lines = len([line for line in lines if not line.strip()])
        
        return {
            'total_lines': len(lines),
            'code_lines': code_lines,
            'comment_lines': comment_lines,
            'blank_lines': blank_lines
        }
    except Exception as e:
        return {'error': str(e)}

def main():
    """Example main function."""
    print("CodeSight Analyzer Template")
    print("This is an example template file that gets copied to your .codesight directory.")
    print("You can customize this file for your specific project needs.")

if __name__ == "__main__":
    main() 