#!/bin/bash
set -e

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Please run this script as root (e.g., with sudo)."
  exit 1
fi

LFS=/mnt/lfs
LFS_TGT=$(su - lfs -c 'echo $LFS_TGT')
export LFS LFS_TGT

# Helper function to run commands as the 'lfs' user
run_as_lfs() {
  su - lfs -c "$1"
}

cd $LFS/sources
chown -v lfs:lfs * > /dev/null 2>&1 || true

extract_and_enter() {
  local tarball="$1"
  run_as_lfs "
    cd $LFS/sources &&
    tar -xf $tarball &&
    cd \$(basename $tarball .tar.*)
  "
}

clean_source() {
  local tarball="$1"
  rm -rf "$(basename "$tarball" .tar.*)"
}

########################################
# 6.2 M4
########################################
echo "🔧 Building M4..."
m4_tar=$(ls m4-*.tar.*)
run_as_lfs "
  cd $LFS/sources &&
  tar -xf $m4_tar &&
  cd m4-* &&
  ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(build-aux/config.guess) &&
  make &&
  make DESTDIR=\$LFS install &&
  cd .. && rm -rf m4-*
"

########################################
# 6.3 Ncurses
########################################
echo "🔧 Building Ncurses..."
ncurses_tar=$(ls ncurses-*.tar.*)
run_as_lfs "
  cd $LFS/sources &&
  tar -xf $ncurses_tar &&
  cd ncurses-* &&
  mkdir build && pushd build &&
    ../configure AWK=gawk &&
    make -C include &&
    make -C progs tic &&
  popd &&
  ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(./config.guess) \
    --mandir=/usr/share/man --with-manpage-format=normal \
    --with-shared --without-normal --with-cxx-shared \
    --without-debug --without-ada --disable-stripping AWK=gawk &&
  make &&
  make DESTDIR=\$LFS TIC_PATH=\$(pwd)/build/progs/tic install &&
  ln -sv libncursesw.so \$LFS/usr/lib/libncurses.so &&
  sed -e 's/^#if.*XOPEN.*$/#if 1/' -i \$LFS/usr/include/curses.h &&
  cd .. && rm -rf ncurses-*
"

########################################
# 6.4 Bash
########################################
echo "🔧 Building Bash..."
bash_tar=$(ls bash-*.tar.*)
run_as_lfs "
  cd $LFS/sources &&
  tar -xf $bash_tar &&
  cd bash-* &&
  ./configure --prefix=/usr --build=\$(sh support/config.guess) \
    --host=\$LFS_TGT --without-bash-malloc &&
  make &&
  make DESTDIR=\$LFS install &&
  ln -sv bash \$LFS/bin/sh &&
  cd .. && rm -rf bash-*
"

########################################
# 6.5 Coreutils
########################################
echo "🔧 Building Coreutils..."
coreutils_tar=$(ls coreutils-*.tar.*)
run_as_lfs "
  cd $LFS/sources &&
  tar -xf $coreutils_tar &&
  cd coreutils-* &&
  ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(build-aux/config.guess) \
    --enable-install-program=hostname --enable-no-install-program=kill,uptime &&
  make &&
  make DESTDIR=\$LFS install &&
  mv -v \$LFS/usr/bin/chroot \$LFS/usr/sbin &&
  mkdir -pv \$LFS/usr/share/man/man8 &&
  mv -v \$LFS/usr/share/man/man1/chroot.1 \$LFS/usr/share/man/man8/chroot.8 &&
  sed -i 's/\"1\"/\"8\"/' \$LFS/usr/share/man/man8/chroot.8 &&
  cd .. && rm -rf coreutils-*
"

########################################
# 6.6 to 6.16 (rest of packages)
########################################
packages=(
  "diffutils"
  "file"
  "findutils"
  "gawk"
  "grep"
  "gzip"
  "make"
  "patch"
  "sed"
  "tar"
  "xz"
)

for pkg in "${packages[@]}"; do
  echo "🔧 Building ${pkg^}..."
  tarball=$(ls $pkg-*.tar.*)
  run_as_lfs "
    cd $LFS/sources &&
    tar -xf $tarball &&
    cd $pkg-* &&
    [[ \"$pkg\" == \"file\" ]] && mkdir build && pushd build &&
      ../configure --disable-bzlib --disable-libseccomp \
      --disable-xzlib --disable-zlib && make && popd
    [[ \"$pkg\" == \"gawk\" ]] && sed -i 's/extras//' Makefile.in
    ./configure --prefix=/usr --host=\$LFS_TGT \
      --build=\$(./configure --help 2>/dev/null | grep -q build-aux && echo ./build-aux/config.guess || echo ./config.guess)
    [[ \"$pkg\" == \"file\" ]] && make FILE_COMPILE=\$(pwd)/build/src/file || make
    make DESTDIR=\$LFS install
    [[ \"$pkg\" == \"file\" ]] && rm -v \$LFS/usr/lib/libmagic.la
    [[ \"$pkg\" == \"xz\" ]] && rm -v \$LFS/usr/lib/liblzma.la
    cd .. && rm -rf $pkg-*
  "
done

echo "✅ All temporary tools from Chapter 6 have been built successfully."
