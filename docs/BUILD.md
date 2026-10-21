# Zero 3W Arch Linux ARM 构建手册

目标：在 **ARM64 Debian/Ubuntu 主机**（测试机为 Zero 3W 自己，Debian 12 bookworm, 8 核/3.8G）
上原生构建可启动的 Arch Linux ARM 镜像。

## 0. 前置

- ARM64 主机，≥ 20 GB 空闲磁盘，建议 ≥ 4 GB RAM + 8 GB swap
- 主机是 Debian/Ubuntu（orangepi-build 需要 `dpkg`/`apt`）
- 网络能访问：GitHub（源码）、archlinuxarm.org（rootfs）、Orange Pi 源（内核/U-Boot）

## 1. 原生编译 U-Boot + 内核

```bash
sudo ./scripts/00-setup-builder.sh
./scripts/10-fetch-build.sh            # clone orangepi-build + 应用 native-arm64 patch
./scripts/20-build-kernel-uboot.sh     # BUILD_OPT=u-boot / kernel
```

产物（`output/debs/`）：

- `linux-image-current-sun60iw2_*.deb`（内核 Image + modules）
- `linux-dtb-current-sun60iw2_*.deb`（含 `sun60i-a733-orangepi-zero3w.dtb`）
- `linux-u-boot-current-orangepizero3w_*.deb`（含 boot0/boot_package/安装脚本）

## 2. Arch rootfs

```bash
sudo ./scripts/30-make-arch-rootfs.sh
```

- 下载 `ArchLinuxARM-aarch64-latest.tar.gz`
- chroot 内：pacman 基础系统、NetworkManager、openssh、vim 等
- 设置 hostname `orangepizero3w`、默认用户 `orangepi/orangepi`、启用 sshd/NetworkManager

## 3. 组装镜像

```bash
sudo ./scripts/40-assemble-image.sh
```

- 从内核 deb 取 `Image`/dtb，生成 `uImage`/`uInitrd`（ARM legacy 格式，load/entry `0x41000000`）
- 从 U-Boot deb 取 `boot0_sdcard.fex`/`boot_package.fex`，写 8KiB / 16400KiB
- 复制 `boot.scr`、`orangepiEnv.txt`、dtb 到 `/boot`
- 注入 aic8800 固件（`aic8800d80/`）
- 输出 `output/arch-zero3w.img` + SHA256

## 4. 烧录验证

```bash
sudo dd if=output/arch-zero3w.img of=/dev/sdX bs=4M status=progress conv=fsync
```

串口 UART0 115200 8N1，检查 U-Boot → boot.scr → 内核 → Arch systemd → 登录。

## 已知坑（来自 Zero 4 经验）

1. **uImage 必须 `mkimage -A arm`（0x02）**，不是 arm64；load/entry `0x41000000`
2. initramfs 必须是 gzip cpio（含 `TRAILER!!!`），`mkinitcpio -z cat` 后 gzip
3. boot0 必须用**官方 258,048 字节**版本（header length 0x3F000）
4. vendor U-Boot 2018 的 boot.scr 会去 `ext4load ... /boot/uImage`，注意文件命名
5. vendor U-Boot 在 `Hit any key` 阶段被串口守护进程写入会中断 autoboot
6. T736 的 WiFi 固件 aic8800 不在 orangepi-firmware deb 里，必须注入

## 实际构建记录（2026-10-21，在 Orange Pi Zero 4 上原生构建）

- 源码：orangepi-build @ a05b3b4 + `patches/native-arm64.patch`
- U-Boot：`linux-u-boot-current-orangepizero3w_1.0.2_arm64.deb`（armhf 交叉编译，含 boot0/boot_package）
- 内核：`linux-image-current-sun60iw2_1.0.2_arm64.deb`（原生 aarch64，Image 26 MB）
- rootfs：ArchLinuxARM-aarch64-latest（tarball 791 MB），pacman -Syu + NetworkManager/openssh 等
- initramfs：`mkinitcpio -k 6.6.98-sun60iw2`（mmc/ext4 为内核内建，initramfs 未带模块也可启动）
- 镜像：2.8 GiB，SHA256 `720627cdc57bd07adaa1a9767eda42ad15fe6592c7456ccfc08a08110d6d11f9`
- `/boot`：Image / uImage / uInitrd / initramfs-sun60iw2.img / boot.scr / boot.cmd / orangepiEnv.txt / dtb/allwinner
- 预配置：hostname `orangepizero3w`、用户 `orangepi/orangepi`（wheel）、sshd + NetworkManager、
  WiFi `GoforLib` 自动连接、aic8800 固件、pad 的 SSH 公钥
