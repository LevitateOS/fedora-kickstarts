# levitate-live.ks
# Flattened kickstart for LevitateOS live ISO
# Based on fedora-live-base.ks

lang en_US.UTF-8
keyboard us
timezone US/Eastern
selinux --enforcing
firewall --enabled --service=mdns
zerombr
clearpart --all
part / --size 5120 --fstype ext4
services --enabled=NetworkManager --disabled=sshd
network --bootproto=dhcp --device=link --activate
rootpw --plaintext root
shutdown

# Repo config (from fedora-repo-not-rawhide.ks)
repo --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch
url --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch

%packages
kernel
kernel-modules
kernel-modules-extra

# Required for live boot
dracut-live
livesys-scripts

# Basic shell environment
bash
coreutils
util-linux
systemd

# Networking
NetworkManager

# Bootloader (required for ISO creation)
grub2-pc
grub2-pc-modules
grub2-efi-x64
grub2-efi-x64-modules
grub2-efi-x64-cdboot
shim-x64
syslinux
syslinux-nonlinux

# Exclude bloat
-fcoe-utils
-device-mapper-multipath
-sdubby
%end

%post
# LevitateOS Branding
cat > /etc/os-release << EOF
NAME="LevitateOS"
VERSION="1.0"
ID=levitate
ID_LIKE=fedora
VERSION_ID=1
PRETTY_NAME="LevitateOS 1.0"
HOME_URL="https://github.com/LevitateOS"
EOF

cat > /etc/issue << EOF
LevitateOS 1.0
Kernel \r on \m (\l)

Login: root (no password)

Run: levitate-installer    - Interactive installer
     Manual install guide: https://levitateos.org/manual

EOF

echo "LevitateOS release 1.0" > /etc/system-release

# Enable livesys services
systemctl enable livesys.service
systemctl enable livesys-late.service

# enable tmpfs for /tmp
systemctl enable tmp.mount

# Dev shared folder (auto-mount when running in QEMU with virtio-9p)
mkdir -p /mnt/share
cat > /etc/systemd/system/mnt-share.mount << EOF
[Unit]
Description=QEMU Shared Folder
ConditionVirtualization=qemu

[Mount]
What=share
Where=/mnt/share
Type=9p
Options=trans=virtio

[Install]
WantedBy=multi-user.target
EOF
systemctl enable mnt-share.mount

# Alias for installer binary
ln -s /mnt/share/target/release/levitate-installer /usr/local/bin/levitate-installer

# make it so that we don't do writing to the overlay for things which
# are just tmpdirs/caches
cat >> /etc/fstab << EOF
vartmp   /var/tmp    tmpfs   defaults   0  0
EOF

# work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
echo "Packages within this LiveCD"
rpm -qa --qf '%{size}\t%{name}-%{version}-%{release}.%{arch}\n' |sort -rn
rm -f /var/lib/rpm/__db*

# go ahead and pre-make the man -k cache
/usr/bin/mandb

# make sure there aren't core files lying around
rm -f /core*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

echo 'File created by kickstart. See systemd-update-done.service(8).' \
    | tee /etc/.updated >/var/.updated

# Drop the rescue kernel and initramfs
rm -f /boot/*-rescue*

# Disable network service here
systemctl disable network

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

%end
