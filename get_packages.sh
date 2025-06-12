#!/bin/bash

export LFS=/mnt/lfs
umask 022

sleep 3
echo "The value of \$LFS is: $LFS"
sleep 3
echo "The umask value is: $(umask)"
sleep 3

chown root:root $LFS
chmod 755 $LFS

mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources

chown root:root $LFS/sources/*

# Define variables
FILE_URL="https://download.savannah.gnu.org/releases/acl/acl-2.3.2.tar.xz"
FILE_NAME="acl-2.3.2.tar.xz"
DEST_DIR="$LFS/sources"
CHECKSUM_EXPECTED="590765dee95907dbc3c856f7255bd669"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Check if the file already exists
if [[ -f "$DEST_DIR/$FILE_NAME" ]]; then
    echo "File already exists: $FILE_NAME. Skipping download."
else
    # Download the file
    wget -O "$DEST_DIR/$FILE_NAME" "$FILE_URL"

    # Verify download success
    if [[ -f "$DEST_DIR/$FILE_NAME" ]]; then
        echo "Download completed successfully: $FILE_NAME"
    else
        echo "Download failed. Please check the URL or network connection."
        exit 1
    fi
fi

# Calculate MD5 checksum
CHECKSUM_ACTUAL=$(md5sum "$DEST_DIR/$FILE_NAME" | awk '{print $1}')

# Validate checksum
if [[ "$CHECKSUM_ACTUAL" == "$CHECKSUM_EXPECTED" ]]; then
    echo "Checksum verification successful: File integrity confirmed."
else
    echo "Checksum verification failed: Expected $CHECKSUM_EXPECTED, but got $CHECKSUM_ACTUAL."
    exit 1
fi

exit 0

