#!/bin/bash

# Define LFS root
export LFS=/mnt/lfs

echo "==> Creating base directory layout in \$LFS"
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done
case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac

echo "==> Creating tools directory"
mkdir -pv $LFS/tools

echo "==> Creating lfs group and user"
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
echo "Logos2025!" | passwd --stdin lfs 2>/dev/null || echo "lfs:Logos2025!" | chpasswd

echo "==> Assigning ownership of LFS directories to lfs user"
chown -v lfs $LFS/{usr{,/*},var,etc,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac

echo "==> Moving /etc/bash.bashrc if present to prevent contamination"
[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

echo "==> Switching to user lfs to create environment files"

su - lfs <<'EOF'
# Create .bash_profile
cat > ~/.bash_profile << "EOP"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOP

# Create .bashrc
cat > ~/.bashrc << "EOR"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOR

# Add parallel make setting
cat >> ~/.bashrc << "EOM"
export MAKEFLAGS=-j$(nproc)
EOM

# Source profile to activate the environment
source ~/.bash_profile
EOF

echo "✅ groundwork.sh completed."

