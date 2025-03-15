# CodeSight Setup Guide

## System Requirements

CodeSight requires:
- Bash shell environment
  - Built-in on macOS and Linux
  - Windows users need Git Bash installed
- Standard command line tools
  - `find` - for locating files
  - `grep` - for searching file contents
  - `wc` - for counting lines and file sizes
  - Clipboard commands (optional): 
    - macOS: `pbcopy`
    - Linux: `xclip`
    - Windows: `clip.exe`

## Running CodeSight

You can run CodeSight from any directory using the full path:

```bash
/path/to/codesight.sh [command]
```

For example:

```bash
/path/to/codesight.sh init
/path/to/codesight.sh analyze
```

On Windows, you can also use the batch file:

```batch
C:\path\to\codesight.bat [command]
```

## Setting Up an Alias (Recommended)

### For Mac Users

Recent Mac systems (macOS Catalina and later) use Zsh as the default shell.

1. Add the alias to your Zsh profile:

   ```bash
   echo 'alias codesight="/path/to/codesight.sh"' >> ~/.zshrc
   ```

2. Reload your shell configuration:

   ```bash
   source ~/.zshrc
   ```

3. Verify the alias works:
   ```bash
   codesight help
   ```

### For Linux/Other Users

#### Bash Shell

1. Add the alias to your Bash profile:

   ```bash
   echo 'alias codesight="/path/to/codesight.sh"' >> ~/.bashrc
   ```

2. Reload your shell configuration:
   ```bash
   source ~/.bashrc
   ```

#### Zsh Shell

1. Add the alias to your Zsh profile:

   ```bash
   echo 'alias codesight="/path/to/codesight.sh"' >> ~/.zshrc
   ```

2. Reload your shell configuration:
   ```bash
   source ~/.zshrc
   ```

#### Fish Shell

1. Add the alias to your Fish config:

   ```bash
   echo 'alias codesight="/path/to/codesight.sh"' >> ~/.config/fish/config.fish
   ```

2. Reload your shell configuration:
   ```bash
   source ~/.config/fish/config.fish
   ```

### For Windows Users

#### Option 1: Git Bash Alias

1. Add the alias to your Git Bash profile:

   ```bash
   echo 'alias codesight="/path/to/codesight.sh"' >> ~/.bashrc
   ```

2. Reload your shell configuration:
   ```bash
   source ~/.bashrc
   ```

#### Option 2: Add to Windows PATH

1. Right-click on 'This PC' or 'My Computer' and select 'Properties'
2. Click on 'Advanced system settings'
3. Click the 'Environment Variables' button
4. Under 'System variables', find and select 'Path', then click 'Edit'
5. Click 'New' and add the full path to the CodeSight directory
6. Click 'OK' on all dialogs to save
7. Restart any open command prompts

After adding to PATH, you can use:
```
codesight.bat
```

## Getting Started

After installation, you can:

1. Initialize CodeSight in your project:

   ```bash
   codesight init
   ```

2. Analyze your codebase:

   ```bash
   codesight analyze
   ```

3. Get information about your configuration:

   ```bash
   codesight info
   ```

4. View help:
   ```bash
   codesight help
   ```
