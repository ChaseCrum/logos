#!/bin/bash

# Function to prompt and fix or exit
prompt_fix() {
    local prompt_message="$1"
    local fix_command="$2"

    read -p "$prompt_message [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Attempting to fix..."
        eval "$fix_command" && echo "[FIXED] Success." || { echo "[ERROR] Fix failed."; exit 1; }
    else
        echo "Exiting script per user choice."
        exit 1
    fi
}

echo "Starting environment checks..."

# 1. Check if the current shell is bash
if [ -n "$BASH_VERSION" ]; then
    echo "[PASS] Bash is the current shell in use."
else
    echo "[FAIL] Bash is NOT the current shell."
    prompt_fix "Do you want to switch to bash?" "exec /bin/bash"
fi

# 2. Check if /bin/sh is a symlink to bash
if [ -L /bin/sh ]; then
    sh_target=$(readlink -f /bin/sh)
    if [[ "$sh_target" == *bash* ]]; then
        echo "[PASS] /bin/sh is a symbolic link to bash ($sh_target)."
    else
        echo "[FAIL] /bin/sh points to $sh_target, not bash."
        prompt_fix "Do you want to relink /bin/sh to bash?" "ln -sf /bin/bash /bin/sh"
    fi
else
    echo "[FAIL] /bin/sh is not a symbolic link."
    prompt_fix "Do you want to replace /bin/sh with a symlink to bash?" "rm -f /bin/sh && ln -s /bin/bash /bin/sh"
fi

# 3. Check if /usr/bin/awk is a symlink to gawk
if [ -L /usr/bin/awk ]; then
    awk_target=$(readlink -f /usr/bin/awk)
    if [[ "$awk_target" == *gawk* ]]; then
        echo "[PASS] /usr/bin/awk is a symbolic link to gawk ($awk_target)."
    else
        echo "[FAIL] /usr/bin/awk points to $awk_target, not gawk."
        prompt_fix "Do you want to relink /usr/bin/awk to gawk?" "ln -sf /usr/bin/gawk /usr/bin/awk"
    fi
else
    echo "[FAIL] /usr/bin/awk is not a symbolic link."
    prompt_fix "Do you want to replace /usr/bin/awk with a symlink to gawk?" "rm -f /usr/bin/awk && ln -s /usr/bin/gawk /usr/bin/awk"
fi

# 4. Check if /usr/bin/yacc is a symlink to bison or script that calls bison
if [ -L /usr/bin/yacc ]; then
    yacc_target=$(readlink -f /usr/bin/yacc)
    if [[ "$yacc_target" == *bison* ]]; then
        echo "[PASS] /usr/bin/yacc is a symbolic link to bison ($yacc_target)."
    else
        echo "[FAIL] /usr/bin/yacc points to $yacc_target, not bison."
        prompt_fix "Do you want to relink /usr/bin/yacc to bison?" "ln -sf /usr/bin/bison /usr/bin/yacc"
    fi
elif grep -q bison /usr/bin/yacc 2>/dev/null; then
    echo "[PASS] /usr/bin/yacc is a script that calls bison."
else
    echo "[FAIL] /usr/bin/yacc is neither a symlink nor a script that calls bison."
    prompt_fix "Do you want to create a script at /usr/bin/yacc that wraps bison?" \
    "echo -e '#!/bin/bash\nexec bison \"\$@\"' > /usr/bin/yacc && chmod +x /usr/bin/yacc"
fi

echo "✅ All checks passed or corrected."

