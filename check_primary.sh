#!/bin/bash

# Identify bootable partition using fdisk
primary_disk=$(sudo fdisk -l | awk '$1 ~ /^\/dev\/sd/ && $2 == "*" {print $1}' | head -n 1)

# Extract the disk name (e.g., from /dev/sda1 -> /dev/sda)
if [[ -n "$primary_disk" ]]; then
    primary_disk=$(lsblk -ndo PKNAME "$primary_disk")
fi

# Get disk size
disk_size=$(lsblk -ndo SIZE "/dev/$primary_disk")

# Print results
echo "Primary bootable disk: $primary_disk"
echo "Disk size: $disk_size"


