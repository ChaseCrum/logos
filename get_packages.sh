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

# === Colors ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# === Function to log results ===
log_status() {
  local name=$1
  local status=$2
  local checksum=$3
  printf "%-20s %-24s %-20s\n" "$name" "$status" "$checksum" >> "$SUMMARY"
}

# === Retry Function ===
download_with_retry() {
  local url=$1
  local filename=$2
  local retries=5
  local delay=10

  for ((i=1; i<=retries; i++)); do
    echo -e "${YELLOW}Attempt $i to download $filename...${NC}"
    wget --show-progress "$url" && return 0
    echo -e "${RED}Download attempt $i for $filename failed.${NC}"
    sleep $delay
  done

  return 1
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
Check|https://github.com/libcheck/check/releases/download/0.15.2/check-0.15.2.tar.gz|50fcafcecde5a380415b12e9c574e0b2
Coreutils|https://ftp.gnu.org/gnu/coreutils/coreutils-9.6.tar.xz|0ed6cc983fe02973bc98803155cc1733
DejaGNU|https://ftp.gnu.org/gnu/dejagnu/dejagnu-1.6.3.tar.gz|68c5208c58236eba447d7d6d1326b821
Diffutils|https://ftp.gnu.org/gnu/diffutils/diffutils-3.11.tar.xz|75ab2bb7b5ac0e3e10cece85bd1780c2
E2fsprogs|https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.47.2/e2fsprogs-1.47.2.tar.gz|752e5a3ce19aea060d8a203f2fae9baa
Elfutils|https://sourceware.org/ftp/elfutils/0.192/elfutils-0.192.tar.bz2|a6bb1efc147302cfc15b5c2b827f186a
Expat|https://prdownloads.sourceforge.net/expat/expat-2.7.1.tar.xz|9f0c266ff4b9720beae0c6bd53ae4469
Expect|https://prdownloads.sourceforge.net/expect/expect5.45.4.tar.gz|00fce8de158422f5ccd2666512329bd2
File|https://astron.com/pub/file/file-5.46.tar.gz|459da2d4b534801e2e2861611d823864
Findutils|https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz|870cfd71c07d37ebe56f9f4aaf4ad872
Flex|https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz|2882e3179748cc9f9c23ec593d6adc8d
Flit-core|https://pypi.org/packages/source/f/flit-core/flit_core-3.11.0.tar.gz|6d677b1acef1769c4c7156c7508e0dbd
Gawk|https://ftp.gnu.org/gnu/gawk/gawk-5.3.1.tar.xz|4e9292a06b43694500e0620851762eec
GCC|https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz|2268420ba02dc01821960e274711bde0
GDBM|https://ftp.gnu.org/gnu/gdbm/gdbm-1.24.tar.gz|c780815649e52317be48331c1773e987
Gettext|https://ftp.gnu.org/gnu/gettext/gettext-0.24.tar.xz|87aea3013802a3c60fa3feb5c7164069
Glibc|https://ftp.gnu.org/gnu/glibc/glibc-2.41.tar.xz|19862601af60f73ac69e067d3e9267d4
GMP|https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz|956dc04e864001a9c22429f761f2c283
Gperf|https://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz|9e251c0a618ad0824b51117d5d9db87e
Grep|https://ftp.gnu.org/gnu/grep/grep-3.11.tar.xz|7c9bbd74492131245f7cdb291fa142c0
Groff|https://ftp.gnu.org/gnu/groff/groff-1.23.0.tar.gz|5e4f40315a22bb8a158748e7d5094c7d
GRUB|https://ftp.gnu.org/gnu/grub/grub-2.12.tar.xz|60c564b1bdc39d8e43b3aab4bc0fb140
Gzip|https://ftp.gnu.org/gnu/gzip/gzip-1.13.tar.xz|d5c9fc9441288817a4a0be2da0249e29
Iana-Etc|https://github.com/Mic92/iana-etc/releases/download/20250123/iana-etc-20250123.tar.gz|f8a0ebdc19a5004cf42d8bdcf614fa5d
Inetutils|https://ftp.gnu.org/gnu/inetutils/inetutils-2.6.tar.xz|401d7d07682a193960bcdecafd03de94
Intltool|https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz|12e517cac2b57a0121cda351570f1e63
IPRoute2|https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-6.13.0.tar.xz|1603d25120d03feeaba9b360d03ffaec
Jinja2|https://pypi.org/packages/source/J/Jinja2/jinja2-3.1.5.tar.gz|083d64f070f6f1b5f75971ae60240785
Kbd|https://www.kernel.org/pub/linux/utils/kbd/kbd-2.7.1.tar.xz|f15673d9f748e58f82fa50cff0d0fd20
Kmod|https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-34.tar.xz|3e6c5c9ad9c7367ab9c3cc4f08dfde62
Less|https://www.greenwoodsoftware.com/less/less-668.tar.gz|d72760386c5f80702890340d2f66c302
LFS-Bootscripts|https://www.linuxfromscratch.org/lfs/downloads/12.3/lfs-bootscripts-20240825.tar.xz|7b078c594a77e0f9cd53a0027471c3bc
Libcap|https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.73.tar.xz|0e186df9de9b1e925593a96684fe2e32
Libffi|https://github.com/libffi/libffi/releases/download/v3.4.7/libffi-3.4.7.tar.gz|696a1d483a1174ce8a477575546a5284
Libpipeline|https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.8.tar.gz|17ac6969b2015386bcb5d278a08a40b5
Libtool|https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.xz|22e0a29df8af5fdde276ea3a7d351d30
Libxcrypt|https://github.com/besser82/libxcrypt/releases/download/v4.4.38/libxcrypt-4.4.38.tar.xz|1796a5d20098e9dd9e3f576803c83000
Linux|https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.13.4.tar.xz|13b9e6c29105a34db4647190a43d1810
Lz4|https://github.com/lz4/lz4/releases/download/v1.10.0/lz4-1.10.0.tar.gz|dead9f5f1966d9ae56e1e32761e4e675
M4|https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz|0d90823e1426f1da2fd872df0311298d
Make|https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz|c8469a3713cbbe04d955d4ae4be23eeb
Man-DB|https://download.savannah.gnu.org/releases/man-db/man-db-2.13.0.tar.xz|97ab5f9f32914eef2062d867381d8cee
Man-pages|https://www.kernel.org/pub/linux/docs/man-pages/man-pages-6.12.tar.xz|44de430a598605eaba3e36dd43f24298
MarkupSafe|https://pypi.org/packages/source/M/MarkupSafe/markupsafe-3.0.2.tar.gz|cb0071711b573b155cc8f86e1de72167
Meson|https://github.com/mesonbuild/meson/releases/download/1.7.0/meson-1.7.0.tar.gz|c20f3e5ebbb007352d22f4fd6ceb925c
MPC|https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz|5c9bc658c9fd0f940e8e3e0f09530c62
MPFR|https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.xz|523c50c6318dde6f9dc523bc0244690a
Ncurses|https://invisible-mirror.net/archives/ncurses/ncurses-6.5.tar.gz|ac2d2629296f04c8537ca706b6977687
Ninja|https://github.com/ninja-build/ninja/archive/v1.12.1/ninja-1.12.1.tar.gz|6288992b05e593a391599692e2f7e490
OpenSSL|https://github.com/openssl/openssl/releases/download/openssl-3.4.1/openssl-3.4.1.tar.gz|fb7a747ac6793a7ad7118eaba45db379
Patch|https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz|78ad9937e4caadcba1526ef1853730d5
Perl|https://www.cpan.org/src/5.0/perl-5.40.1.tar.xz|bab3547a5cdf2302ee0396419d74a42e
Pkgconf|https://distfiles.ariadne.space/pkgconf/pkgconf-2.3.0.tar.xz|833363e77b5bed0131c7bc4cc6f7747b
Procps|https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.5.tar.xz|90803e64f51f192f3325d25c3335d057
Psmisc|https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.7.tar.xz|53eae841735189a896d614cba440eb10
Python|https://www.python.org/ftp/python/3.13.2/Python-3.13.2.tar.xz|4c2d9202ab4db02c9d0999b14655dfe5
Readline|https://ftp.gnu.org/gnu/readline/readline-8.2.13.tar.gz|05080bf3801e6874bb115cd6700b708f
Sed|https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz|6aac9b2dbafcd5b7a67a8a9bcb8036c3
Setuptools|https://pypi.org/packages/source/s/setuptools/setuptools-75.8.1.tar.gz|7dc3d3f529b76b10e35326e25c676b30
Shadow|https://github.com/shadow-maint/shadow/releases/download/4.17.3/shadow-4.17.3.tar.xz|0da190e53ecee76237e4c8f3f39531ed
Sysklogd|https://github.com/troglobit/sysklogd/releases/download/v2.7.0/sysklogd-2.7.0.tar.gz|611c0fa5c138eb7a532f3c13bdf11ebc
Systemd|https://github.com/systemd/systemd/archive/v257.3/systemd-257.3.tar.gz|8e4fc90c7aead651fa5c50bd1b34abc2
SysVinit|https://github.com/slicer69/sysvinit/releases/download/3.14/sysvinit-3.14.tar.xz|bc6890b975d19dc9db42d0c7364dd092
Tar|https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz|a2d8042658cfd8ea939e6d911eaf4152
Tcl|https://downloads.sourceforge.net/tcl/tcl8.6.16-src.tar.gz|eaef5d0a27239fb840f04af8ec608242
Texinfo|https://ftp.gnu.org/gnu/texinfo/texinfo-7.2.tar.xz|11939a7624572814912a18e76c8d8972
Util-linux|https://www.kernel.org/pub/linux/utils/util-linux/v2.40/util-linux-2.40.4.tar.xz|f9cbb1c8315d8ccbeb0ec36d10350304
Vim|https://github.com/vim/vim/archive/v9.1.1166/vim-9.1.1166.tar.gz|718d43ce957ab7c81071793de176c2eb
Wheel|https://pypi.org/packages/source/w/wheel/wheel-0.45.1.tar.gz|dddc505d0573d03576c7c6c5a4fe0641
XML::Parser|https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.47.tar.gz|89a8e82cfd2ad948b349c0a69c494463
Zlib|https://zlib.net/fossils/zlib-1.3.1.tar.gz|9855b6d802d7fe5b7bd5b196a2271655
Zstd|https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz|780fc1896922b1bc52a4e90980cdda48
EOF
)

# === Main Processing Loop ===
echo "$packages" | while IFS='|' read -r name url md5; do
  filename=$(basename "$url")
  echo -e "${YELLOW}Processing $name → $filename${NC}"

  if [[ -f "$filename" ]]; then
    echo "→ Already exists. Verifying checksum..."
    actual_md5=$(md5sum "$filename" | awk '{print $1}')
    if [[ "$actual_md5" == "$md5" ]]; then
      echo -e "${GREEN}→ Checksum matches. Skipping download.${NC}"
      log_status "$name" "Already Present" "Matched"
      continue
    else
      echo -e "${RED}→ Checksum mismatch. Removing and retrying download...${NC}"
      rm -f "$filename"
    fi
  fi

  echo -e "${YELLOW}→ Downloading $filename...${NC}"
  if download_with_retry "$url" "$filename"; then
    actual_md5=$(md5sum "$filename" | awk '{print $1}')
    if [[ "$actual_md5" == "$md5" ]]; then
      echo -e "${GREEN}→ Downloaded and checksum matched.${NC}"
      log_status "$name" "Downloaded" "Matched"
    else
      echo -e "${RED}→ Checksum mismatch after download!${NC}"
      log_status "$name" "Downloaded" "Mismatch"
    fi
  else
    echo -e "${RED}→ Failed to download $filename after retries.${NC}"
    log_status "$name" "Failed to Download" "N/A"
  fi
done

# === Final Summary ===
echo -e "\nSummary written to $SUMMARY"
column -t "$SUMMARY"