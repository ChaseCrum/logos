#!/bin/bash
set -e

# Safeguard: set LFS if not defined
if [ -z "$LFS" ]; then
  export LFS=/mnt/lfs
  echo "⚠️  LFS not set, defaulting to $LFS"
fi

# Ensure script is executed via sudo
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Please run this script with sudo."
  exit 1
fi

# Re-execute as 'lfs' user when running as root via sudo
if [ "$(whoami)" != "lfs" ]; then
  sudo -u lfs LFS=$LFS bash "$0"
  exit $?
fi

# Environment setup
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export PATH=$LFS/tools/bin:$PATH
cd $LFS/sources

# Function to unpack, build, and clean up package
build_package() {
  local package=$1
  local commands=$2

  rm -rf ${package}-*/
  tar xf ${package}-*.tar.*
  cd ${package}-*/

  eval "$commands"

  cd ..
  rm -rf ${package}-*/
}

# 6.2 M4
build_package m4 '
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.3 Ncurses
build_package ncurses '
mkdir build && pushd build
../configure AWK=gawk
make -C include
make -C progs tic
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess) \
  --mandir=/usr/share/man --with-manpage-format=normal \
  --with-shared --without-normal --with-cxx-shared \
  --without-debug --without-ada --disable-stripping AWK=gawk
make
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -i 's/^#if.*XOPEN.*$/#if 1/' $LFS/usr/include/curses.h
'

# 6.4 Bash
build_package bash '
./configure --prefix=/usr --build=$(sh support/config.guess) --host=$LFS_TGT --without-bash-malloc
make
make DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh
'

# 6.5 Coreutils
build_package coreutils '
FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr --host=$LFS_TGT \
  --build=$(build-aux/config.guess) --enable-install-program=hostname \
  --enable-no-install-program=kill,uptime
make
make DESTDIR=$LFS install
mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i "s/\"1\"/\"8\"/" $LFS/usr/share/man/man8/chroot.8
'

# 6.6 Diffutils
build_package diffutils '
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.7 File
build_package file '
mkdir build && pushd build
../configure --disable-bzlib --disable-libseccomp --disable-xzlib --disable-zlib
make
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la
'

# 6.8 Findutils
build_package findutils '
./configure --prefix=/usr --localstatedir=/var/lib/locate --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.9 Gawk
build_package gawk '
sed -i "s/extras//" Makefile.in
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.10 Grep
build_package grep '
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.11 Gzip
build_package gzip '
./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install
'

# 6.12 Make
build_package make '
./configure --prefix=/usr --without-guile --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.13 Patch
build_package patch '
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.14 Sed
build_package sed '
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.15 Tar
build_package tar '
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.16 Xz
build_package xz '
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess) --disable-static --docdir=/usr/share/doc/xz-5.6.4
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la
'

# 6.17 Binutils Pass 2
build_package binutils '
sed "6031s/\$add_dir//" -i ltmain.sh
mkdir build && cd build
../configure --prefix=/usr --build=$(../config.guess) --host=$LFS_TGT \
  --disable-nls --enable-shared --enable-gprofng=no --disable-werror \
  --enable-64-bit-bfd --enable-new-dtags --enable-default-hash-style=gnu
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
'

# 6.18 GCC Pass 2
build_package gcc '
tar -xf ../mpfr-*.tar.* && mv -v mpfr-* mpfr
tar -xf ../gmp-*.tar.* && mv -v gmp-* gmp
tar -xf ../mpc-*.tar.* && mv -v mpc-* mpc
sed "/m64=/s/lib64/lib/" -i.orig gcc/config/i386/t-linux64
sed "/thread_header =/s/@.*@/gthr-posix.h/" -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
mkdir build && cd build
../configure --build=$(../config.guess) --host=$LFS_TGT --target=$LFS_TGT \
LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc --prefix=/usr --with-build-sysroot=$LFS \
--enable-default-pie --enable-default-ssp --disable-nls --disable-multilib \
--disable-libatomic --disable-libgomp --disable-libquadmath --disable-libsanitizer \
--disable-libssp --disable-libvtv --enable-languages=c,c++
make
make DESTDIR=$LFS install
ln -sv gcc $LFS/usr/bin/cc
'

echo "🎉 Chapter 6 build complete!"
