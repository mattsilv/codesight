#!/bin/bash
# Update checker utility for CodeSight

# URLs and settings for update check
REPO_OWNER="mattsilv"
REPO_NAME="codesight"
UPDATE_CHECK_INTERVAL=7 # Days between update checks
LAST_CHECK_FILE="$HOME/.codesight_update_check"

function check_for_updates() {
    # Skip update check if running in CI/CD or non-interactive shell
    if [[ -n "$CI" || ! -t 0 ]]; then
        return 0
    fi
    
    # Check if we should check for updates (not too frequent)
    local should_check=false
    
    if [[ ! -f "$LAST_CHECK_FILE" ]]; then
        should_check=true
    else
        local last_check=$(cat "$LAST_CHECK_FILE" 2>/dev/null || echo "0")
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_check))
        local day_seconds=$((60 * 60 * 24 * UPDATE_CHECK_INTERVAL))
        
        if [[ $time_diff -gt $day_seconds ]]; then
            should_check=true
        fi
    fi
    
    if [[ "$should_check" == "true" ]]; then
        echo "Checking for updates..."
        perform_update_check
        echo $(date +%s) > "$LAST_CHECK_FILE"
    fi
}

function perform_update_check() {
    # Get the latest version from the remote repo
    local latest_version=""
    
    # Try using curl if available
    if command -v curl &>/dev/null; then
        latest_version=$(curl -s "https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/main/codesight.sh" | grep -m 1 "VERSION=" | cut -d'"' -f2)
    # Try using wget if available
    elif command -v wget &>/dev/null; then
        latest_version=$(wget -qO- "https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/main/codesight.sh" | grep -m 1 "VERSION=" | cut -d'"' -f2)
    # If neither is available, skip update check
    else
        return 0
    fi
    
    # If we couldn't get the latest version, skip
    if [[ -z "$latest_version" ]]; then
        return 0
    fi
    
    # Compare versions (assuming semantic versioning)
    if [[ "$latest_version" != "$VERSION" ]]; then
        if is_newer_version "$latest_version" "$VERSION"; then
            echo "📢 A new version of CodeSight is available!"
            echo "   Current version: $VERSION"
            echo "   Latest version: $latest_version"
            echo ""
            echo "   To update, run: git pull"
            echo "   Or visit: https://github.com/$REPO_OWNER/$REPO_NAME/releases"
            echo ""
        fi
    fi
}

function is_newer_version() {
    local latest=$1
    local current=$2
    
    # Extract major, minor, patch version numbers
    local latest_major=$(echo "$latest" | cut -d. -f1)
    local latest_minor=$(echo "$latest" | cut -d. -f2)
    local latest_patch=$(echo "$latest" | cut -d. -f3)
    
    local current_major=$(echo "$current" | cut -d. -f1)
    local current_minor=$(echo "$current" | cut -d. -f2)
    local current_patch=$(echo "$current" | cut -d. -f3)
    
    # Compare versions
    if [[ "$latest_major" -gt "$current_major" ]]; then
        return 0 # True - newer version
    elif [[ "$latest_major" -eq "$current_major" && "$latest_minor" -gt "$current_minor" ]]; then
        return 0 # True - newer version
    elif [[ "$latest_major" -eq "$current_major" && "$latest_minor" -eq "$current_minor" && "$latest_patch" -gt "$current_patch" ]]; then
        return 0 # True - newer version
    else
        return 1 # False - not newer version
    fi
}