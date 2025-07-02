#!/bin/bash
set -e

echo "🔧 Building GCC (Pass 1)"

sudo su - lfs << "EOF"
set -e

export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu

cd \$LFS/sources
tar -xf gcc-*.tar.* || { echo "[ERROR] Failed to extract GCC"; exit 1; }
cd gcc-*/

# Extract required dependencies
tar -xf ../mpfr-*.tar.* && mv -v mpfr-* mpfr
tar -xf ../gmp-*.tar.* && mv -v gmp-* gmp
tar -xf ../mpc-*.tar.* && mv -v mpc-* mpc

# Fix 64-bit lib path
case \$(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac

# Create build directory
mkdir -v build
cd build

# Configure the build
../configure \
    --target=\$LFS_TGT \
    --prefix=\$LFS/tools \
    --with-glibc-version=2.41 \
    --with-sysroot=\$LFS \
    --with-newlib \
    --without-headers \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-nls \
    --disable-shared \
    --disable-multilib \
    --disable-threads \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libvtv \
    --disable-libstdcxx \
    --enable-languages=c,c++

make
make install

# Create the limits.h header
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  \`dirname \$(${LFS_TGT}-gcc -print-libgcc-file-name)\`/include/limits.h

EOF

echo "✅ GCC (Pass 1) build complete."
