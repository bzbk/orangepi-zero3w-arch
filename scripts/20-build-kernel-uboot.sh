#!/bin/bash
# Build vendor U-Boot + kernel natively (produces .deb artifacts in output/debs).
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$HERE/orangepi-build}"
cd "$WORK"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
# u-boot (32-bit ARM, needs arm-linux-gnueabi- from apt)
./build.sh BOARD=orangepizero3w BRANCH=current RELEASE=bookworm BUILD_OPT=u-boot \
  BUILD_DESKTOP=no BUILD_MINIMAL=no KERNEL_CONFIGURE=no
# kernel (native aarch64)
./build.sh BOARD=orangepizero3w BRANCH=current RELEASE=bookworm BUILD_OPT=kernel \
  BUILD_DESKTOP=no BUILD_MINIMAL=no KERNEL_CONFIGURE=no
echo "==> debs in $WORK/output/debs/"
ls -lh "$WORK"/output/debs/*.deb
