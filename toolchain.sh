#!/bin/bash

# Define LFS root
export LFS=/mnt/lfs

echo "Starting environment checks..."

# 1. Check if the current shell is bash
if [ -n "$BASH_VERSION" ]; then
    echo "[PASS] Bash is the current shell in use."
else
    echo "[FAIL] Bash is NOT the current shell in use."
fi

# 2. Check if /bin/sh is a symlink to bash
if [ -L /bin/sh ]; then
    sh_target=$(readlink -f /bin/sh)
    if [[ "$sh_target" == *bash* ]]; then
        echo "[PASS] /bin/sh is a symbolic link to bash ($sh_target)."
    else
        echo "[FAIL] /bin/sh is a symlink but not to bash (points to $sh_target)."
    fi
else
    echo "[FAIL] /bin/sh is not a symbolic link."
fi

# 3. Check if /usr/bin/awk is a symlink to gawk
if [ -L /usr/bin/awk ]; then
    awk_target=$(readlink -f /usr/bin/awk)
    if [[ "$awk_target" == *gawk* ]]; then
        echo "[PASS] /usr/bin/awk is a symbolic link to gawk ($awk_target)."
    else
        echo "[FAIL] /usr/bin/awk is a symlink but not to gawk (points to $awk_target)."
    fi
else
    echo "[FAIL] /usr/bin/awk is not a symbolic link."
fi

# 4. Check if /usr/bin/yacc is a symlink to bison or a script that calls bison
if [ -L /usr/bin/yacc ]; then
    yacc_target=$(readlink -f /usr/bin/yacc)
    if [[ "$yacc_target" == *bison* ]]; then
        echo "[PASS] /usr/bin/yacc is a symbolic link to bison ($yacc_target)."
    else
        echo "[FAIL] /usr/bin/yacc is a symlink but not to bison (points to $yacc_target)."
    fi
elif grep -q bison /usr/bin/yacc 2>/dev/null; then
    echo "[PASS] /usr/bin/yacc is a script that calls bison."
else
    echo "[FAIL] /usr/bin/yacc is neither a symlink to bison nor a script that calls it."
fi

