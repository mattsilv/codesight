#!/bin/bash
# CodeSight ASCII logo and display functionality

# ASCII logo for CodeSight
CODESIGHT_LOGO=" ██████╗ ██████╗ ██████╗ ███████╗███████╗██╗ ██████╗ ██╗  ██╗████████╗
██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝██║██╔════╝ ██║  ██║╚══██╔══╝
██║     ██║   ██║██║  ██║█████╗  ███████╗██║██║  ███╗███████║   ██║   
██║     ██║   ██║██║  ██║██╔══╝  ╚════██║██║██║   ██║██╔══██║   ██║   
╚██████╗╚██████╔╝██████╔╝███████╗███████║██║╚██████╔╝██║  ██║   ██║   
 ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   "

# Display the CodeSight logo
function display_logo() {
    # Only display logo once per session using a temporary file as a flag
    local logo_shown_file="/tmp/codesight_logo_shown"
    local current_session_id="$(date +%Y%m%d)"
    
    # Check if we already showed the logo this session
    if [[ -f "$logo_shown_file" ]] && [[ "$(cat "$logo_shown_file")" == "$current_session_id" ]]; then
        return 0
    fi
    
    # If TERM is not dumb and we're not in a pipeline, show the logo with color
    if [[ "$TERM" != "dumb" ]] && [[ -t 1 ]]; then
        echo -e "\033[0;36m$CODESIGHT_LOGO\033[0m"
        echo "" # Add a blank line for spacing
    fi
    
    # Mark logo as shown for this session
    echo "$current_session_id" > "$logo_shown_file"
}