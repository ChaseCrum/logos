#!/bin/bash
set -e

# === enter_chroot.sh ===
# Automates the steps in Chapter 7 of LFS 12.3

# Ensure LFS is set
if [ -z "$LFS" ]; then
  export LFS=/mnt/lfs
  echo "⚠️  LFS not set. Defaulting to /mnt/lfs"
fi

# Create mount point directories if they don't exist
mkdir -pv $LFS/{dev,proc,sys,run}

# 🧼 Set ownership of critical directories to root
echo "🔧 Ensuring root ownership of system directories..."
chown --from lfs -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
esac

# 🗂 Mount virtual filesystems
echo "🔍 Mounting and verifying virtual filesystems..."

mount --bind /dev $LFS/dev || { echo "❌ Failed to bind /dev"; exit 1; }
mount --bind /dev/pts $LFS/dev/pts || { echo "❌ Failed to bind /dev/pts"; exit 1; }
mount -t proc proc $LFS/proc || { echo "❌ Failed to mount /proc"; exit 1; }
mount -t sysfs sysfs $LFS/sys || { echo "❌ Failed to mount /sys"; exit 1; }
mount -t tmpfs tmpfs $LFS/run || { echo "❌ Failed to mount /run"; exit 1; }

# Handle /dev/shm
if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi

echo "✅ All virtual filesystems mounted."

# 🚪 Enter the chroot environment
echo "🚪 Entering chroot..."
chroot "$LFS" /usr/bin/env -i \
  HOME=/root \
  TERM="$TERM" \
  PS1='(lfs chroot) \u:\w\$ ' \
  PATH=/usr/bin:/usr/sbin \
  MAKEFLAGS="-j$(nproc)" \
  TESTSUITEFLAGS="-j$(nproc)" \
  /bin/bash --login
