#!/bin/bash
set -e

echo -e "\n=== Linux From Scratch Disk Setup ==="

# Prompt user for disk to use
echo -e "\nAvailable disks:\n"
lsblk -dpno NAME,SIZE | grep -v loop
read -rp $'\nEnter the full path of the disk to use (e.g. /dev/sda): ' DISK

if [[ ! -b "$DISK" ]]; then
    echo "❌ ERROR: Invalid disk: $DISK"
    exit 1
fi

echo -e "\nPartitioning $DISK..."

# Create partition table and partitions
parted -s "$DISK" mklabel gpt \
  mkpart primary 1MiB 3MiB \
  set 1 bios_grub on \
  mkpart primary linux-swap 3MiB 8195MiB \
  mkpart primary xfs 8195MiB 80% \
  mkpart primary xfs 80% 100%

# Partition variables
get_partition_name() {
    local disk="$1"
    local num="$2"
    # Use 'p' for nvme devices (e.g., /dev/nvme0n1p1)
    if [[ "$disk" =~ nvme ]]; then
        echo "${disk}p${num}"
    else
        echo "${disk}${num}"
    fi
}

SWAP_PART=$(get_partition_name "$DISK" 2)
ROOT_PART=$(get_partition_name "$DISK" 3)
HOME_PART=$(get_partition_name "$DISK" 4)

echo -e "\nFormatting partitions..."
mkfs.xfs -f "$ROOT_PART"
mkfs.xfs -f "$HOME_PART"
mkswap "$SWAP_PART"

echo -e "\nMounting partitions..."
export LFS=/mnt/lfs
umask 022
mkdir -pv $LFS

if ! mount -v -t xfs "$ROOT_PART" "$LFS"; then
    echo "❌ ERROR: Failed to mount $ROOT_PART to $LFS"
    dmesg | tail -n10
    exit 1
fi

mkdir -pv $LFS/sources $LFS/tools $LFS/home
chown -v lfs:lfs $LFS/sources $LFS/tools

if ! mount -v -t xfs "$HOME_PART" "$LFS/home"; then
    echo "❌ ERROR: Failed to mount $HOME_PART to $LFS/home"
    dmesg | tail -n10
    exit 1
fi

swapon "$SWAP_PART"

echo -e "\n✅ Disk setup complete!"
lsblk -f | grep "$(basename "$DISK")"
mount | grep -E 'lfs|vda|'"$(basename "$DISK")"
