#!/bin/bash

# === Set LFS Environment ===
export LFS=/mnt/lfs

# Create sources dir and set permissions
mkdir -pv $LFS/sources
chmod -v a+wt $LFS/sources

# === Working Directory & Summary ===
DOWNLOAD_DIR="$LFS/sources"
SUMMARY="$LFS/download_summary.txt"

mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR" || exit 1
echo -e "Package\t\t\tStatus\t\t\tChecksum Match" > "$SUMMARY"

# === Function to log results ===
log_status() {
  local name=$1
  local status=$2
  local checksum=$3
  printf "%-20s %-24s %-20s\n" "$name" "$status" "$checksum" >> "$SUMMARY"
}

# === Package Data (name|url|md5) ===
packages=$(
cat <<EOF
Acl|https://download.savannah.gnu.org/releases/acl/acl-2.3.2.tar.xz|590765dee95907dbc3c856f7255bd669
Attr|https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.gz|227043ec2f6ca03c0948df5517f9c927
Autoconf|https://ftp.gnu.org/gnu/autoconf/autoconf-2.72.tar.xz|1be79f7106ab6767f18391c5e22be701
Automake|https://ftp.gnu.org/gnu/automake/automake-1.17.tar.xz|7ab3a02318fee6f5bd42adfc369abf10
Bash|https://ftp.gnu.org/gnu/bash/bash-5.2.37.tar.gz|9c28f21ff65de72ca329c1779684a972
Bc|https://github.com/gavinhoward/bc/releases/download/7.0.3/bc-7.0.3.tar.xz|ad4db5a0eb4fdbb3f6813be4b6b3da74
Binutils|https://sourceware.org/pub/binutils/releases/binutils-2.44.tar.xz|49912ce774666a30806141f106124294
Bison|https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz|c28f119f405a2304ff0a7ccdcc629713
Bzip2|https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz|67e051268d0c475ea773822f7500d0e5
Coreutils|https://ftp.gnu.org/gnu/coreutils/coreutils-9.6.tar.xz|0ed6cc983fe02973bc98803155cc1733
Gawk|https://ftp.gnu.org/gnu/gawk/gawk-5.3.1.tar.xz|4e9292a06b43694500e0620851762eec
GCC|https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz|2268420ba02dc01821960e274711bde0
Make|https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz|c8469a3713cbbe04d955d4ae4be23eeb
Perl|https://www.cpan.org/src/5.0/perl-5.40.1.tar.xz|bab3547a5cdf2302ee0396419d74a42e
Sed|https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz|6aac9b2dbafcd5b7a67a8a9bcb8036c3
Tar|https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz|a2d8042658cfd8ea939e6d911eaf4152
Xz-Utils|https://github.com//tukaani-project/xz/releases/download/v5.6.4/xz-5.6.4.tar.xz|4b1cf07d45ec7eb90a01dd3c00311a3e
Zlib|https://zlib.net/fossils/zlib-1.3.1.tar.gz|9855b6d802d7fe5b7bd5b196a2271655
EOF
)

# === Main Processing Loop ===
echo "$packages" | while IFS='|' read -r name url md5; do
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

