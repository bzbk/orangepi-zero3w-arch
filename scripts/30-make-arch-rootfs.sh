#!/bin/bash
# Download Arch Linux ARM aarch64 rootfs and prepare it for Zero 3W.
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="${ROOTFS:-$HERE/rootfs}"
TARBALL="${TARBALL:-$HERE/ArchLinuxARM-aarch64-latest.tar.gz}"
MIRROR="${MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/os/ArchLinuxARM-aarch64-latest.tar.gz}"
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }
if [ ! -e "$ROOTFS/etc/os-release" ]; then
  [ -f "$TARBALL" ] || curl -L --fail -o "$TARBALL" "$MIRROR"
  mkdir -p "$ROOTFS"
  tar -xzf "$TARBALL" -C "$ROOTFS"
fi
# pacman sandbox fix (vendor kernel has no Landlock)
grep -q '^DisableSandbox' "$ROOTFS/etc/pacman.conf" || sed -i '/^\[options\]/a DisableSandbox' "$ROOTFS/etc/pacman.conf"
cp -f /etc/resolv.conf "$ROOTFS/etc/resolv.conf"
for d in proc dev sys; do mkdir -p "$ROOTFS/$d"; mountpoint -q "$ROOTFS/$d" || mount --bind "/$d" "$ROOTFS/$d"; done
chroot "$ROOTFS" /bin/bash -c '
  set -e
  pacman-key --init >/dev/null 2>&1 || true
  pacman-key --populate archlinuxarm >/dev/null 2>&1 || true
  pacman -Syu --noconfirm
  pacman -S --noconfirm --needed networkmanager openssh sudo nano vim htop git zstd \
    e2fsprogs dosfstools mtools wpa_supplicant avahi nss-mdns
  systemctl enable NetworkManager sshd
  echo "orangepizero3w" > /etc/hostname
  id orangepi >/dev/null 2>&1 || useradd -m -G wheel -s /bin/bash orangepi
  echo "orangepi:orangepi" | chpasswd
  echo "root:orangepi" | chpasswd
  echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/10-wheel
  chmod 440 /etc/sudoers.d/10-wheel
'
for d in proc dev sys; do umount "$ROOTFS/$d" 2>/dev/null || true; done
echo "==> Arch rootfs ready at $ROOTFS"
