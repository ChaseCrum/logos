#!/bin/bash
set -e

# Ensure LFS is set
if [ -z "$LFS" ]; then
  echo "❌ LFS variable is not set."
  exit 1
fi

# Ensure running as root but executing as 'lfs' user
if [ "$(id -u)" -eq 0 ]; then
  echo "✅ Running as root. Executing build steps as 'lfs' user..."
  sudo -u lfs LFS=$LFS bash "$0"
  exit $?
fi

echo "🔧 Building temporary tools in $LFS..."

cd $LFS/sources

# M4
echo "🔧 Building M4..."
tar -xf m4-*.tar.*
cd m4-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf m4-*/

# Ncurses
echo "🔧 Building Ncurses..."
tar -xf ncurses-*.tar.*
cd ncurses-*/
mkdir build
pushd build
../configure AWK=gawk
make -C include
make -C progs tic
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess) --mandir=/usr/share/man \
  --with-manpage-format=normal --with-shared --without-normal --with-cxx-shared \
  --without-debug --without-ada --disable-stripping AWK=gawk
make
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' -i $LFS/usr/include/curses.h
cd ..
rm -rf ncurses-*/

# Bash
echo "🔧 Building Bash..."
tar -xf bash-*.tar.*
cd bash-*/
./configure --prefix=/usr --build=$(sh support/config.guess) --host=$LFS_TGT --without-bash-malloc
make
make DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh
cd ..
rm -rf bash-*/

# Coreutils (with fix)
echo "🔧 Building Coreutils..."
tar -xf coreutils-*.tar.*
cd coreutils-*/
FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess) \
  --enable-install-program=hostname --enable-no-install-program=kill,uptime
make
make DESTDIR=$LFS install
mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8
cd ..
rm -rf coreutils-*/

# Diffutils
echo "🔧 Building Diffutils..."
tar -xf diffutils-*.tar.*
cd diffutils-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf diffutils-*/

# File
echo "🔧 Building File..."
tar -xf file-*.tar.*
cd file-*/
mkdir build
pushd build
../configure --disable-bzlib --disable-libseccomp --disable-xzlib --disable-zlib
make
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la
cd ..
rm -rf file-*/

# Findutils
echo "🔧 Building Findutils..."
tar -xf findutils-*.tar.*
cd findutils-*/
./configure --prefix=/usr --localstatedir=/var/lib/locate --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf findutils-*/

# Gawk
echo "🔧 Building Gawk..."
tar -xf gawk-*.tar.*
cd gawk-*/
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf gawk-*/

# Grep
echo "🔧 Building Grep..."
tar -xf grep-*.tar.*
cd grep-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf grep-*/

# Gzip
echo "🔧 Building Gzip..."
tar -xf gzip-*.tar.*
cd gzip-*/
./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install
cd ..
rm -rf gzip-*/

# Make
echo "🔧 Building Make..."
tar -xf make-*.tar.*
cd make-*/
./configure --prefix=/usr --without-guile --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf make-*/

# Patch
echo "🔧 Building Patch..."
tar -xf patch-*.tar.*
cd patch-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf patch-*/

# Sed
echo "🔧 Building Sed..."
tar -xf sed-*.tar.*
cd sed-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf sed-*/

# Tar
echo "🔧 Building Tar..."
tar -xf tar-*.tar.*
cd tar-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf tar-*/

# Xz
echo "🔧 Building Xz..."
tar -xf xz-*.tar.*
cd xz-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess) --disable-static \
  --docdir=/usr/share/doc/xz-5.6.4
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la
cd ..
rm -rf xz-*/

echo "✅ Temporary tools build complete!"
