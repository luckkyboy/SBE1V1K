# SBE1V1K HTTP U-Boot / Chainloader 使用说明

来源：[YYH2913/http-uboot 的 sbe1v1k 分支](https://github.com/YYH2913/http-uboot/tree/sbe1v1k)。它不是用来替换 eMMC `boot0`/`boot1` 中原厂启动链的普通完整 U-Boot，而是由原厂 `bootm` 临时启动、之后可安装到 eMMC 用户区的二阶段 U-Boot chainloader，并提供 HTTP 备份、GPT 迁移和 OpenWrt 恢复界面。

> 这是第三方、破坏性较强的可选方案，不是 OpenWrt PR #21586 的上游安装流程。只想保持官方 PR 的 mainline 分区时，可以完全不安装它，继续使用 initramfs + `fw_setenv` + `sysupgrade` 路径。

## 1. 应使用哪个文件

已核对的 GitHub Release：[`260720`](https://github.com/YYH2913/http-uboot/releases/tag/260720)

```text
文件：sbe1v1k-chainloader.itb
大小：758532 bytes
SHA-256：2aad05c1ee2574874a4570367a090ebf9af66cc02d23db91365ed0b83ef5d702
下载：https://github.com/YYH2913/http-uboot/releases/download/260720/sbe1v1k-chainloader.itb
```

下载后必须验证：

```bash
echo '2aad05c1ee2574874a4570367a090ebf9af66cc02d23db91365ed0b83ef5d702  sbe1v1k-chainloader.itb' | sha256sum -c -
```

文件用途不能互换：

| 文件 | 用途 |
|---|---|
| `sbe1v1k-chainloader.itb` | 原厂 U-Boot TFTP 临时启动；HTTP Chainloader 页面升级也用它 |
| `sbe1v1k-chainloader-partition.img` | 仅限外接 eMMC 读卡器离线修复正确分区 |
| `u-boot.bin` | 二阶段内部 payload，**绝不能直接 bootm 或写入 eMMC** |
| `*-hlos.elf`、`*-shim.bin`、`*-control.dtb` | 检查/构建中间文件，不直接刷写 |

绝不能把 chainloader 写入 `0:HLOS`、`0:HLOS_1`、`boot0` 或 `boot1`。

## 2. 首次临时启动

首次仍需按设备 PR 的方法拆机、连接 1.8 V 串口并通过 eMMC glitch 得到原厂 U-Boot 提示符。PC 设置 `192.168.1.2/24`，把已校验的 ITB 放进 TFTP 根目录。

原厂 U-Boot 只执行临时命令：

```text
setenv ipaddr 192.168.1.1
setenv serverip 192.168.1.2
tftpboot 0x80000000 sbe1v1k-chainloader.itb
bootm 0x80000000
```

**不要执行 `saveenv`。** 此时 chainloader 只在 RAM 中运行，还没有写入 eMMC。

## 3. 先用 HTTP 页面备份

二阶段 U-Boot 若没有可启动固件可能自动进入恢复；也可在其命令行执行：

```text
http_recovery
```

PC 改为 DHCP，或静态设置 `192.168.255.2/24`、不填网关，然后访问：

```text
http://192.168.255.1/
```

先在 Backup 页面执行 **Download all (.tar)**。必须至少保存：

- eMMC `boot0`、`boot1`；
- GPT 分区 `p1` 到 `p26`；
- 下载文件的 SHA-256，并复制到另一块物理磁盘。

该 tar 是分区级备份，不含 eMMC 用户区 GPT 头、未分配扇区和 RPMB。真正完整的扇区级灾难恢复仍需外接 eMMC 读卡器备份整个 user area、boot0 和 boot1。

## 4. 分区模式选择

HTTP 页面提供：

- `mainline`：使用 `0:HLOS`、`rootfs`、`rootfs_data`，保留 `/dev/mmcblk0p27` 约定；与本仓库 OpenWrt 设备定义最接近，推荐选择。
- `large`：创建 4 MiB `chainloader`、32 MiB `kernel`、1 GiB `rootfs` 和约 6.2 GiB `rootfs_data`；这是第三方重分区布局，不属于当前 OpenWrt 上游设备 PR。

对本仓库的第一轮实机验证建议只用 `mainline`。不要为了扩大 overlay 在尚未验证恢复能力时选择 `large`。

选择布局后输入确认词：

```text
SBE1V1K_REPARTITION
```

这会重写 GPT 尾部、安装当前正在运行的 chainloader FIT，并更新 `0:APPSBLENV`。完成后不要断电或重启，必须立即上传匹配布局的 OpenWrt 固件。

## 5. 通过 HTTP 安装本仓库 OpenWrt

在 Firmware 页面上传本仓库生成的：

```text
openwrt-qualcommbe-ipq95xx-askey_sbe1v1k-squashfs-sysupgrade.bin
```

虽然扩展名为 `.bin`，该文件实际是包含 `kernel` 和 `root` 成员的 sysupgrade tar。HTTP U-Boot 会流式解析并写入当前 profile 的 kernel/rootfs，随后清空 `rootfs_data`。

上传并非原子操作：服务器会先擦除目标分区，断电、浏览器中断或错误镜像都会让当前系统不可启动。保持串口、网线、浏览器和稳定电源直到写入完成并自动重启。

不要在这个流程中再执行上游 PR 的三条 `fw_setenv` 安装命令；chainloader 的布局迁移会管理它需要的 `0:APPSBLENV`。两种安装流程应二选一，不能在中途混用。

## 6. 后续更新

- 更新 OpenWrt：进入 `http_recovery`，Firmware 页面上传 sysupgrade tar。
- 更新 chainloader：Chainloader 页面只上传原始 `sbe1v1k-chainloader.itb`；`mainline` 自动写 `rsvd_2`，`large` 自动写 `chainloader`。
- HTTP 页面 chainloader 上限为 4 MiB，不能上传 `u-boot.bin`、OpenWrt 固件或 4 MiB padded partition image。

普通 OpenWrt `sysupgrade` 是否适用于第三方 `large` 布局取决于固件中的 platform upgrade 脚本；未实机验证前，`large` 布局只使用该 HTTP recovery 的固件更新路径。

## 7. 与上游安装路径的区别

| 路径 | 是否改 GPT | 是否安装二阶段 U-Boot | 推荐场景 |
|---|---:|---:|---|
| OpenWrt PR #21586：initramfs + `fw_setenv` + `sysupgrade` | 否 | 否 | 最接近上游、最少改动 |
| HTTP chainloader `mainline` | 会重建/校验 GPT 尾部 | 是，位于 `rsvd_2` | 需要 Web 备份和恢复能力 |
| HTTP chainloader `large` | 是，大幅改变尾部布局 | 是，独立 `chainloader` 分区 | 实验性大存储布局 |

无论选择哪条路径，都不要在原厂 U-Boot 中 `saveenv`，不要直接写 `u-boot.bin`，不要把 chainloader 写入 eMMC hardware boot0/boot1。
