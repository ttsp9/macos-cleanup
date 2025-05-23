#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    echo "Admin rights needed. Enter your password:"
    exec sudo "$0" "$@"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Measure initial disk space (in KB)
initial_space=$(df -k / | awk 'NR==2 {print $4}')

echo -e "\n${YELLOW}=== Developer System Cleaner ===${NC}"

# Node.js Deep Clean
echo -e "\n${YELLOW}[Node.js Cleanup]${NC}"
find ~ -type d -name "node_modules" -prune ! -path "~/Library/*" -exec du -sh {} + 2>/dev/null
yn="y"
if [ "$yn" = "y" ]; then
    find ~ -type d -name "node_modules" -prune ! -path "~/Library/*" -exec rm -rf {} + 2>/dev/null
    echo -e "${GREEN}Removed node_modules${NC}"
fi
npm cache clean --force 2>/dev/null
yarn cache clean 2>/dev/null
rm -rf ~/.npm/_logs/* 2>/dev/null

# Python Cleanup
echo -e "\n${YELLOW}[Python Cleanup]${NC}"
pip cache purge 2>/dev/null
rm -rf ~/.cache/pip/* 2>/dev/null
find ~ -type d -name "__pycache__" ! -path "~/Library/*" -exec rm -rf {} + 2>/dev/null
find ~ -type d -name ".venv" ! -path "~/Library/*" -exec du -sh {} + 2>/dev/null

# Docker Nuclear Option
echo -e "\n${YELLOW}[Docker Cleanup]${NC}"
if command -v docker >/dev/null 2>&1; then
    docker system prune -af --volumes 2>/dev/null
    rm -rf ~/Library/Containers/com.docker.docker/Data/* 2>/dev/null
    echo -e "${GREEN}Docker cleaned${NC}"
else
    echo -e "${RED}Docker not installed, skipping${NC}"
fi

# Development Cache
echo -e "\n${YELLOW}[Development Cache]${NC}"
rm -rf ~/.cache/* ~/.gradle/caches/* ~/.m2/repository/* ~/.ivy2/cache/* 2>/dev/null
echo -e "${GREEN}Development caches cleared${NC}"

# System-Level Clean
echo -e "\n${YELLOW}[System Cleanup]${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null
rm -rf ~/Library/Application\ Support/Slack/Service\ Worker/CacheStorage/* 2>/dev/null
killall -HUP mDNSResponder 2>/dev/null
echo -e "${GREEN}System caches cleared${NC}"

# Time Machine Local Snapshots
echo -e "\n${YELLOW}[Time Machine Snapshots]${NC}"
if command -v tmutil >/dev/null 2>&1; then
    tmutil thinlocalsnapshots / 1000000000 1 2>/dev/null
    echo -e "${GREEN}Time Machine snapshots cleaned${NC}"
else
    echo -e "${RED}tmutil not found, skipping${NC}"
fi

# Mail App Attachments and Cache
echo -e "\n${YELLOW}[Mail App Cleanup]${NC}"
rm -rf ~/Library/Mail/V*/MailData/AvailableDownloads/* 2>/dev/null
rm -rf ~/Library/Mail/V*/MailData/Attachments/* 2>/dev/null
echo -e "${GREEN}Mail app caches cleared${NC}"

# iOS Simulator Data
echo -e "\n${YELLOW}[iOS Simulator Cleanup]${NC}"
rm -rf ~/Library/Developer/CoreSimulator/Caches/* 2>/dev/null
rm -rf ~/Library/Developer/CoreSimulator/Devices/* 2>/dev/null
echo -e "${GREEN}iOS simulator data cleared${NC}"

# Homebrew Cache
echo -e "\n${YELLOW}[Homebrew Cleanup]${NC}"
if command -v brew >/dev/null 2>&1; then
    brew cleanup --prune=all 2>/dev/null
    rm -rf ~/Library/Caches/Homebrew/* 2>/dev/null
    echo -e "${GREEN}Homebrew cache cleaned${NC}"
else
    echo -e "${RED}Homebrew not installed, skipping${NC}"
fi

# Application Logs
echo -e "\n${YELLOW}[Application Logs Cleanup]${NC}"
rm -rf ~/Library/Logs/* 2>/dev/null
find /var/log -type f -size +10M -exec truncate -s 0 {} \; 2>/dev/null
echo -e "${GREEN}Application logs cleared${NC}"

# Trash Bin
echo -e "\n${YELLOW}[Trash Cleanup]${NC}"
rm -rf ~/.Trash/* 2>/dev/null
echo -e "${GREEN}Trash emptied${NC}"

# iOS Backups
echo -e "\n${YELLOW}[iOS Backups Cleanup]${NC}"
rm -rf ~/Library/Application\ Support/MobileSync/Backup/* 2>/dev/null
echo -e "${GREEN}Old iOS backups cleared${NC}"

# Podcasts and iTunes Cache
echo -e "\n${YELLOW}[Podcasts and iTunes Cleanup]${NC}"
rm -rf ~/Library/Group\ Containers/*.com.apple.podcasts/Caches/* 2>/dev/null
rm -rf ~/Library/Caches/com.apple.iTunes/* 2>/dev/null
echo -e "${GREEN}Podcasts and iTunes caches cleared${NC}"

# Downloads Cleanup
echo -e "\n${YELLOW}[Downloads Cleanup]${NC}"
rm -rf ~/Downloads/* 2>/dev/null
echo -e "${GREEN}Downloads folder cleared${NC}"

# Screenshots Cleanup
echo -e "\n${YELLOW}[Screenshots Cleanup]${NC}"
rm -rf ~/Desktop/Screen\ Shot*.png 2>/dev/null
rm -rf ~/Desktop/Screenshot*.png 2>/dev/null
echo -e "${GREEN}Desktop screenshots cleared${NC}"

# Bin Cleanup
echo -e "\n${YELLOW}[Bin Cleanup]${NC}"
rm -rf ~/bin/* 2>/dev/null
echo -e "${GREEN}Bin folder cleared${NC}"

# Space Reclamation
echo -e "\n${YELLOW}[Space Reclamation]${NC}"
echo "Writing zeros to 90% of free disk space to optimize usage (useful for virtual machines)."
echo "This may take several minutes on large disks..."
skip_reclamation="n"
if [[ ! "$skip_reclamation" =~ ^[Nn]$ ]]; then
    echo "Skipping space reclamation."
else
    free_space_kb=$(df -k / | awk 'NR==2 {print $4}')
    free_space_mb=$((free_space_kb / 1024))
    target_mb=$((free_space_mb * 99 / 100))
    echo "Writing ${target_mb}MB of zeros to ~/zero (this may take a moment)..."
    count=$((target_mb / 16))
    if [ $count -gt 0 ]; then
        dd if=/dev/zero of=~/zero bs=16m count=$count status=progress
        rm ~/zero
        echo "Space reclamation complete."
    else
        echo -e "${RED}Not enough free space for reclamation${NC}"
    fi
fi

# Final Report
final_space=$(df -k / | awk 'NR==2 {print $4}')
freed=$(( (final_space - initial_space) / 1024 ))

echo -e "\n${GREEN}=== Cleanup Complete ===${NC}"
echo "Freed: ${freed} MB"
echo "Total free space: $((final_space / 1024)) MB"