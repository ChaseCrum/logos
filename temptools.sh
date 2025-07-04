#!/bin/bash
set -e

# Ensure LFS variable is set
if [ -z "$LFS" ]; then
  echo "❌ LFS variable is not set."
  exit 1
fi

# If run as root via sudo, run commands as the lfs user
run_as_lfs() {
  if [ "$(whoami)" = "root" ]; then
    su - lfs -c "$1"
  else
    bash -c "$1"
  fi
}

# Wildcard unpack helper
unpack() {
  tarball=$(ls $LFS/sources/$1 2>/dev/null | head -n 1)
  [ -z "$tarball" ] && echo "❌ Archive for $1 not found" && exit 1
  tar -xf $LFS/sources/$tarball -C $LFS/sources
  cd $LFS/sources/${tarball%.tar.*}
}

echo "🔧 Starting temp tools build..."

# 6.2 M4
run_as_lfs '
cd $LFS/sources
unpack "m4-*"
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.3 Ncurses
run_as_lfs '
cd $LFS/sources
unpack "ncurses-*"
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
sed -e "s/^#if.*XOPEN.*$/#if 1/" -i $LFS/usr/include/curses.h
'

# 6.4 Bash
run_as_lfs '
cd $LFS/sources
unpack "bash-*"
./configure --prefix=/usr --build=$(sh support/config.guess) \
  --host=$LFS_TGT --without-bash-malloc
make
make DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh
'

# 6.5 Coreutils
run_as_lfs '
cd $LFS/sources
unpack "coreutils-*"
./configure --prefix=/usr --host=$LFS_TGT \
  --build=$(build-aux/config.guess) \
  --enable-install-program=hostname --enable-no-install-program=kill,uptime
make
make DESTDIR=$LFS install
mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i "s/\"1\"/\"8\"/" $LFS/usr/share/man/man8/chroot.8
'

# 6.6 Diffutils
run_as_lfs '
cd $LFS/sources
unpack "diffutils-*"
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.7 File
run_as_lfs '
cd $LFS/sources
unpack "file-*"
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
run_as_lfs '
cd $LFS/sources
unpack "findutils-*"
./configure --prefix=/usr --localstatedir=/var/lib/locate \
  --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.9 Gawk
run_as_lfs '
cd $LFS/sources
unpack "gawk-*"
sed -i "s/extras//" Makefile.in
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.10 Grep
run_as_lfs '
cd $LFS/sources
unpack "grep-*"
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.11 Gzip
run_as_lfs '
cd $LFS/sources
unpack "gzip-*"
./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install
'

# 6.12 Make
run_as_lfs '
cd $LFS/sources
unpack "make-*"
./configure --prefix=/usr --without-guile \
  --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.13 Patch
run_as_lfs '
cd $LFS/sources
unpack "patch-*"
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.14 Sed
run_as_lfs '
cd $LFS/sources
unpack "sed-*"
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.15 Tar
run_as_lfs '
cd $LFS/sources
unpack "tar-*"
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
'

# 6.16 Xz
run_as_lfs '
cd $LFS/sources
unpack "xz-*"
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess) \
  --disable-static --docdir=/usr/share/doc/xz
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la
'

echo "✅ temp tools build complete."
