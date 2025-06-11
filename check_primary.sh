#!/bin/bash

clear
echo -e "\n=== Detecting Disks ==="
lsblk -dno NAME,SIZE,TYPE | grep disk

echo -e "\n=== Choose Disk ==="
echo -n "Enter the full path of the disk to format (e.g., /dev/sdX): "
read DISK

echo -n "Run in dry-run mode (no partitioning or formatting will occur)? [y/N]: "
read DRY_RUN

if [[ "$DRY_RUN" =~ ^[Yy]$ ]]; then
    DRY_RUN=true
else
    DRY_RUN=false
fi

echo -e "WARNING: This will erase all data on $DISK. Continue? [y/N]: "
read CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Get RAM size
echo -e "\n=== Getting RAM Size ==="
echo -n "Enter RAM in MB (leave blank to auto-detect): "
read RAM_MB

if [[ -z "$RAM_MB" ]]; then
    RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    RAM_MB=$((RAM_KB / 1024))
fi

SWAP_MB=$((RAM_MB * 2))
echo "Using RAM_MB = $RAM_MB → Swap size will be $SWAP_MB MB"

# Calculate total disk size in MB
total_mb=$(lsblk -b -dn -o SIZE "$DISK")
total_mb=$((total_mb / 1024 / 1024))

# Define fixed partition sizes
BOOT_MB=500
SRC_MB=35672
OPT_MB=11890
TMP_MB=11890
USR_MB=47563
ROOT_MB=47563

# Calculate remaining for /home
used_mb=$((BOOT_MB + SWAP_MB + SRC_MB + OPT_MB + TMP_MB + USR_MB + ROOT_MB))
HOME_MB=$((total_mb - used_mb))

# Display planned layout
echo -e "\nPlanned Partition Layout (in MB):"
echo "1. /boot     : $BOOT_MB"
echo "2. swap      : $SWAP_MB"
echo "3. /usr/src  : $SRC_MB"
echo "4. /opt      : $OPT_MB"
echo "5. /tmp      : $TMP_MB"
echo "6. /usr      : $USR_MB"
echo "7. /         : $ROOT_MB"
echo "8. /home     : $HOME_MB"
echo "Total Used  : $((used_mb + HOME_MB)) / $total_mb MB"

# Confirm before proceeding
echo -n "Do you approve this layout and want to proceed with partitioning and formatting? [y/N]: "
read APPROVE
if [[ ! "$APPROVE" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

if $DRY_RUN; then
    echo "Dry-run mode enabled. No changes made."
    exit 0
fi

# Placeholder for actual partitioning logic
echo "Proceeding with actual partitioning..."
# (Insert your partitioning commands here)

