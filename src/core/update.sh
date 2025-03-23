#!/bin/bash
# Update checking utility for CodeSight

# Last time we checked for updates (epoch seconds)
LAST_UPDATE_CHECK=0
UPDATE_CHECK_INTERVAL=$((60*60*24*7))  # Check once a week

function check_for_updates() {
    # Only check once per session and not too frequently
    local current_time=$(date +%s)
    local time_since_check=$((current_time - LAST_UPDATE_CHECK))
    
    if [[ $time_since_check -lt $UPDATE_CHECK_INTERVAL ]]; then
        return 0
    fi
    
    # Update the last check time
    LAST_UPDATE_CHECK=$current_time
    
    # Notify user that we're checking for updates (if not silent)
    if [[ "$1" != "silent" ]]; then
        echo "   Checking for updates..."
    fi
    
    # Use GitHub API to get the latest release if curl is available
    if command -v curl &>/dev/null; then
        local latest_version
        latest_version=$(curl -s "https://api.github.com/repos/USERNAME/codesight/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')
        
        # If we got a version, compare it
        if [[ -n "$latest_version" && "$latest_version" != "null" ]]; then
            compare_versions "$VERSION" "$latest_version"
            return $?
        fi
    fi
    
    return 0
}

function compare_versions() {
    local current="$1"
    local latest="$2"
    
    # Convert versions to array of integers
    IFS='.' read -ra current_parts <<< "$current"
    IFS='.' read -ra latest_parts <<< "$latest"
    
    # Compare each part
    for i in {0..2}; do
        if [[ "${current_parts[$i]}" -lt "${latest_parts[$i]}" ]]; then
            # New version available
            echo "   ✨ New version available: v$latest (you have v$current)"
            echo "   Run 'git pull' to update or visit our GitHub page"
            return 1
        elif [[ "${current_parts[$i]}" -gt "${latest_parts[$i]}" ]]; then
            # Current version is ahead (development/preview)
            return 0
        fi
    done
    
    # Versions are equal
    return 0
}

function perform_update_check() {
    check_for_updates
    local update_status=$?
    
    if [[ $update_status -eq 0 ]]; then
        echo "✅ You are using the latest version (v$VERSION)"
    fi
}