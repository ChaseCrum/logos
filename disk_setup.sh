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
echo "Using RAM_MB = $RAM_MB → Swap size will be $SWAP_MB MB"

# Get total disk size in MB
total_mb=$(lsblk -b -dn -o SIZE "$DISK")
total_mb=$((total_mb / 1024 / 1024))

# Reserve BIOS boot partition
BIOS_BOOT_MB=2
BOOT_MB=500

# Remaining after BIOS + boot + swap
REMAINING_MB=$((total_mb - BIOS_BOOT_MB - BOOT_MB - SWAP_MB))

# Allocate based on percentage
SRC_MB=$((REMAINING_MB * 15 / 100))
OPT_MB=$((REMAINING_MB * 5 / 100))
TMP_MB=$((REMAINING_MB * 5 / 100))
USR_MB=$((REMAINING_MB * 20 / 100))
ROOT_MB=$((REMAINING_MB * 20 / 100))
used_dynamic=$((SRC_MB + OPT_MB + TMP_MB + USR_MB + ROOT_MB))
HOME_MB=$((REMAINING_MB - used_dynamic))

echo -e "\nPlanned Partition Layout (in MB):"
echo "1. BIOS Boot : $BIOS_BOOT_MB"
echo "2. /boot     : $BOOT_MB"
echo "3. swap      : $SWAP_MB"
echo "4. /usr/src  : $SRC_MB"
echo "5. /opt      : $OPT_MB"
echo "6. /tmp      : $TMP_MB"
echo "7. /usr      : $USR_MB"
echo "8. /         : $ROOT_MB"
echo "9. /home     : $HOME_MB"
echo "Total Used  : $((BIOS_BOOT_MB + BOOT_MB + SWAP_MB + REMAINING_MB)) / $total_mb MB"

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

# Wipe existing partitioning
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
    elif [[ "$LABEL" == "/boot" ]]; then
        parted -s "$DISK" set $part_num boot on
    fi

    echo "Created $LABEL from $START_MB MB to $END_MB MB"
    START_MB=$((END_MB + 1))
    part_num=$((part_num + 1))
}

create_partition $BIOS_BOOT_MB "BIOS" "none"
create_partition $BOOT_MB "/boot" "xfs"
create_partition $SWAP_MB "swap" "swap"
create_partition $SRC_MB "/usr/src" "xfs"
create_partition $OPT_MB "/opt" "xfs"
create_partition $TMP_MB "/tmp" "xfs"
create_partition $USR_MB "/usr" "xfs"
create_partition $ROOT_MB "/" "xfs"
create_partition $HOME_MB "/home" "xfs"

echo -e "\n=== Formatting Partitions ==="
partprobe "$DISK"
sleep 2

# Build full device names
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

format_partition "${DISK}2" "xfs" "/boot"
format_partition "${DISK}3" "swap" "swap"
format_partition "${DISK}4" "xfs" "/usr/src"
format_partition "${DISK}5" "xfs" "/opt"
format_partition "${DISK}6" "xfs" "/tmp"
format_partition "${DISK}7" "xfs" "/usr"
format_partition "${DISK}8" "xfs" "/"
format_partition "${DISK}9" "xfs" "/home"

echo -e "\n✅ GPT Partitioning and formatting complete!"

