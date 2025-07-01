#!/bin/bash
set -e

export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export PATH=$LFS/tools/bin:$PATH

umask 022
mkdir -pv $LFS/tools
ln -sv $LFS/tools /

# -------- Helper Function --------
clean_source() {
  echo "🧹 Cleaning up $1..."
  sudo su - lfs -c "rm -rf ~lfs/sources/$1 ~lfs/sources/$1-build"
}

# -------- Binutils Pass 1 --------
echo "🔧 Building Binutils (Pass 1)"
BINUTILS_SRC=$(basename ~lfs/sources/binutils-*.tar.* | head -n1)
BINUTILS_DIR=${BINUTILS_SRC%.tar.*}

sudo su - lfs -c "cd ~/sources && tar -xf $BINUTILS_SRC"
sudo su - lfs -c "mkdir -v ~/sources/$BINUTILS_DIR/build"
sudo su - lfs -c "cd ~/sources/$BINUTILS_DIR/build && \
  ../configure --prefix=$LFS/tools \
               --with-sysroot=$LFS \
               --target=$LFS_TGT \
               --disable-nls \
               --enable-gprofng=no \
               --disable-werror \
               --enable-new-dtags \
               --enable-default-hash-style=gnu && \
  make -j$(nproc) && \
  make install"
clean_source $BINUTILS_DIR

# -------- GCC Pass 1 --------
echo "🔧 Building GCC (Pass 1)"
GCC_SRC=$(basename ~lfs/sources/gcc-*.tar.* | head -n1)
GCC_DIR=${GCC_SRC%.tar.*}

MPFR_SRC=$(basename ~lfs/sources/mpfr-*.tar.* | head -n1)
GMP_SRC=$(basename ~lfs/sources/gmp-*.tar.* | head -n1)
MPC_SRC=$(basename ~lfs/sources/mpc-*.tar.* | head -n1)

MPFR_DIR=${MPFR_SRC%.tar.*}
GMP_DIR=${GMP_SRC%.tar.*}
MPC_DIR=${MPC_SRC%.tar.*}

sudo su - lfs -c "cd ~/sources && tar -xf $GCC_SRC"
sudo su - lfs -c "cd ~/sources && tar -xf $MPFR_SRC && mv -v $MPFR_DIR $GCC_DIR/mpfr"
sudo su - lfs -c "cd ~/sources && tar -xf $GMP_SRC && mv -v $GMP_DIR $GCC_DIR/gmp"
sudo su - lfs -c "cd ~/sources && tar -xf $MPC_SRC && mv -v $MPC_DIR $GCC_DIR/mpc"

# Multilib fix for x86_64
sudo su - lfs -c "cd ~/sources/$GCC_DIR && \
  case \$(uname -m) in \
    x86_64) sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 ;; \
  esac"

# Configure and build
sudo su - lfs -c "mkdir -v ~/sources/$GCC_DIR/build"
sudo su - lfs -c "cd ~/sources/$GCC_DIR/build && \
  ../configure --target=$LFS_TGT \
               --prefix=$LFS/tools \
               --with-glibc-version=2.39 \
               --with-sysroot=$LFS \
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
               --enable-languages=c && \
  make -j$(nproc) && \
  make install"
clean_source $GCC_DIR

echo -e "\n✅ Toolchain base (Binutils + GCC Pass 1) built successfully!"
