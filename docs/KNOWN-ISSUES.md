# Known issues

## 1. aic8800 WiFi 固件缺失（T736 / Zero 3W）

上游 `orangepi-firmware` deb 不含 `/lib/firmware/aic8800d80/*`，导致
`aicbsp_sdio_probe` 失败、没有 `wlan0`。构建镜像时必须注入固件
（可从官方 Zero 4/Zero 3W 镜像或 linux-firmware 获取）。

## 2. 串口写入会打断 U-Boot autoboot

U-Boot 在 `Hit any key to stop autoboot` 阶段任何串口输入都会停止自动启动。
若主机上的串口守护进程（如灯控）探测 `/dev/ttyUSB*` 并写字符，板子会停在
U-Boot `=>`。用 udev 把 CH340 限制为 root 0600：

```
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0600", GROUP="root"
```

## 3. vendor U-Boot 是 32 位 ARM

`sun60iw2` 家族 U-Boot 编译需要 `arm-linux-gnueabi-`（armhf 交叉工具链），
即使在 ARM64 主机上也是如此；内核才是原生 aarch64 编译。
