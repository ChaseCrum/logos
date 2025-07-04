#!/bin/bash
set -e

echo "🔧 Building and Installing Glibc (2.41)"

sudo su - lfs << EOF
set -e

# Set up environment
export LFS=/mnt/lfs
export LFS_TGT=\$(uname -m)-lfs-linux-gnu
export PATH=\$LFS/tools/bin:\$PATH
unset CC
unset CFLAGS
unset CXXFLAGS

cd \$LFS/sources
tar -xf glibc-2.41.tar.* || { echo "[ERROR] Failed to extract Glibc"; exit 1; }
cd glibc-2.41

# LSB compatibility symlinks
case \$(uname -m) in
  i?86)
    ln -sfv ld-linux.so.2 \$LFS/lib/ld-lsb.so.3
    ;;
  x86_64)
    ln -sfv ../lib/ld-linux-x86-64.so.2 \$LFS/lib64
    ln -sfv ../lib/ld-linux-x86-64.so.2 \$LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac

# Apply FHS patch
patch -Np1 -i ../glibc-2.41-fhs-1.patch

# Create and enter build directory
mkdir -v build
cd build

# Configure Glibc
echo "rootsbindir=/usr/sbin" > configparms

../configure \\
  --prefix=/usr \\
  --host=\$LFS_TGT \\
  --build=\$(../scripts/config.guess) \\
  --enable-kernel=5.4 \\
  --with-headers=\$LFS/usr/include \\
  --disable-nscd \\
  libc_cv_slibdir=/usr/lib

# Build Glibc
make

# Install Glibc into \$LFS
make DESTDIR=\$LFS install

# Fix ldd path
sed '/RTLDLIST=/s@/usr@@g' -i \$LFS/usr/bin/ldd

# Sanity check
cd \$LFS
echo 'int main(){}' | \$LFS_TGT-gcc -xc -
readelf -l a.out | grep ld-linux || echo "⚠️ Toolchain test failed"
rm -v a.out

EOF

echo "✅ Glibc (2.41) build and install complete."
