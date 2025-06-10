#!/bin/bash

# Avoid silent failure
#set -euo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "Please run this script with sudo."
   exit 1
fi

PACKAGE_FILE="packages.txt"
SUMMARY=()

# === Functions ===

# Compare versions
version_ge() {
  dpkg --compare-versions "$1" ge "$2"
}

# Sanitize version
clean_version() {
  echo "$1" | sed 's/[^0-9a-zA-Z.\-]//g'
}

# Normalize name
normalize_package_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

# Get installed version
get_installed_version() {
  dpkg -l 2>/dev/null | awk -v pkg="$1" '$1 == "ii" && $2 == pkg {print $3}' | head -n1
}

# === Main Loop ===

i=0
total=$(grep -c . "$PACKAGE_FILE")

while IFS= read -r line || [[ -n "$line" ]]; do
  ((i++))
  echo -n "."  # Simple progress

  PACKAGE_ORIG=$(echo "$line" | cut -d'-' -f1 | xargs)
  PACKAGE=$(normalize_package_name "$PACKAGE_ORIG")
  REQUIRED_VERSION=$(clean_version "$(echo "$line" | cut -d'-' -f2 | xargs)")

  # Linux kernel special case
  if [[ "$PACKAGE" == "linux-kernel" ]]; then
    CURRENT_VERSION=$(uname -r | cut -d'-' -f1)
    if version_ge "$CURRENT_VERSION" "$REQUIRED_VERSION"; then
      SUMMARY+=("$PACKAGE_ORIG - Found")
    else
      SUMMARY+=("$PACKAGE_ORIG - Cannot Meet requirement")
    fi
    continue
  fi

  # Try to find installed version
  CURRENT_VERSION=$(get_installed_version "$PACKAGE")

  if [[ -z "$CURRENT_VERSION" ]]; then
    apt-get update -qq >/dev/null 2>&1
    if apt-get install -y "$PACKAGE" >/dev/null 2>&1; then
      SUMMARY+=("$PACKAGE_ORIG - Installed")
    else
      SUMMARY+=("$PACKAGE_ORIG - Cannot Meet requirement")
    fi
  else
    CLEAN_CURRENT=$(clean_version "$CURRENT_VERSION")
    if version_ge "$CLEAN_CURRENT" "$REQUIRED_VERSION"; then
      SUMMARY+=("$PACKAGE_ORIG - Found")
    else
      apt-get update -qq >/dev/null 2>&1
      if apt-get install --only-upgrade -y "$PACKAGE" >/dev/null 2>&1; then
        NEW_VERSION=$(get_installed_version "$PACKAGE")
        CLEAN_NEW=$(clean_version "$NEW_VERSION")
        if version_ge "$CLEAN_NEW" "$REQUIRED_VERSION"; then
          SUMMARY+=("$PACKAGE_ORIG - Upgraded")
        else
          SUMMARY+=("$PACKAGE_ORIG - Cannot Meet requirement")
        fi
      else
        SUMMARY+=("$PACKAGE_ORIG - Cannot Meet requirement")
      fi
    fi
  fi

done < "$PACKAGE_FILE"

# === Output Summary ===
echo -e "\n\n===== Package Summary ====="
for entry in "${SUMMARY[@]}"; do
  echo "$entry"
done

