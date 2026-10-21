#!/bin/bash
# Assemble the final Zero 3W Arch image: MBR (partition @LBA 65536), boot0 @8KiB,
# boot_package @16400KiB, /boot with uImage + uInitrd + dtb + boot.scr.
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$HERE/orangepi-build}"
ROOTFS="${ROOTFS:-$HERE/rootfs}"
OUT="${OUT:-$HERE/output/arch-zero3w.img}"
VENDOR_IMAGE="${VENDOR_IMAGE:-}"     # optional validated vendor Debian image for boot.scr/orangepiEnv.txt
DEBS="$WORK/output/debs"
BOOT0="$HERE/artifacts/boot0_sdcard.fex"
BOOTPKG="$HERE/artifacts/boot_package.fex"
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }
mkdir -p "$(dirname "$OUT")" "$HERE/artifacts" "$HERE/build"

# 1) extract kernel/u-boot from debs
KDEB=$(ls "$DEBS"/linux-image-current-sun60iw2_*.deb | head -1)
DTBDEB=$(ls "$DEBS"/linux-dtb-current-sun60iw2_*.deb | head -1)
UBDEB=$(ls "$DEBS"/linux-u-boot-current-orangepizero3w_*.deb | head -1)
rm -rf "$HERE/build/kernel" "$HERE/build/uboot"; mkdir -p "$HERE/build/kernel" "$HERE/build/uboot"
dpkg-deb -x "$KDEB" "$HERE/build/kernel"
dpkg-deb -x "$DTBDEB" "$HERE/build/kernel"
dpkg-deb -x "$UBDEB" "$HERE/build/uboot"

# 2) boot0 / boot_package (from u-boot deb install payload)
find "$HERE/build/uboot" -name 'boot0_sdcard.fex' -exec cp -f {} "$BOOT0" \;
find "$HERE/build/uboot" -name 'boot_package.fex' -exec cp -f {} "$BOOTPKG" \;

# 3) uImage + uInitrd (legacy ARM format, load/entry 0x41000000)
KVER=6.6.98-sun60iw2
KIMG=$(find "$HERE/build/kernel" -path '*/boot/*' \( -name 'Image' -o -name 'vmlinuz-*' -o -name 'vmlinuz' \) | head -1)
[ -n "$KIMG" ] || { echo "kernel Image not found"; exit 1; }
mkimage -A arm -O linux -T kernel -C none -a 0x41000000 -e 0x41000000 \
  -n "Linux-$KVER" -d "$KIMG" "$HERE/build/uImage"
# initramfs inside the Arch rootfs chroot
for d in proc dev sys; do mkdir -p "$ROOTFS/$d"; mountpoint -q "$ROOTFS/$d" || mount --bind "/$d" "$ROOTFS/$d"; done
chroot "$ROOTFS" /bin/bash -c "mkinitcpio -k $KVER -g /boot/initramfs-linux.img" || \
  echo "WARN: mkinitcpio failed (check /etc/mkinitcpio.conf MODULES for sun60iw2)"
gzip -c "$ROOTFS/boot/initramfs-linux.img" > "$HERE/build/initramfs.gz"
mkimage -A arm -O linux -T ramdisk -C gzip -n initrd -d "$HERE/build/initramfs.gz" "$HERE/build/uInitrd"
for d in proc dev sys; do umount "$ROOTFS/$d" 2>/dev/null || true; done

# 4) boot files (boot.scr, orangepiEnv.txt, dtb)
DTB=$(find "$HERE/build/kernel" -name 'sun60i-a733-orangepi-zero3w.dtb' | head -1)
mkdir -p "$ROOTFS/boot/dtb/allwinner"
cp -f "$DTB" "$ROOTFS/boot/dtb/allwinner/"
cp -f "$HERE/build/uImage" "$HERE/build/uInitrd" "$ROOTFS/boot/"
if [ -n "$VENDOR_IMAGE" ] && [ -f "$VENDOR_IMAGE" ]; then
  M=$(mktemp -d); mount -o loop,ro,offset=$((65536*512)) "$VENDOR_IMAGE" "$M"
  cp -f "$M/boot/boot.scr" "$M/boot/boot.cmd" "$M/boot/orangepiEnv.txt" "$ROOTFS/boot/" 2>/dev/null || true
  umount "$M"; rmdir "$M"
fi

# 5) aic8800 firmware (copy from /lib/firmware on the build host if present)
if [ -d /lib/firmware/aic8800d80 ] && [ ! -d "$ROOTFS/lib/firmware/aic8800d80" ]; then
  mkdir -p "$ROOTFS/lib/firmware/aic8800d80"
  cp -f /lib/firmware/aic8800d80/* "$ROOTFS/lib/firmware/aic8800d80/" || true
fi

# 6) image layout: 32MiB offset, ext4, copy rootfs
SIZE_MB=$(( ($(du -sm "$ROOTFS" | cut -f1) + 256) ))
truncate -s "$((32*1024*1024 + SIZE_MB*1024*1024))" "$OUT"
parted -s "$OUT" mklabel msdos mkpart primary ext4 32MiB 100%
LOOP=$(losetup -f --show -P "$OUT")
mkfs.ext4 -q -L rootfs "${LOOP}p1"
M=$(mktemp -d); mount "${LOOP}p1" "$M"
rsync -aHAX --numeric-ids "$ROOTFS"/ "$M"/
umount "$M"; rmdir "$M"; losetup -d "$LOOP"

# 7) bootloader
[ -f "$BOOT0" ] && dd if="$BOOT0" of="$OUT" bs=1024 seek=8 conv=fsync,notrunc status=none
[ -f "$BOOTPKG" ] && dd if="$BOOTPKG" of="$OUT" bs=1024 seek=16400 conv=fsync,notrunc status=none
sha256sum "$OUT" > "$OUT.sha256"
echo "==> Image: $OUT"; cat "$OUT.sha256"
