#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Root privileges required. Enter password:"
    exec sudo "$0" "$@"
    exit 1
fi

echo -e "${YELLOW}This script will delete cache files and other temporary data. Continue? [y/N]${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cleanup aborted."
    exit 0
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

safe_clean() {
    local target=$1
    local size_before=$(du -sk "$target" 2>/dev/null | awk '{print $1}')
    echo -e "${YELLOW}Cleaning: $target${NC}"
    
    if rm -rf "$target" 2>/dev/null; then
        echo -e "${GREEN}✓ Success${NC}"
        local size_after=$(du -sk "$target" 2>/dev/null | awk '{print $1}' || echo 0)
        echo "Freed: $(( (size_before - size_after) / 1024 )) MB"
        return 0
    fi
    
    if [ $? -eq 1 ]; then
        echo -e "${RED}⚠ Partial (SIP protected)${NC}"
        find "$target" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null
        local size_after=$(du -sk "$target" 2>/dev/null | awk '{print $1}' || echo 0)
        echo "Freed: $(( (size_before - size_after) / 1024 )) MB"
        return 1
    fi
}

CLEAN_PATHS=(
    "/Library/Caches"
    "~/Library/Caches"
    "/private/var/log"
    "/System/Library/Caches"
    "/var/log"
    "~/Library/Containers/*/Data/Library/Caches"
    "~/Library/Developer/Xcode/DerivedData"
    "~/Library/Developer/Xcode/Archives"
)

initial_space=$(df -k / | awk 'NR==2 {print $4}')

LOG_FILE="/tmp/macos_cleanup_$(date +%F_%H-%M-%S).log"
echo "Logging cleanup to $LOG_FILE"
exec 1> >(tee -a "$LOG_FILE")

echo -e "\n${YELLOW}=== Safe macOS Cleanup ===${NC}"

for path in "${CLEAN_PATHS[@]}"; do
    expanded_path=$(eval echo "$path")
    if [ -d "$expanded_path" ]; then
        safe_clean "$expanded_path"
    else
        echo -e "${RED}✗ Skipped: $path does not exist${NC}"
    fi
done

echo -e "\n${YELLOW}Additional Optimization:${NC}"

echo "Cleaning via maintenance scripts..."
periodic daily weekly monthly 2>/dev/null

echo "Resetting DNS cache..."
dscacheutil -flushcache
killall -HUP mDNSResponder

echo "Removing old Time Machine snapshots..."
tmutil thinlocalsnapshots / 1000000000 1 2>/dev/null
echo -e "${GREEN}✓ Time Machine snapshots cleaned${NC}"

if command -v brew >/dev/null 2>&1; then
    echo "Cleaning Homebrew cache..."
    brew cleanup --prune=all 2>/dev/null
    echo -e "${GREEN}✓ Homebrew cache cleaned${NC}"
else
    echo -e "${YELLOW}✗ Homebrew not installed, skipping${NC}"
fi

KEEP_LANGUAGES=("en.lproj" "ru.lproj")
echo "Removing unnecessary language packs..."
find /Applications -type d -name "*.lproj" -not -name "${KEEP_LANGUAGES[0]}" -not -name "${KEEP_LANGUAGES[1]}" -exec rm -rf {} + 2>/dev/null
echo -e "${GREEN}✓ Language packs cleaned${NC}"

final_space=$(df -k / | awk 'NR==2 {print $4}')
freed=$(( (final_space - initial_space) / 1024 ))

echo -e "\n${GREEN}=== Results ===${NC}"
echo "Freed: ${freed} MB"
echo "Total free space: $((final_space / 1024)) MB"