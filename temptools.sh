#!/bin/bash
set -e

# Safeguard: set LFS if not defined
if [ -z "$LFS" ]; then
  echo "⚠️  LFS not set, defaulting to /mnt/lfs"
  export LFS=/mnt/lfs
fi

# Must be run via sudo as root so we can switch to lfs
if [ "$(whoami)" != "lfs" ]; then
  exec sudo -H -u lfs env LFS="$LFS" bash "$0"
fi


cd $LFS/sources
export LFS_TGT=$(uname -m)-lfs-linux-gnu

# 6.2 M4-1.4.19
tar -xf m4-*.tar.* && cd m4-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..

# 6.3 Ncurses-6.5
tar -xf ncurses-*.tar.* && cd ncurses-*/
mkdir build && pushd build
../configure AWK=gawk
make -C include
make -C progs tic
popd
./configure --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(./config.guess) \
  --mandir=/usr/share/man \
  --with-manpage-format=normal \
  --with-shared \
  --without-normal \
  --with-cxx-shared \
  --without-debug \
  --without-ada \
  --disable-stripping \
  AWK=gawk
make
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' -i $LFS/usr/include/curses.h
cd ..

# 6.4 Bash-5.2.37
tar -xf bash-*.tar.* && cd bash-*/
./configure --prefix=/usr \
  --build=$(sh support/config.guess) \
  --host=$LFS_TGT \
  --without-bash-malloc
make
make DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh
cd ..

# 6.5 Coreutils-9.6
tar -xf coreutils-*.tar.* && cd coreutils-*/
FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess) \
  --enable-install-program=hostname \
  --enable-no-install-program=kill,uptime
make
make DESTDIR=$LFS install
mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8
cd ..

# 6.6 Diffutils-3.11
tar -xf diffutils-*.tar.* && cd diffutils-*/
./configure --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..

# 6.7 File-5.46
tar -xf file-*.tar.* && cd file-*/
mkdir build && pushd build
../configure --disable-bzlib \
  --disable-libseccomp \
  --disable-xzlib \
  --disable-zlib
make
popd
./configure --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la
cd ..

# 6.8 Findutils-4.10.0
tar -xf findutils-*.tar.* && cd findutils-*/
./configure --prefix=/usr \
  --localstatedir=/var/lib/locate \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..

# 6.9 Gawk-5.3.1
tar -xf gawk-*.tar.* && cd gawk-*/
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..

# 6.10 Grep-3.11
tar -xf grep-*.tar.* && cd grep-*/
./configure --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..

# 6.11 Gzip-1.13
tar -xf gzip-*.tar.* && cd gzip-*/
./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install
cd ..

# 6.12 Make-4.4.1
tar -xf make-*.tar.* && cd make-*/
./configure --prefix=/usr \
  --without-guile \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..

# 6.13 Patch-2.7.6
tar -xf patch-*.tar.* && cd patch-*/
./configure --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd .

# 6.14 Sed-4.9
tar -xf sed-*.tar.* && cd sed-*/
./configure --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..

# 6.15 Tar-1.35
tar -xf tar-*.tar.* && cd tar-*/
./configure --prefix=/usr \
  --host=$LFS_TGT \
  --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..

# 6.17 Binutils-2.44 Pass 2
tar -xf binutils-*.tar.* && cd binutils-*/
sed '6031s/\$add_dir//' -i ltmain.sh
mkdir -v build && cd build

../configure --prefix=/usr \
  --build=$(../config.guess) \
  --host=$LFS_TGT \
  --disable-nls \
  --enable-shared \
  --enable-gprofng=no \
  --disable-werror \
  --enable-64-bit-bfd \
  --enable-new-dtags \
  --enable-default-hash-style=gnu

make
env DESTDIR=$LFS make install
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
cd ../..


# 6.18 GCC-14.2.0 Pass 2
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
mkdir -v build && cd build
../configure --build=$(../config.guess) \
  --host=$LFS_TGT \
  --target=$LFS_TGT \
  LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc \
  --prefix=/usr \
  --with-build-sysroot=$LFS \
  --enable-default-pie \
  --enable-default-ssp \
  --disable-nls \
  --disable-multilib \
  --disable-libatomic \
  --disable-libgomp \
  --disable-libquadmath \
  --disable-libsanitizer \
  --disable-libssp \
  --disable-libvtv \
  --enable-languages=c,c++
make
make DESTDIR=$LFS install
ln -sv gcc $LFS/usr/bin/cc
cd ..

echo "🎉 Chapter 6 temporary tools build complete!"