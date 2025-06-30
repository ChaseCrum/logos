#!/bin/bash
set -e

export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export PATH="$LFS/tools/bin:$PATH"

cd $LFS/sources

# -------------------------------
# Binutils
# -------------------------------
sudo -u lfs tar -xf binutils-*.tar.xz
mkdir -v binutils-build
cd binutils-build
../binutils-*/configure --prefix=$LFS/tools \
    --with-sysroot=$LFS \
    --target=$LFS_TGT   \
    --disable-nls       \
    --enable-gprofng=no \
    --disable-werror
make -j$(nproc)
make install
cd ..
rm -rf binutils-*/

# -------------------------------
# GCC
# -------------------------------
sudo -u lfs tar -xf gcc-*.tar.xz
cd gcc-*/

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac

# -------------------------------
# Dependencies for GCC
# -------------------------------
sudo -u lfs tar -xf mpfr-*.tar.xz
sudo mv -v mpfr-* mpfr
sudo -u lfs tar -xf gmp-*.tar.xz
sudo mv -v gmp-* gmp
sudo -u lfs tar -xf mpc-*.tar.gz
sudo mv -v mpc-* mpc

cd ..
mkdir -v gcc-build
cd gcc-build

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
cd ..
rm -rf gcc-*/

# -------------------------------
# Cleanup for dependencies
# -------------------------------
rm -rf mpfr-*/
rm -rf gmp-*/
rm -rf mpc-*/

echo "✅ Toolchain build complete."
