#!/bin/bash

set -euo pipefail

### Function Definitions ###
echo_step() {
    echo -e "\n=== $1 ==="
}

confirm() {
    read -rp "$1 [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]] || {
        echo "Aborted."; exit 1;
    }
}

get_ram_mb() {
    grep MemTotal /proc/meminfo | awk '{print int($2 / 1024)}'
}

get_disk_size_mb() {
    local disk=$1
    lsblk -bno SIZE "$disk" | awk '{print int($1 / 1024 / 1024)}'
}

calculate_sizes() {
    local total_mb=$1
    local ram_mb=$2

    local boot_mb=500
    local swap_mb=$((ram_mb * 2))
    local remaining_mb=$((total_mb - boot_mb - swap_mb))

    src_mb=$((remaining_mb * 15 / 100))
    opt_mb=$((remaining_mb * 5 / 100))
    tmp_mb=$((remaining_mb * 5 / 100))
    usr_mb=$((remaining_mb * 20 / 100))
    root_mb=$((remaining_mb * 20 / 100))
    home_mb=$((remaining_mb - src_mb - opt_mb - tmp_mb - usr_mb - root_mb))

    total_calc=$((boot_mb + swap_mb + src_mb + opt_mb + tmp_mb + usr_mb + root_mb + home_mb))

    echo "\nPlanned Partition Layout (in MB):"
    echo "1. /boot     : $boot_mb"
    echo "2. swap      : $swap_mb"
    echo "3. /usr/src  : $src_mb"
    echo "4. /opt      : $opt_mb"
    echo "5. /tmp      : $tmp_mb"
    echo "6. /usr      : $usr_mb"
    echo "7. /         : $root_mb"
    echo "8. /home     : $home_mb"
    echo "Total Used  : $total_calc / $total_mb MB"
}

format_partitions() {
    local disk=$1

    mkfs.xfs -f ${disk}1 -L boot
    mkswap ${disk}2
    mkfs.xfs -f ${disk}3 -L usr_src
    mkfs.xfs -f ${disk}4 -L opt
    mkfs.xfs -f ${disk}5 -L tmp
    mkfs.xfs -f ${disk}6 -L usr
    mkfs.xfs -f ${disk}7 -L root
    mkfs.xfs -f ${disk}8 -L home
}

### Script Starts Here ###
echo_step "Detecting Disks"
lsblk -d -o NAME,SIZE,TYPE | grep disk

echo_step "Choose Disk"
read -rp "Enter the full path of the disk to format (e.g., /dev/sdX): " DISK

[[ -b "$DISK" ]] || { echo "Invalid disk: $DISK"; exit 1; }

read -rp "Run in dry-run mode (no partitioning or formatting will occur)? [y/N]: " dryrun_response
DRY_RUN=false
[[ "$dryrun_response" =~ ^[Yy]$ ]] && DRY_RUN=true

confirm "WARNING: This will erase all data on $DISK. Continue?"

echo_step "Getting RAM Size"
read -rp "Enter RAM in MB (leave blank to auto-detect): " input_ram
if [[ -n "$input_ram" ]]; then
    if [[ "$input_ram" =~ ^[0-9]+$ ]]; then
        RAM_MB=$input_ram
    else
        echo "Invalid RAM value. Must be a number in MB."; exit 1;
    fi
else
    RAM_MB=$(get_ram_mb)
fi

echo "Using RAM_MB = $RAM_MB → Swap size will be $((RAM_MB * 2)) MB"

DISK_MB=$(get_disk_size_mb "$DISK")
calculate_sizes $DISK_MB $RAM_MB
confirm "Do you approve this layout and want to proceed with partitioning and formatting?"

if [ "$DRY_RUN" = true ]; then
    echo_step "Dry-run complete. No changes made."
    exit 0
fi

echo_step "Creating Partition Table (MBR)"
parted -s "$DISK" mklabel msdos

BOOT_MB=500
SWAP_MB=$((RAM_MB * 2))

# Calculate start and end points
declare -i start=1
end=$((start + BOOT_MB - 1))
parted -s "$DISK" mkpart primary xfs ${start}MiB ${end}MiB
parted -s "$DISK" set 1 boot on

start=$((end + 1)); end=$((start + SWAP_MB - 1))
parted -s "$DISK" mkpart primary linux-swap ${start}MiB ${end}MiB

start=$((end + 1)); end=$((start + src_mb - 1))
parted -s "$DISK" mkpart primary xfs ${start}MiB ${end}MiB

start=$((end + 1)); end=$((start + opt_mb - 1))
parted -s "$DISK" mkpart primary xfs ${start}MiB ${end}MiB

start=$((end + 1)); end=$((start + tmp_mb - 1))
parted -s "$DISK" mkpart primary xfs ${start}MiB ${end}MiB

start=$((end + 1)); end=$((start + usr_mb - 1))
parted -s "$DISK" mkpart primary xfs ${start}MiB ${end}MiB

start=$((end + 1)); end=$((start + root_mb - 1))
parted -s "$DISK" mkpart primary xfs ${start}MiB ${end}MiB

start=$((end + 1))
parted -s "$DISK" mkpart primary xfs ${start}MiB 100%

sleep 2
echo_step "Formatting Partitions"
PART_PREFIX="${DISK}"
[[ "$DISK" =~ nvme ]] && PART_PREFIX="${DISK}p"
format_partitions "$PART_PREFIX"

echo_step "Partitioning and formatting complete."
echo "You may now mount the partitions and continue system setup."
