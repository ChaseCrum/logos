#!/bin/bash

set -e

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
ROOT_MB=75000  # fixed size for /
BIOS_BOOT_MB=2

# Total disk size
total_mb=$(lsblk -b -dn -o SIZE "$DISK")
total_mb=$((total_mb / 1024 / 1024))

# Calculate space left for /home
used_mb=$((BIOS_BOOT_MB + SWAP_MB + ROOT_MB))
HOME_MB=$((total_mb - used_mb))

# Show plan
echo -e "\nPlanned Partition Layout (in MB):"
echo "1. BIOS Boot : $BIOS_BOOT_MB"
echo "2. swap      : $SWAP_MB"
echo "3. /         : $ROOT_MB"
echo "4. /home     : $HOME_MB"
echo "Total Used  : $((BIOS_BOOT_MB + SWAP_MB + ROOT_MB + HOME_MB)) / $total_mb MB"

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

echo -e "\n=== Partitioning Disk (GPT) ==="

# Wipe and prepare
sgdisk --zap-all "$DISK" || true
dd if=/dev/zero of="$DISK" bs=512 count=2048 status=none
wipefs -a "$DISK"
parted -s "$DISK" mklabel gpt

START_MB=1
part_num=1

create_partition() {
    local SIZE_MB=$1
    local LABEL=$2
    local FS=$3
    local END_MB=$((START_MB + SIZE_MB - 1))

    parted -s "$DISK" mkpart primary "${START_MB}MB" "${END_MB}MB"

    if [[ "$LABEL" == "BIOS" ]]; then
        parted -s "$DISK" set $part_num bios_grub on
    fi

    echo "Created $LABEL from $START_MB MB to $END_MB MB"
    START_MB=$((END_MB + 1))
    part_num=$((part_num + 1))
}

create_partition $BIOS_BOOT_MB "BIOS" "none"
create_partition $SWAP_MB "swap" "swap"
create_partition $ROOT_MB "/" "xfs"
create_partition $HOME_MB "/home" "xfs"

echo -e "\n=== Formatting Partitions ==="
partprobe "$DISK"
sleep 2

format_partition() {
    local PART=$1
    local FS=$2
    local LABEL=$3

    if [[ "$FS" == "swap" ]]; then
        mkswap "$PART"
        echo "Formatted $PART as swap"
    else
        mkfs.xfs -f "$PART"
        echo "Formatted $PART as xfs ($LABEL)"
    fi
}

format_partition "${DISK}2" "swap" "swap"
format_partition "${DISK}3" "xfs" "/"
format_partition "${DISK}4" "xfs" "/home"

echo -e "\n✅ GPT Partitioning and formatting complete!"

