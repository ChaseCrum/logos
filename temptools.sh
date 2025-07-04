#!/bin/bash
set -e

# === Ensure LFS variable is set, even when run via sudo ===
if [ -z "$LFS" ]; then
  if [ -n "$SUDO_USER" ]; then
    LFS=$(sudo -u "$SUDO_USER" bash -c 'echo $LFS')
  fi
  if [ -z "$LFS" ]; then
    LFS=$(sudo -u lfs bash -c 'echo $LFS')
  fi
  export LFS
fi

if [ -z "$LFS" ]; then
  echo "❌ LFS variable is not set and could not be recovered."
  exit 1
fi

echo "✅ LFS is set to: $LFS"
echo "🔧 Running temptools.sh as $(whoami)"

run_as_lfs() {
  sudo -H -u lfs bash -c "source ~/.bashrc && cd /mnt/lfs/sources && $1"
}

# M4
run_as_lfs "
  tar -xf m4-*.tar.* &&
  cd m4-* &&
  ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(build-aux/config.guess) &&
  make &&
  make DESTDIR=\$LFS install &&
  cd .. &&
  rm -rf m4-*
"

# Ncurses
run_as_lfs "
  tar -xf ncurses-*.tar.* &&
  cd ncurses-* &&
  mkdir build &&
  pushd build &&
    ../configure AWK=gawk &&
    make -C include &&
    make -C progs tic &&
  popd &&
  ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(./config.guess) \
    --mandir=/usr/share/man --with-manpage-format=normal --with-shared \
    --without-normal --with-cxx-shared --without-debug --without-ada \
    --disable-stripping AWK=gawk &&
  make &&
  make DESTDIR=\$LFS TIC_PATH=\$(pwd)/build/progs/tic install &&
  ln -sv libncursesw.so \$LFS/usr/lib/libncurses.so &&
  sed -e 's/^#if.*XOPEN.*\$/#if 1/' -i \$LFS/usr/include/curses.h &&
  cd .. &&
  rm -rf ncurses-*
"

# Bash
run_as_lfs "
  tar -xf bash-*.tar.* &&
  cd bash-* &&
  ./configure --prefix=/usr --build=\$(sh support/config.guess) --host=\$LFS_TGT --without-bash-malloc &&
  make &&
  make DESTDIR=\$LFS install &&
  ln -sv bash \$LFS/bin/sh &&
  cd .. &&
  rm -rf bash-*
"

# Coreutils
run_as_lfs "
  tar -xf coreutils-*.tar.* &&
  cd coreutils-* &&
  FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr --host=\$LFS_TGT \
    --build=\$(build-aux/config.guess) \
    --enable-install-program=hostname \
    --enable-no-install-program=kill,uptime &&
  make &&
  make DESTDIR=\$LFS install &&
  mv -v \$LFS/usr/bin/chroot \$LFS/usr/sbin &&
  mkdir -pv \$LFS/usr/share/man/man8 &&
  mv -v \$LFS/usr/share/man/man1/chroot.1 \$LFS/usr/share/man/man8/chroot.8 &&
  sed -i 's/\"1\"/\"8\"/' \$LFS/usr/share/man/man8/chroot.8 &&
  cd .. &&
  rm -rf coreutils-*
"

# Diffutils
run_as_lfs "
  tar -xf diffutils-*.tar.* &&
  cd diffutils-* &&
  ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(./build-aux/config.guess) &&
  make &&
  make DESTDIR=\$LFS install &&
  cd .. &&
  rm -rf diffutils-*
"

# File
run_as_lfs "
  tar -xf file-*.tar.* &&
  cd file-* &&
  mkdir build &&
  pushd build &&
    ../configure --disable-bzlib --disable-libseccomp --disable-xzlib --disable-zlib &&
    make
  popd &&
  ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(./config.guess) &&
  make FILE_COMPILE=\$(pwd)/build/src/file &&
  make DESTDIR=\$LFS install &&
  rm -v \$LFS/usr/lib/libmagic.la &&
  cd .. &&
  rm -rf file-*
"

# Findutils
run_as_lfs "
  tar -xf findutils-*.tar.* &&
  cd findutils-* &&
  ./configure --prefix=/usr --localstatedir=/var/lib/locate \
    --host=\$LFS_TGT --build=\$(build-aux/config.guess) &&
  make &&
  make DESTDIR=\$LFS install &&
  cd .. &&
  rm -rf findutils-*
"

# Gawk
run_as_lfs "
  tar -xf gawk-*.tar.* &&
  cd gawk-* &&
  sed -i 's/extras//' Makefile.in &&
  ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(build-aux/config.guess) &&
  make &&
  make DESTDIR=\$LFS install &&
  cd .. &&
  rm -rf gawk-*
"

# Grep
run_as_lfs "
  tar -xf grep-*.tar.* &&
  cd grep-* &&
  ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(./build-aux/config.guess) &&
  make &&
  make DESTDIR=\$LFS install &&
  cd .. &&
  rm -rf grep-*
"

# Gzip
run_as_lfs "
  tar -xf gzip-*.tar.* &&
  cd gzip-* &&
  ./configure --prefix=/usr --host=\$LFS_TGT &&
  make &&
  make DESTDIR=\$LFS install &&
  cd .. &&
  rm -rf gzip-*
"

# Make
run_as_lfs "
  tar -xf make-*.tar.* &&
  cd make-* &&
  ./configure --prefix=/usr --without-guile --host=\$LFS_TGT --build=\$(build-aux/config.guess) &&
  make &&
  make DESTDIR=\$LFS install &&
  cd .. &&
  rm -rf make-*
"

# Patch
run_as_lfs "
  tar -xf patch-*.tar.* &&
  cd patch-* &&
  ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(build-aux/config.guess) &&
  make &&
  make DESTDIR=\$LFS install &&
  cd .. &&
  rm -rf patch-*
"

# Sed
run_as_lfs "
  tar -xf sed-*.tar.* &&
  cd sed-* &&
  ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(./build-aux/config.guess) &&
  make &&
  make DESTDIR=\$LFS install &&
  cd .. &&
  rm -rf sed-*
"

# Tar
run_as_lfs "
  tar -xf tar-*.tar.* &&
  cd tar-* &&
  ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(build-aux/config.guess) &&
  make &&
  make DESTDIR=\$LFS install &&
  cd .. &&
  rm -rf tar-*
"

# Xz
run_as_lfs "
  tar -xf xz-*.tar.* &&
  cd xz-* &&
  ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(build-aux/config.guess) \
    --disable-static --docdir=/usr/share/doc/xz-5.6.4 &&
  make &&
  make DESTDIR=\$LFS install &&
  rm -v \$LFS/usr/lib/liblzma.la &&
  cd .. &&
  rm -rf xz-*
"

echo "✅ temptools.sh completed successfully!"
