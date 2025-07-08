#!/bin/bash

echo "🔍 Running post-chroot diagnostics..."

# 1. Check present working directory
echo -n "📁 Current directory: "
pwd

# 2. Verify LFS is unset
if [ -z "$LFS" ]; then
  echo "✅ \$LFS is unset (expected inside chroot)"
else
  echo "❌ \$LFS is still set to: $LFS"
fi

# 3. Verify essential tools are available
for tool in bash gcc ld; do
  if command -v $tool >/dev/null 2>&1; then
    echo "✅ $tool found at $(command -v $tool)"
  else
    echo "❌ $tool not found"
  fi
done

# 4. Check gcc specs and linker location
echo 'main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log

echo -n "🔗 Linked dynamic linker: "
readelf -l a.out | grep ': /lib' || echo "❌ Not found"

echo -n "📚 Libraries search paths: "
grep -o '/usr/lib.*/crt1.o' dummy.log | head -n 1 || echo "❌ /usr/lib not found in gcc output"

# 5. Show ld symlink location
echo -n "🔗 ld symlink: "
readlink -f $(command -v ld) || echo "❌ ld not found"

# Cleanup
rm -f dummy.c a.out dummy.log

echo "✅ Post-chroot diagnostics complete."