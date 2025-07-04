#!/bin/bash
set -e

# Check for correct user
if [ "$(whoami)" != "lfs" ]; then
  echo "❌ This script must be run as the 'lfs' user. Exiting."
  exit 1
fi

echo "🧰 Starting temporary tools build (Chapter 6)..."

cd $LFS/sources

#####################################
# 6.2. M4
#####################################
echo "🔧 Building M4..."
tar -xf m4-*.tar.xz
cd m4-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf m4-*/

#####################################
# 6.3. Ncurses
#####################################
echo "🔧 Building Ncurses..."
tar -xf ncurses-*.tar.xz
cd ncurses-*/
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
cd ..
rm -rf ncurses-*/

#####################################
# 6.4. Bash
#####################################
echo "🔧 Building Bash..."
tar -xf bash-*.tar.gz
cd bash-*/
./configure --prefix=/usr --build=$(sh support/config.guess) --host=$LFS_TGT --without-bash-malloc
make
make DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh
cd ..
rm -rf bash-*/

#####################################
# 6.5. Coreutils
#####################################
echo "🔧 Building Coreutils..."
tar -xf coreutils-*.tar.xz
cd coreutils-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess) \
  --enable-install-program=hostname --enable-no-install-program=kill,uptime
make
make DESTDIR=$LFS install
mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8
cd ..
rm -rf coreutils-*/

#####################################
# 6.6. Diffutils
#####################################
echo "🔧 Building Diffutils..."
tar -xf diffutils-*.tar.xz
cd diffutils-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf diffutils-*/

#####################################
# 6.7. File
#####################################
echo "🔧 Building File..."
tar -xf file-*.tar.gz
cd file-*/
mkdir build && pushd build
../configure --disable-bzlib --disable-libseccomp --disable-xzlib --disable-zlib
make
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la
cd ..
rm -rf file-*/

#####################################
# 6.8. Findutils
#####################################
echo "🔧 Building Findutils..."
tar -xf findutils-*.tar.xz
cd findutils-*/
./configure --prefix=/usr --localstatedir=/var/lib/locate \
  --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf findutils-*/

#####################################
# 6.9. Gawk
#####################################
echo "🔧 Building Gawk..."
tar -xf gawk-*.tar.xz
cd gawk-*/
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf gawk-*/

#####################################
# 6.10. Grep
#####################################
echo "🔧 Building Grep..."
tar -xf grep-*.tar.xz
cd grep-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf grep-*/

#####################################
# 6.11. Gzip
#####################################
echo "🔧 Building Gzip..."
tar -xf gzip-*.tar.xz
cd gzip-*/
./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install
cd ..
rm -rf gzip-*/

#####################################
# 6.12. Make
#####################################
echo "🔧 Building Make..."
tar -xf make-*.tar.gz
cd make-*/
./configure --prefix=/usr --without-guile --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf make-*/

#####################################
# 6.13. Patch
#####################################
echo "🔧 Building Patch..."
tar -xf patch-*.tar.xz
cd patch-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf patch-*/

#####################################
# 6.14. Sed
#####################################
echo "🔧 Building Sed..."
tar -xf sed-*.tar.xz
cd sed-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf sed-*/

#####################################
# 6.15. Tar
#####################################
echo "🔧 Building Tar..."
tar -xf tar-*.tar.xz
cd tar-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf tar-*/

#####################################
# 6.16. Xz
#####################################
echo "🔧 Building Xz..."
tar -xf xz-*.tar.xz
cd xz-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess) \
  --disable-static --docdir=/usr/share/doc/xz-5.6.4
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la
cd ..
rm -rf xz-*/

#####################################
# 6.17. Binutils (Pass 2)
#####################################
echo "🔧 Building Binutils (Pass 2)..."
tar -xf binutils-*.tar.xz
cd binutils-*/
sed '6031s/$add_dir//' -i ltmain.sh
mkdir -v build && cd build
../configure --prefix=/usr --build=$(../config.guess) --host=$LFS_TGT \
  --disable-nls --enable-shared --enable-gprofng=no --disable-werror \
  --enable-64-bit-bfd --enable-new-dtags --enable-default-hash-style=gnu
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
cd ../..
rm -rf binutils-*/

#####################################
# 6.18. GCC (Pass 2)
#####################################
echo "🔧 Building GCC (Pass 2)..."
tar -xf gcc-14.2.0.tar.xz
cd gcc-14.2.0
tar -xf ../mpfr-*.tar.xz && mv -v mpfr-* mpfr
tar -xf ../gmp-*.tar.xz && mv -v gmp-* gmp
tar -xf ../mpc-*.tar.gz && mv -v mpc-* mpc

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac

sed '/thread_header =/s/@.*@/gthr-posix.h/' \
  -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build && cd build
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
cd ../..
rm -rf gcc-14.2.0

echo "✅ Temporary tools build (Chapter 6) complete!"
