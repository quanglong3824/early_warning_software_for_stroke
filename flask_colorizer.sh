#!/bin/bash

# Flask output colorizer
# This script adds colors to Flask/Python output

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
BOLD='\033[1m'
BOLD_CYAN='\033[1;36m'
NC='\033[0m' # No Color

while IFS= read -r line; do
    # Check for HTTP URLs and colorize them
    if [[ "$line" =~ http://[^[:space:]]+ ]] || [[ "$line" =~ https://[^[:space:]]+ ]]; then
        # Extract URL
        url=$(echo "$line" | grep -oE 'https?://[^[:space:]]*')
        
        # Use printf to handle colors correctly without sed issues
        # We split the line by the URL and reconstruct it with colors
        prefix=${line%%$url*}
        suffix=${line#*$url}
        
        colored_line="${prefix}${BOLD_CYAN}${url}${NC}${suffix}"
        
        # Apply additional coloring based on content
        if [[ "$line" =~ "Running on" ]]; then
            echo -e "🌐 ${colored_line}"
        elif [[ "$line" =~ "📍" ]]; then
            echo -e "${BLUE}${colored_line}${NC}"
        else
            echo -e "${colored_line}"
        fi
    # Color different types of Flask output
    elif [[ "$line" =~ "Loading models" ]]; then
        echo -e "${CYAN}📦 $line${NC}"
    elif [[ "$line" =~ "✅" ]]; then
        echo -e "${GREEN}$line${NC}"
    elif [[ "$line" =~ "❌" ]]; then
        echo -e "${RED}$line${NC}"
    elif [[ "$line" =~ "🚀 Starting Flask" ]]; then
        echo -e "${BOLD}${MAGENTA}$line${NC}"
    elif [[ "$line" =~ "WARNING" ]] || [[ "$line" =~ "InconsistentVersionWarning" ]]; then
        echo -e "${YELLOW}⚠️  $line${NC}"
    elif [[ "$line" =~ "Debugger" ]]; then
        echo -e "${CYAN}🔧 $line${NC}"
    elif [[ "$line" =~ "Serving Flask app" ]]; then
        echo -e "${MAGENTA}⚡ $line${NC}"
    else
        echo "$line"
    fi
done
