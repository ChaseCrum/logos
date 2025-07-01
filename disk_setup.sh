#!/bin/bash

set -e

clear
echo -e "\n=== Detecting Disks ===\n"
lsblk
echo

read -p "Enter target disk (e.g., /dev/sda): " DISK

export LFS=/mnt/lfs

echo -e "\nCreating partitions..."
parted --script "$DISK" \
  mklabel msdos \
  mkpart primary linux-swap 1MiB 2049MiB \
  mkpart primary xfs 2049MiB 61441MiB \
  mkpart primary xfs 61441MiB 100%

sleep 1
clear

echo -e "\n=== Partition Overview ==="
lsblk "$DISK"
echo

SWAP_PART=${DISK}1
ROOT_PART=${DISK}2
HOME_PART=${DISK}3

echo -e "\nCreating filesystems..."
mkswap -v "$SWAP_PART"
mkfs.xfs -f "$ROOT_PART"
mkfs.xfs -f "$HOME_PART"

echo -e "\nActivating swap..."
swapon "$SWAP_PART"

echo -e "\nMounting root partition..."
mkdir -pv $LFS
mount -v -t xfs "$ROOT_PART" $LFS

# Ensure we're working inside the mounted LFS
echo "✅ $ROOT_PART successfully mounted on $LFS"

# Create essential structure inside $LFS
mkdir -pv $LFS/{sources,tools}
chown -v lfs:lfs $LFS/sources
chown -v lfs:lfs $LFS/tools

mkdir -pv $LFS/home
mount -v -t xfs "$HOME_PART" $LFS/home

echo "Setting permissions..."
chown root:root $LFS
chmod 755 $LFS

echo -e "\n✅ Disk setup complete. Root mounted at $LFS."
