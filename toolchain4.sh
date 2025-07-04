#!/bin/bash
set -e

echo "🔧 Installing Linux API Headers (kernel 6.13.4)"

sudo su - lfs << EOF
set -e

export LFS=/mnt/lfs
export PATH=\$LFS/tools/bin:\$PATH
unset CC
unset CFLAGS
unset CXXFLAGS

cd \$LFS/sources
tar -xf linux-6.13.4.tar.* || { echo "[ERROR] Failed to extract Linux kernel"; exit 1; }
cd linux-6.13.4

# Clean the kernel source tree
make mrproper

# Generate sanitized headers
make headers

# Remove non-header files
find usr/include -type f ! -name '*.h' -delete

# Copy headers to \$LFS
cp -rv usr/include \$LFS/usr

EOF

echo "✅ Linux API Headers installation complete."
