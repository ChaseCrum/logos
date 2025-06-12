#!/bin/bash

# Validate LFS environment variable
if [[ -z "$LFS" ]]; then
  echo "ERROR: LFS environment variable not set."
  echo "Please set it with: export LFS=/mnt/lfs (or your correct path)"
  exit 1
fi

PKG_LIST="needed_packages.txt"
SUMMARY="download_summary.txt"
DOWNLOAD_DIR="$LFS/sources"

mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR" || exit 1

# Clear any previous summary
echo -e "Package\t\t\tStatus\t\t\tChecksum Match" > "../$SUMMARY"

# Logging helper
log_status() {
  local name=$1
  local status=$2
  local checksum=$3
  printf "%-20s %-24s %-20s\n" "$name" "$status" "$checksum" >> "../$SUMMARY"
}

# Extract and process package info from list
awk '
/• / {
  gsub(/• /, "")
  name=$1
  version=$2
  nextline=1
}
/Download:/ {
  if (nextline) {
    url=$2
    nextline=0
  }
}
/MD5 sum:/ {
  checksum=$3
  printf "%s|%s|%s\n", name, url, checksum
}
' "../$PKG_LIST" | while IFS='|' read -r pkgname url expected_md5; do
  filename=$(basename "$url")
  echo "Processing $pkgname → $filename"

  if [[ -f "$filename" ]]; then
    echo "→ Already exists. Verifying checksum..."
    actual_md5=$(md5sum "$filename" | awk '{print $1}')
    if [[ "$actual_md5" == "$expected_md5" ]]; then
      log_status "$pkgname" "Already Present" "Matched"
      continue
    else
      echo "→ Checksum mismatch. Redownloading..."
      rm -f "$filename"
    fi
  fi

  echo "→ Downloading $filename ..."
  if curl -LO "$url"; then
    actual_md5=$(md5sum "$filename" | awk '{print $1}')
    if [[ "$actual_md5" == "$expected_md5" ]]; then
      log_status "$pkgname" "Downloaded" "Matched"
    else
      log_status "$pkgname" "Downloaded" "Mismatch"
    fi
  else
    log_status "$pkgname" "Failed to Download" "N/A"
  fi
done

# Display summary
echo -e "\nSummary written to $SUMMARY"
column -t "../$SUMMARY"

