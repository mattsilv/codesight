# ShellCheck Guide for CodeSight

## Overview
ShellCheck is a static analysis tool for shell scripts that provides warnings and suggestions for bash/sh shell scripts. It helps identify common bugs, potential issues, and stylistic inconsistencies.

## Installation
- macOS: `brew install shellcheck`
- Linux (Debian/Ubuntu): `apt-get install shellcheck`
- Linux (Fedora): `dnf install ShellCheck`
- Windows (via Chocolatey): `choco install shellcheck`

## Running ShellCheck
```bash
# Check a single script
shellcheck script.sh

# Always show suggestions (even "note" level)
shellcheck -Calways script.sh

# Specify shell dialect (bash, sh, dash, ksh)
shellcheck -s bash script.sh

# Exclude specific error codes
shellcheck -e SC2086,SC2181 script.sh
```

## Common Issues and Solutions

### 1. Quoting Variables
```bash
# BAD - unquoted variable
echo $variable

# GOOD - quoted variable
echo "$variable"
```

### 2. Testing Commands
```bash
# BAD - fragile test
if [ -n $var ]; then

# GOOD - robust test
if [ -n "$var" ]; then

# BETTER - modern test syntax
if [[ -n $var ]]; then
```

### 3. Command Substitution
```bash
# BAD - legacy syntax
result=`command`

# GOOD - modern syntax 
result=$(command)
```

### 4. ShellCheck Directives
Use directives to disable specific checks only when necessary:

```bash
# Disable a check for a single line
command # shellcheck disable=SC2059

# Disable a check for a block of code
# shellcheck disable=SC2059
command1
command2
# shellcheck enable=SC2059
```

Always add a comment explaining why you're disabling a check.

## Integrating with Pre-release
CodeSight automatically runs ShellCheck as part of the pre-release validation. You can run this validation with:

```bash
./pre_release.sh
```

## Best Practices
1. Fix all ShellCheck warnings before committing
2. Don't disable warnings unless absolutely necessary
3. Run ShellCheck locally before creating a pull request
4. Document reasons for disabling specific checks
5. Use ShellCheck's suggestion to learn shell scripting best practices

## Resources
- [ShellCheck GitHub repository](https://github.com/koalaman/shellcheck)
- [ShellCheck Wiki (detailed explanations of all warnings)](https://github.com/koalaman/shellcheck/wiki)