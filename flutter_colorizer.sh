#!/bin/bash

# Flutter output colorizer
# This script adds colors to Flutter output

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
BOLD='\033[1m'
BOLD_CYAN='\033[1;36m'
NC='\033[0m' # No Color

package_count=0
in_package_list=false

while IFS= read -r line; do
    # Count packages and suppress individual package lines
    if [[ "$line" =~ "Downloading packages" ]]; then
        echo -e "${CYAN}📦 $line${NC}"
        in_package_list=true
        package_count=0
        continue
    fi
    
    # Count packages in the list
    if [[ "$in_package_list" == true ]]; then
        if [[ "$line" =~ "available" ]]; then
            ((package_count++))
            continue
        elif [[ "$line" =~ "Got dependencies" ]]; then
            in_package_list=false
            echo -e "${GREEN}✅ Resolved dependencies: ${package_count} packages${NC}"
            continue
        fi
    fi
    
    # Color different types of Flutter output
    if [[ "$line" =~ "Resolving dependencies" ]]; then
        echo -e "${CYAN}📦 $line${NC}"
    elif [[ "$line" =~ "Got dependencies" ]] && [[ "$in_package_list" == false ]]; then
        echo -e "${GREEN}✅ $line${NC}"
    elif [[ "$line" =~ "Launching" ]]; then
        echo -e "${MAGENTA}🚀 $line${NC}"
    elif [[ "$line" =~ http://[^[:space:]]+ ]]; then
        # Extract and colorize URL
        url=$(echo "$line" | grep -o 'http://[^[:space:]]*')
        
        # Use string manipulation instead of sed
        prefix=${line%%$url*}
        suffix=${line#*$url}
        
        echo -e "🌐 ${prefix}${BOLD_CYAN}${url}${NC}${suffix}"
    elif [[ "$line" =~ "Hot reload" ]]; then
        echo -e "${RED}🔥 $line${NC}"
    elif [[ "$line" =~ "Waiting for connection" ]]; then
        echo -e "${YELLOW}⏳ $line${NC}"
    elif [[ "$line" =~ "Flutter run key commands" ]]; then
        echo -e "${BOLD}${BLUE}⌨️  $line${NC}"
    elif [[ "$line" =~ ^[rRhdc] ]] && [[ ${#line} -lt 100 ]]; then
        # Key command descriptions
        echo -e "${CYAN}   $line${NC}"
    elif [[ "$line" =~ "packages have newer versions" ]]; then
        # Show package update summary
        echo -e "${YELLOW}ℹ️  $line${NC}"
    else
        echo "$line"
    fi
done
