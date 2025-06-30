#!/bin/bash
set -e

# Environment setup
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export PATH="$LFS/tools/bin:$PATH"

# Ensure sources dir exists
mkdir -pv $LFS/sources
chmod a+wt $LFS/sources

# Function to run commands as the lfs user inside $LFS/sources
run_as_lfs() {
    sudo -u lfs bash -c "cd $LFS/sources && $*"
}

cd $LFS/sources

# -------------------------------
# Binutils Pass 1
# -------------------------------
run_as_lfs "tar -xf binutils-*.tar.xz"
mkdir -v $LFS/sources/binutils-build
cd $LFS/sources/binutils-build

../binutils-*/configure --prefix=$LFS/tools \
    --with-sysroot=$LFS \
    --target=$LFS_TGT   \
    --disable-nls       \
    --enable-gprofng=no \
    --disable-werror

make -j$(nproc)
make install

cd $LFS/sources
rm -rf binutils-*/ binutils-build/

# -------------------------------
# GCC Pass 1 + Dependencies
# -------------------------------
run_as_lfs "tar -xf gcc-*.tar.xz"
cd $LFS/sources/gcc-*/

# Fix lib64 path for x86_64
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac

# MPFR
run_as_lfs "tar -xf mpfr-*.tar.xz"
mv -v mpfr-* mpfr

# GMP
run_as_lfs "tar -xf gmp-*.tar.xz"
mv -v gmp-* gmp

# MPC
run_as_lfs "tar -xf mpc-*.tar.gz"
mv -v mpc-* mpc

# GCC build
mkdir -v $LFS/sources/gcc-build
cd $LFS/sources/gcc-build

../gcc-*/configure --target=$LFS_TGT \
    --prefix=$LFS/tools              \
    --with-glibc-version=2.39        \
    --with-sysroot=$LFS              \
    --with-newlib                    \
    --without-headers                \
    --enable-default-pie=no          \
    --enable-default-ssp=no          \
    --disable-nls                    \
    --disable-shared                 \
    --disable-multilib               \
    --disable-threads                \
    --disable-libatomic              \
    --disable-libgomp                \
    --disable-libquadmath            \
    --disable-libssp                 \
    --disable-libvtv                 \
    --enable-languages=c,c++

make -j$(nproc)
make install

cd $LFS/sources
rm -rf gcc-*/ gcc-build/ mpfr/ gmp/ mpc/

echo "✅ Toolchain build completed successfully in \$LFS/sources."
