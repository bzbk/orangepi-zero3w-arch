# Orange Pi Zero 3W · Arch Linux ARM

Orange Pi Zero 3W（Allwinner **T736**，sun60iw2 家族）的 **Arch Linux ARM (aarch64)** 镜像构建项目。

> 和 [orangepi-zero4-arch](https://github.com/bzbk/orangepi-zero4-arch)（Zero 4/A733）同一套思路：
> 厂商 U-Boot/boot0/boot_package + 厂商 BSP 内核 6.6.98-sun60iw2 + Arch Linux ARM rootfs，
> **在 ARM64 机器上原生构建**（不需要 x86 主机）——内核/U-Boot 原生编译见
> [orangepi-build-native](https://github.com/bzbk/orangepi-build-native)。

## 状态

- [x] 仓库与构建方案建立
- [x] Zero 3W 的 Debian 镜像已在真实硬件验证（用于确认内核/U-Boot/bootloader 组合可用）
- [ ] **Arch Linux ARM 镜像构建**（进行中）
- [ ] 实机启动验证

## 硬件

| 项目 | 参数 |
|---|---|
| SoC | Allwinner T736（sun60iw2 家族，8 核） |
| 内核 | vendor BSP `6.6.98-sun60iw2` |
| U-Boot | vendor v2018.05（32 位 ARM，SUNXI） |
| bootloader | `boot0_sdcard.fex` @8KiB + `boot_package.fex` @16400KiB（32MiB 分区偏移） |
| WiFi | aic8800（SDIO，**需要单独注入固件**，见 docs/KNOWN-ISSUES.md） |

## 构建路线

1. **在 ARM64 的 Debian/Ubuntu 主机上原生编译** vendor U-Boot + 内核  
   （使用 [orangepi-build-native](https://github.com/bzbk/orangepi-build-native) 的 patch）
2. 下载 **Arch Linux ARM aarch64 rootfs**（ALARM tarball），chroot 内 pacman 安装基础系统 + NetworkManager + openssh 等
3. 把内核（`Image`/`uImage`、`uInitrd`、dtb）和 U-Boot（`boot0_sdcard.fex`/`boot_package.fex`）装入 Arch 镜像
4. 镜像布局与官方一致：MBR、分区 1 起始 **LBA 65536**、boot0 @8KiB、boot_package @16400KiB
5. 注入 aic8800 固件 + 预配置 WiFi
6. 烧录到 TF 卡，在真实 Zero 3W 上启动验证

## 目录

```
scripts/    构建脚本（Debian 主机构建链）
docs/       构建计划、已知问题、调试记录
```

## 相关项目

- [orangepi-zero4-arch](https://github.com/bzbk/orangepi-zero4-arch) — Zero 4（A733）Arch 镜像
- [orangepi-build-native](https://github.com/bzbk/orangepi-build-native) — 原生 ARM64 构建 orangepi-build 的补丁集
- [orangepi-config-arch](https://github.com/bzbk/orangepi-config-arch) — 官方 orangepi-config 的 Arch 移植

## License

GPL-2.0
