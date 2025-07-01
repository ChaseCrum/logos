#!/bin/bash
set -e

# Environment Checks
echo "Starting environment checks..."

all_passed=true

# Check shell
if [ "$SHELL" = "/bin/bash" ]; then
  echo "[PASS] Bash is the current shell in use."
else
  echo "[FAIL] Bash is not the current shell."
  all_passed=false
fi

# Check /bin/sh link
if [ "$(readlink -f /bin/sh)" = "/bin/bash" ]; then
  echo "[PASS] /bin/sh points to bash."
else
  echo "[FAIL] /bin/sh points to $(readlink -f /bin/sh), not bash."
  all_passed=false
fi

# Check awk
if [ "$(readlink -f /usr/bin/awk)" = "/usr/bin/gawk" ]; then
  echo "[PASS] /usr/bin/awk is a symbolic link to gawk (/usr/bin/gawk)."
else
  echo "[FAIL] /usr/bin/awk is not linked to gawk."
  all_passed=false
fi

# Check yacc
if [[ "$(readlink -f /usr/bin/yacc)" =~ bison ]]; then
  echo "[PASS] /usr/bin/yacc is a symbolic link to bison ($(readlink -f /usr/bin/yacc))."
else
  echo "[FAIL] /usr/bin/yacc is not linked to bison."
  all_passed=false
fi

if ! $all_passed; then
  echo -e "\nThe following issues were found:"
  [ "$(readlink -f /bin/sh)" != "/bin/bash" ] && echo " - /bin/sh is not linked to bash"
  [ "$(readlink -f /usr/bin/awk)" != "/usr/bin/gawk" ] && echo " - awk is not linked to gawk"
  [[ ! "$(readlink -f /usr/bin/yacc)" =~ bison ]] && echo " - yacc is not linked to bison"

  read -p $'\nDo you want to apply all suggested fixes? [y/N]: ' fixit
  if [[ "$fixit" =~ ^[Yy]$ ]]; then
    echo "Applying fixes..."
    [ "$(readlink -f /bin/sh)" != "/bin/bash" ] && ln -sf /bin/bash /bin/sh && echo "→ ln -sf /bin/bash /bin/sh"
    [ "$(readlink -f /usr/bin/awk)" != "/usr/bin/gawk" ] && ln -sf /usr/bin/gawk /usr/bin/awk && echo "→ ln -sf /usr/bin/gawk /usr/bin/awk"
    [[ ! "$(readlink -f /usr/bin/yacc)" =~ bison ]] && ln -sf /usr/bin/bison /usr/bin/yacc && echo "→ ln -sf /usr/bin/bison /usr/bin/yacc"
    echo "✅ All issues corrected."
  else
    echo "Aborting due to unresolved environment issues."
    exit 1
  fi
fi

# Check if gcc works on host
if command -v gcc >/dev/null 2>&1; then
  echo -n "[INFO] Testing host GCC compiler... "
  echo 'int main() { return 0; }' > test.c
  gcc test.c -o test.out >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "✅ Host GCC compiler works."
    rm -f test.c test.out
  else
    echo "❌ Host GCC compiler failed to compile."
    rm -f test.c
    echo "Please ensure GCC and build tools are installed on your host system."
    exit 1
  fi
else
  echo "❌ GCC is not installed on the host system."
  echo "Please install GCC and development tools before proceeding."
  exit 1
fi

# Set LFS variable
export LFS=/mnt/lfs
echo "LFS variable is set to: $LFS"

# Symlink /tools if not exists
[ ! -e /tools ] && ln -s $LFS/tools /tools

# Build Binutils (Pass 1)
echo "🔧 Building Binutils (Pass 1)"
sudo su - lfs << 'EOF'
set -e

export LFS=/mnt/lfs
export PATH=$LFS/tools/bin:$PATH

cd $LFS/sources
tar -xf binutils-*.tar.*
cd binutils-*/
mkdir -v build
cd build

../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$(uname -m)-lfs-linux-gnu \
             --disable-nls \
             --enable-gprofng=no \
             --disable-werror \
             --enable-new-dtags \
             --enable-default-hash-style=gnu

make -j$(nproc)
make install

cd $LFS/sources
rm -rf binutils-*/
EOF

# Clean up archive as root
echo "🧹 Cleaning up binutils archive..."
rm -f /mnt/lfs/sources/binutils-*.tar.*

echo "✅ toolchain2.sh completed."
exit 0
