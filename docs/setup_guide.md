# CodeSight Setup Guide

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
