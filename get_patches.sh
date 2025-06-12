#!/bin/bash

# === Set LFS Environment ===
export LFS=/mnt/lfs

# === Working Directory & Summary ===
DOWNLOAD_DIR="$LFS/sources"
SUMMARY="$LFS/patch_download_summary.txt"

mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR" || exit 1
echo -e "Patch\t\t\tStatus\t\t\tChecksum Match" > "$SUMMARY"

# === Function to log results ===
log_status() {
  local name=$1
  local status=$2
  local checksum=$3
  printf "%-30s %-24s %-20s\n" "$name" "$status" "$checksum" >> "$SUMMARY"
}

# === Patch Data (name|url|md5) ===
patches=$(
cat <<EOF
Bzip2 Docs Patch|https://www.linuxfromscratch.org/patches/lfs/12.3/bzip2-1.0.8-install_docs-1.patch|6a5ac7e89b791aae556de0f745916f7f
Coreutils i18n Patch|https://www.linuxfromscratch.org/patches/lfs/12.3/coreutils-9.6-i18n-1.patch|6aee45dd3e05b7658971c321d92f44b7
Expect GCC14 Patch|https://www.linuxfromscratch.org/patches/lfs/12.3/expect-5.45.4-gcc14-1.patch|0b8b5ac411d011263ad40b0664c669f0
Glibc FHS Patch|https://www.linuxfromscratch.org/patches/lfs/12.3/glibc-2.41-fhs-1.patch|9a5997c3452909b1769918c759eff8a2
Kbd Backspace Patch|https://www.linuxfromscratch.org/patches/lfs/12.3/kbd-2.7.1-backspace-1.patch|f75cca16a38da6caa7d52151f7136895
SysVinit Patch|https://www.linuxfromscratch.org/patches/lfs/12.3/sysvinit-3.14-consolidated-1.patch|3af8fd8e13cad481eeeaa48be4247445
EOF
)

# === Main Processing Loop ===
echo "$patches" | while IFS='|' read -r name url md5; do
  filename=$(basename "$url")
  echo "Processing $name → $filename"

  if [[ -f "$filename" ]]; then
    echo "→ Already exists. Verifying checksum..."
    actual_md5=$(md5sum "$filename" | awk '{print $1}')
    if [[ "$actual_md5" == "$md5" ]]; then
      log_status "$name" "Already Present" "Matched"
      continue
    else
      echo "→ Checksum mismatch. Redownloading..."
      rm -f "$filename"
    fi
  fi

  echo "→ Downloading $filename ..."
  if wget -q --show-progress "$url"; then
    actual_md5=$(md5sum "$filename" | awk '{print $1}')
    if [[ "$actual_md5" == "$md5" ]]; then
      log_status "$name" "Downloaded" "Matched"
    else
      log_status "$name" "Downloaded" "Mismatch"
    fi
  else
    log_status "$name" "Failed to Download" "N/A"
  fi
done

# === Final Summary ===
echo -e "\nSummary written to $SUMMARY"
column -t "$SUMMARY"

