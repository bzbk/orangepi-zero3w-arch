#!/bin/bash
# Install build dependencies on an ARM64 Debian/Ubuntu host (native build host).
set -e
[ "$(id -u)" -eq 0 ] || { echo "run as root: sudo $0"; exit 1; }
[ "$(uname -m)" = "aarch64" ] || { echo "this project builds natively on aarch64"; exit 1; }
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential bc bison flex libssl-dev libncurses-dev libelf-dev device-tree-compiler \
  git curl wget rsync python3 python3-dev swig zstd xz-utils file \
  debootstrap qemu-user-static binfmt-support gcc-arm-linux-gnueabi \
  parted dosfstools mtools u-boot-tools kmod bc ccache cpio \
  e2fsprogs f2fs-tools p7zip-full
echo "==> Build dependencies installed."
