#!/bin/bash
set -e

# === Ensure LFS is available, even if run via sudo ===
if [ -z "$LFS" ]; then
  if [ -n "$SUDO_UID" ]; then
    LFS=$(sudo -u "#$SUDO_UID" bash -c 'echo $LFS')
    export LFS
  fi
fi

if [ -z "$LFS" ]; then
  echo "❌ LFS variable is not set."
  exit 1
fi

# === Switch to 'lfs' user if running as root ===
if [ "$(id -u)" -eq 0 ] && [ "$USER" != "lfs" ]; then
  echo "✅ Running as root. Switching to 'lfs' user..."
  exec sudo -E -u lfs env LFS="$LFS" bash "$0"
fi

cd "$LFS/sources"

build_and_install() {
  PACKAGE_GLOB="$1"
  CONFIGURE_CMD="$2"
  MAKE_FLAGS="$3"
  POST_INSTALL="$4"

  SRC_DIR=$(find . -maxdepth 1 -type d -name "$PACKAGE_GLOB*" | head -n 1)
  if [ ! -d "$SRC_DIR" ]; then
    echo "❌ Source directory not found for $PACKAGE_GLOB"
    exit 1
  fi

  echo "🔧 Building $PACKAGE_GLOB in $SRC_DIR"
  cd "$SRC_DIR"

  if [ -f configure ]; then
    eval "$CONFIGURE_CMD"
  fi

  eval "make $MAKE_FLAGS"
  make DESTDIR=$LFS install

  if [ -n "$POST_INSTALL" ]; then
    eval "$POST_INSTALL"
  fi

  cd "$LFS/sources"
  echo "✅ $PACKAGE_GLOB build complete."
}

# 6.2 M4
build_and_install "m4-" \
  "./configure --prefix=/usr --host=\$LFS_TGT --build=\$(build-aux/config.guess)" "" ""

# 6.3 Ncurses
NCURSES_DIR=$(find . -type d -name "ncurses*" | head -n 1)
cd "$NCURSES_DIR"
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
sed -e 's/^#if.*XOPEN.*$/#if 1/' -i $LFS/usr/include/curses.h
cd $LFS/sources

# 6.4 Bash
build_and_install "bash-" \
  "./configure --prefix=/usr --build=\$(sh support/config.guess) --host=\$LFS_TGT --without-bash-malloc" "" \
  "ln -sv bash \$LFS/bin/sh"

# 6.5 Coreutils
build_and_install "coreutils-" \
  "FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr --host=\$LFS_TGT --build=\$(build-aux/config.guess) --enable-install-program=hostname --enable-no-install-program=kill,uptime" "" \
  "mv -v \$LFS/usr/bin/chroot \$LFS/usr/sbin && mkdir -pv \$LFS/usr/share/man/man8 && mv -v \$LFS/usr/share/man/man1/chroot.1 \$LFS/usr/share/man/man8/chroot.8 && sed -i 's/\"1\"/\"8\"/' \$LFS/usr/share/man/man8/chroot.8"

# 6.6 Diffutils
build_and_install "diffutils-" \
  "./configure --prefix=/usr --host=\$LFS_TGT --build=\$(./build-aux/config.guess)" "" ""

# 6.7 File
FILE_DIR=$(find . -type d -name "file-"* | head -n 1)
cd "$FILE_DIR"
mkdir build && pushd build
../configure --disable-bzlib --disable-libseccomp --disable-xzlib --disable-zlib
make
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la
cd $LFS/sources

# 6.8 Findutils
build_and_install "findutils-" \
  "./configure --prefix=/usr --localstatedir=/var/lib/locate --host=\$LFS_TGT --build=\$(build-aux/config.guess)" "" ""

# 6.9 Gawk
GAWK_DIR=$(find . -type d -name "gawk-"* | head -n 1)
cd "$GAWK_DIR"
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd $LFS/sources

# 6.10 Grep
build_and_install "grep-" \
  "./configure --prefix=/usr --host=\$LFS_TGT --build=\$(./build-aux/config.guess)" "" ""

# 6.11 Gzip
build_and_install "gzip-" \
  "./configure --prefix=/usr --host=\$LFS_TGT" "" ""

# 6.12 Make
build_and_install "make-" \
  "./configure --prefix=/usr --without-guile --host=\$LFS_TGT --build=\$(build-aux/config.guess)" "" ""

# 6.13 Patch
build_and_install "patch-" \
  "./configure --prefix=/usr --host=\$LFS_TGT --build=\$(build-aux/config.guess)" "" ""

# 6.14 Sed
build_and_install "sed-" \
  "./configure --prefix=/usr --host=\$LFS_TGT --build=\$(./build-aux/config.guess)" "" ""

# 6.15 Tar
build_and_install "tar-" \
  "./configure --prefix=/usr --host=\$LFS_TGT --build=\$(build-aux/config.guess)" "" ""

# 6.16 Xz
XZ_DIR=$(find . -type d -name "xz-"* | head -n 1)
cd "$XZ_DIR"
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess) --disable-static --docdir=/usr/share/doc/xz-5.6.4
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la
cd $LFS/sources

echo "🎉 All temporary tools built successfully!"
