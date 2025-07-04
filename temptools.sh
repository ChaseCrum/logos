#!/bin/bash
set -e

# Fix LFS variable if running with sudo
if [ -z "$LFS" ]; then
  if [ -n "$SUDO_USER" ]; then
    eval LFS=$(sudo -u "$SUDO_USER" env | grep '^LFS=' | cut -d= -f2-)
    export LFS
  fi
fi

if [ -z "$LFS" ]; then
  echo "❌ LFS variable is not set."
  exit 1
fi

# Run script as 'lfs' user if executed by root
if [ "$(id -u)" -eq 0 ] && [ "$USER" != "lfs" ]; then
  echo "✅ Running as root. Executing build steps as 'lfs' user..."
  sudo -u lfs LFS=$LFS bash "$0"
  exit $?
fi

cd $LFS/sources

# M4
tar -xf m4-*.tar.* && cd m4-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd .. && rm -rf m4-*/

# Ncurses
tar -xf ncurses-*.tar.* && cd ncurses-*/
mkdir build && pushd build
../configure AWK=gawk
make -C include
make -C progs tic
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess) \
  --mandir=/usr/share/man --with-manpage-format=normal --with-shared \
  --without-normal --with-cxx-shared --without-debug --without-ada \
  --disable-stripping AWK=gawk
make
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' -i $LFS/usr/include/curses.h
cd .. && rm -rf ncurses-*/

# Bash
tar -xf bash-*.tar.* && cd bash-*/
./configure --prefix=/usr --build=$(sh support/config.guess) \
  --host=$LFS_TGT --without-bash-malloc
make
make DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh
cd .. && rm -rf bash-*/

# Coreutils
tar -xf coreutils-*.tar.* && cd coreutils-*/
FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr --host=$LFS_TGT \
  --build=$(build-aux/config.guess) --enable-install-program=hostname \
  --enable-no-install-program=kill,uptime
make
make DESTDIR=$LFS install
mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8
cd .. && rm -rf coreutils-*/

# Diffutils
tar -xf diffutils-*.tar.* && cd diffutils-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd .. && rm -rf diffutils-*/

# File
tar -xf file-*.tar.* && cd file-*/
mkdir build && pushd build
../configure --disable-bzlib --disable-libseccomp --disable-xzlib --disable-zlib
make
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la
cd .. && rm -rf file-*/

# Findutils
tar -xf findutils-*.tar.* && cd findutils-*/
./configure --prefix=/usr --localstatedir=/var/lib/locate \
  --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd .. && rm -rf findutils-*/

# Gawk
tar -xf gawk-*.tar.* && cd gawk-*/
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd .. && rm -rf gawk-*/

# Grep
tar -xf grep-*.tar.* && cd grep-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd .. && rm -rf grep-*/

# Gzip
tar -xf gzip-*.tar.* && cd gzip-*/
./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install
cd .. && rm -rf gzip-*/

# Make
tar -xf make-*.tar.* && cd make-*/
./configure --prefix=/usr --without-guile --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd .. && rm -rf make-*/

# Patch
tar -xf patch-*.tar.* && cd patch-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd .. && rm -rf patch-*/

# Sed
tar -xf sed-*.tar.* && cd sed-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd .. && rm -rf sed-*/

# Tar
tar -xf tar-*.tar.* && cd tar-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd .. && rm -rf tar-*/

# Xz
tar -xf xz-*.tar.* && cd xz-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess) \
  --disable-static --docdir=/usr/share/doc/xz-5.6.4
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la
cd .. && rm -rf xz-*/

# Binutils (pass 2)
tar -xf binutils-*.tar.* && cd binutils-*/
sed '6031s/$add_dir//' -i ltmain.sh
mkdir build && cd build
../configure --prefix=/usr --build=$(../config.guess) --host=$LFS_TGT \
  --disable-nls --enable-shared --enable-gprofng=no --disable-werror \
  --enable-64-bit-bfd --enable-new-dtags --enable-default-hash-style=gnu
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
cd ../.. && rm -rf binutils-*/

# GCC (pass 2)
tar -xf gcc-*.tar.* && cd gcc-*/
tar -xf ../mpfr-*.tar.* && mv -v mpfr-* mpfr
tar -xf ../gmp-*.tar.* && mv -v gmp-* gmp
tar -xf ../mpc-*.tar.* && mv -v mpc-* mpc

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac

sed '/thread_header =/s/@.*@/gthr-posix.h/' \
  -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir build && cd build
../configure --build=$(../config.guess) --host=$LFS_TGT --target=$LFS_TGT \
  LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc \
  --prefix=/usr --with-build-sysroot=$LFS --enable-default-pie \
  --enable-default-ssp --disable-nls --disable-multilib \
  --disable-libatomic --disable-libgomp --disable-libquadmath \
  --disable-libsanitizer --disable-libssp --disable-libvtv \
  --enable-languages=c,c++
make
make DESTDIR=$LFS install
ln -sv gcc $LFS/usr/bin/cc
cd ../.. && rm -rf gcc-*/

echo "✅ Temporary tools built successfully!"
