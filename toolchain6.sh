#!/bin/bash
set -e

echo "🔧 Building and Installing Libstdc++ (from GCC 14.2.0)"

sudo su - lfs << EOF
set -e

# Set up environment
export LFS=/mnt/lfs
export LFS_TGT=\$(uname -m)-lfs-linux-gnu
export PATH=\$LFS/tools/bin:\$PATH
unset CC
unset CFLAGS
unset CXXFLAGS

cd \$LFS/sources/gcc-14.2.0

# Create and enter separate build directory
mkdir -v libstdcpp-build
cd libstdcpp-build

# Configure Libstdc++
../libstdc++-v3/configure \\
  --host=\$LFS_TGT \\
  --build=\$(../config.guess) \\
  --prefix=/usr \\
  --disable-multilib \\
  --disable-nls \\
  --disable-libstdcxx-pch \\
  --with-gxx-include-dir=/tools/\$LFS_TGT/include/c++/14.2.0

# Build
make

# Install to \$LFS
make DESTDIR=\$LFS install

# Remove problematic libtool archive files
rm -v \$LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la

EOF

echo "✅ Libstdc++ build and installation complete."
