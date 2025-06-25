#!/bin/bash

# Define LFS root
export LFS=/mnt/lfs

echo "Starting environment checks..."

sleep 3

# Track failed conditions and fixes
declare -a fixes
declare -a messages

# 1. Check if the current shell is bash
if [ -n "$BASH_VERSION" ]; then
    echo "[PASS] Bash is the current shell in use."
else
    echo "[FAIL] Bash is NOT the current shell in use."
    messages+=("Shell is not Bash")
    fixes+=("exec /bin/bash")
fi

# 2. Check if /bin/sh is a symlink to bash
if [ -L /bin/sh ]; then
    sh_target=$(readlink -f /bin/sh)
    if [[ "$sh_target" == *bash* ]]; then
        echo "[PASS] /bin/sh is a symbolic link to bash ($sh_target)."
    else
        echo "[FAIL] /bin/sh points to $sh_target, not bash."
        messages+=("/bin/sh is not linked to bash")
        fixes+=("ln -sf /bin/bash /bin/sh")
    fi
else
    echo "[FAIL] /bin/sh is not a symbolic link."
    messages+=("/bin/sh is not a symlink at all")
    fixes+=("rm -f /bin/sh && ln -s /bin/bash /bin/sh")
fi

# 3. Check if /usr/bin/awk is a symlink to gawk
if [ -L /usr/bin/awk ]; then
    awk_target=$(readlink -f /usr/bin/awk)
    if [[ "$awk_target" == *gawk* ]]; then
        echo "[PASS] /usr/bin/awk is a symbolic link to gawk ($awk_target)."
    else
        echo "[FAIL] /usr/bin/awk points to $awk_target, not gawk."
        messages+=("/usr/bin/awk is not linked to gawk")
        fixes+=("ln -sf /usr/bin/gawk /usr/bin/awk")
    fi
else
    echo "[FAIL] /usr/bin/awk is not a symbolic link."
    messages+=("/usr/bin/awk is not a symlink at all")
    fixes+=("rm -f /usr/bin/awk && ln -s /usr/bin/gawk /usr/bin/awk")
fi

# 4. Check if /usr/bin/yacc is a symlink to bison or a wrapper script
if [ -L /usr/bin/yacc ]; then
    yacc_target=$(readlink -f /usr/bin/yacc)
    if [[ "$yacc_target" == *bison* ]]; then
        echo "[PASS] /usr/bin/yacc is a symbolic link to bison ($yacc_target)."
    else
        echo "[FAIL] /usr/bin/yacc points to $yacc_target, not bison."
        messages+=("/usr/bin/yacc is a symlink but not to bison")
        fixes+=("ln -sf /usr/bin/bison /usr/bin/yacc")
    fi
elif grep -q bison /usr/bin/yacc 2>/dev/null; then
    echo "[PASS] /usr/bin/yacc is a script that calls bison."
else
    echo "[FAIL] /usr/bin/yacc is neither a symlink nor a bison-calling script."
    messages+=("/usr/bin/yacc is not set up correctly")
    fixes+=("echo -e '#!/bin/bash\nexec bison \"\$@\"' > /usr/bin/yacc && chmod +x /usr/bin/yacc")
fi

# Summary and fix prompt
if [ ${#fixes[@]} -eq 0 ]; then
    echo "✅ All checks passed. No changes needed."
else
    echo -e "\nThe following issues were found:"
    for msg in "${messages[@]}"; do
        echo " - $msg"
    done

    read -p $'\nDo you want to apply all suggested fixes? [y/N]: ' answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Applying fixes..."
        for cmd in "${fixes[@]}"; do
            echo "→ $cmd"
            eval "$cmd" || { echo "[ERROR] Failed to execute: $cmd"; exit 1; }
        done
        echo "✅ All issues corrected."
    else
        echo "No changes made. Exiting."
        exit 1
    fi
fi

sleep 3
echo "LFS variable is set to: "$LFS
