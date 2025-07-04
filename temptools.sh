#!/bin/bash
set -e

# === Preserve LFS variable when running with sudo ===
if [ -z "$LFS" ]; then
  if [ -n "$SUDO_USER" ]; then
    LFS=$(sudo -u "$SUDO_USER" bash -c 'echo $LFS')
    export LFS
  fi
fi

if [ -z "$LFS" ]; then
  echo "❌ LFS variable is not set."
  exit 1
fi

echo "✅ LFS is set to: $LFS"
echo "🔧 Running temptools.sh as $(whoami)"

execute_as_lfs() {
  sudo -u lfs bash -c "cd \$HOME && $1"
}

cd /mnt/lfs/sources

execute_as_lfs '
  set -e
  tar -xf m4-*.tar.* && cd m4-*
  ./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
  make
  make DESTDIR=$LFS install
'

execute_as_lfs '
  set -e
  tar -xf ncurses-*.tar.* && cd ncurses-*
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
  sed -e '\''s/^#if.*XOPEN.*$/#if 1/'\'' -i $LFS/usr/include/curses.h
'

execute_as_lfs '
  set -e
  tar -xf bash-*.tar.* && cd bash-*
  ./configure --prefix=/usr --build=$(sh support/config.guess) \
    --host=$LFS_TGT --without-bash-malloc
  make
  make DESTDIR=$LFS install
  ln -sv bash $LFS/bin/sh
'

execute_as_lfs '
  set -e
  tar -xf coreutils-*.tar.* && cd coreutils-*
  FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr --host=$LFS_TGT \
    --build=$(build-aux/config.guess) --enable-install-program=hostname \
    --enable-no-install-program=kill,uptime
  make
  make DESTDIR=$LFS install
  mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
  mkdir -pv $LFS/usr/share/man/man8
  mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
  sed -i '\''s/"1"/"8"/'\'' $LFS/usr/share/man/man8/chroot.8
'

execute_as_lfs '
  set -e
  tar -xf diffutils-*.tar.* && cd diffutils-*
  ./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
  make
  make DESTDIR=$LFS install
'

execute_as_lfs '
  set -e
  tar -xf file-*.tar.* && cd file-*
  mkdir build && pushd build
  ../configure --disable-bzlib --disable-libseccomp --disable-xzlib --disable-zlib
  make
  popd
  ./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
  make FILE_COMPILE=$(pwd)/build/src/file
  make DESTDIR=$LFS install
  rm -v $LFS/usr/lib/libmagic.la
'

execute_as_lfs '
  set -e
  tar -xf findutils-*.tar.* && cd findutils-*
  ./configure --prefix=/usr --localstatedir=/var/lib/locate \
    --host=$LFS_TGT --build=$(build-aux/config.guess)
  make
  make DESTDIR=$LFS install
'

execute_as_lfs '
  set -e
  tar -xf gawk-*.tar.* && cd gawk-*
  sed -i '\''s/extras//'\'' Makefile.in
  ./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
  make
  make DESTDIR=$LFS install
'

execute_as_lfs '
  set -e
  tar -xf grep-*.tar.* && cd grep-*
  ./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
  make
  make DESTDIR=$LFS install
'

execute_as_lfs '
  set -e
  tar -xf gzip-*.tar.* && cd gzip-*
  ./configure --prefix=/usr --host=$LFS_TGT
  make
  make DESTDIR=$LFS install
'

execute_as_lfs '
  set -e
  tar -xf make-*.tar.* && cd make-*
  ./configure --prefix=/usr --without-guile --host=$LFS_TGT \
    --build=$(build-aux/config.guess)
  make
  make DESTDIR=$LFS install
'

execute_as_lfs '
  set -e
  tar -xf patch-*.tar.* && cd patch-*
  ./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
  make
  make DESTDIR=$LFS install
'

execute_as_lfs '
  set -e
  tar -xf sed-*.tar.* && cd sed-*
  ./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
  make
  make DESTDIR=$LFS install
'

execute_as_lfs '
  set -e
  tar -xf tar-*.tar.* && cd tar-*
  ./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
  make
  make DESTDIR=$LFS install
'

execute_as_lfs '
  set -e
  tar -xf xz-*.tar.* && cd xz-*
  ./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess) \
    --disable-static --docdir=/usr/share/doc/xz-5.6.4
  make
  make DESTDIR=$LFS install
  rm -v $LFS/usr/lib/liblzma.la
'

execute_as_lfs '
  set -e
  tar -xf binutils-*.tar.* && cd binutils-*
  sed '\''6031s/$add_dir//'\'' -i ltmain.sh
  mkdir build && cd build
  ../configure --prefix=/usr --build=$(../config.guess) --host=$LFS_TGT \
    --disable-nls --enable-shared --enable-gprofng=no --disable-werror \
    --enable-64-bit-bfd --enable-new-dtags --enable-default-hash-style=gnu
  make
  make DESTDIR=$LFS install
  rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
'

execute_as_lfs '
  set -e
  tar -xf gcc-14.*.tar.* && cd gcc-14.*/
  tar -xf ../mpfr-*.tar.* && mv -v mpfr-* mpfr
  tar -xf ../gmp-*.tar.* && mv -v gmp-* gmp
  tar -xf ../mpc-*.tar.* && mv -v mpc-* mpc
  case $(uname -m) in
    x86_64)
      sed -e '\''/m64=/s/lib64/lib/'\'' -i.orig gcc/config/i386/t-linux64
    ;;
  esac
  sed '\''/thread_header =/s/@.*@/gthr-posix.h/'\'' -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
  mkdir build && cd build
  ../configure --build=$(../config.guess) --host=$LFS_TGT --target=$LFS_TGT \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc --prefix=/usr \
    --with-build-sysroot=$LFS --enable-default-pie --enable-default-ssp \
    --disable-nls --disable-multilib --disable-libatomic --disable-libgomp \
    --disable-libquadmath --disable-libsanitizer --disable-libssp \
    --disable-libvtv --enable-languages=c,c++
  make
  make DESTDIR=$LFS install
  ln -sv gcc $LFS/usr/bin/cc
'

echo "🎉 temptools.sh completed successfully!"
