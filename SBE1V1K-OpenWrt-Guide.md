# SBE1V1K OpenWrt 源码、编译、拆机与刷机指南

调查日期：2026-07-22。设备别名包括 Spectrum SBE1V1K、Askey SBE1V1K、Askey RTQ7300T。

## 1. 先说结论

SBE1V1K 已经具备可用的 OpenWrt 设备支持代码，但还不能称为“官方完善支持”：

- OpenWrt 设备支持 [PR #21586](https://github.com/openwrt/openwrt/pull/21586) 仍为 Open 状态，因此官方 snapshot/稳定版中还没有该机型配置和镜像。
- PR 作者是 `andrewjlamarche`，其源码为 [andrewjlamarche/openwrt 的 sbe1v1k 分支](https://github.com/andrewjlamarche/openwrt/tree/sbe1v1k)。本项目固定在提交 `525e6238f484876a0551323f9be4599e2945bc84`，避免作者 force-push 后构建内容悄悄变化。
- 作者分支已有 CPU、2 GB 内存、8 GB eMMC、四个以太网口、三频 Wi-Fi、LED、复位键和 PWM 风扇定义。论坛用户也报告这些普通功能可工作。
- 仅克隆作者分支仍缺三个在途项：每 radio MAC、随机 PCI 枚举下的三 radio 稳定识别，以及 QCN9274 BDF。本仓库已把它们做成直接修改 OpenWrt 源码的可追溯提交；其中多路径提交并非作者最终代码，而是未上游的实验性集成。
- 目前没有 IPQ9574 PPE/NSS 硬件路由加速支持；高吞吐转发按软件路径理解。这里的“可用”不等于官方合并，也不等于有硬件卸载。
- PR 的 GitHub 检查没有完成一次完整的 `qualcommbe/ipq95xx` 镜像编译；本项目当前 Windows 主机也没有安装 WSL Linux 发行版，因此这里不冒充“已实机构建验证”。源码 tree、补丁应用和二进制校验已经验证，完整编译命令如下。

## 2. 硬件与支持状态

| 项目 | 硬件/状态 |
|---|---|
| SoC | Qualcomm IPQ9570；DTS compatible 为 `qcom,ipq9574`，两种称呼来自同一目标代码 |
| RAM / 存储 | Micron 2 GB / 8 GB eMMC |
| 10G | RTL8261BE，设备树与固件已包含 |
| 2.5G | QCA8081，已定义 |
| 1G | QCA8075 × 2，已定义 |
| 2.4 GHz | QCN6214，4×4 |
| 5 / 6 GHz | QCN6274，分别 4×4；共用单 wiphy、多 radio 结构，需要本项目 0001/0002 补丁 |
| 风扇 | PWM 风扇；修复 PR #23916 已合并并包含在固定基线中 |
| LED / 按钮 | 单状态灯、单复位键 |
| USB | 无 |
| Bootloader | 原厂 U-Boot 1.0.9；可选第三方 HTTP 二阶段 chainloader。首次进入原厂 shell 仍需串口 + eMMC glitch |
| PPE/NSS 加速 | 未支持 |

## 3. 源码的可追溯组成

本仓库根目录就是完整 OpenWrt 工作树，不再需要源码生成脚本。`sources.lock` 是来源锁文件，相关 Git 线索明确分开：

- `author-head` 分支：严格指向 Andrew 的 `525e623`，tree 为 `a3913efb3e6ae889d95bdd76b652e46f2e2b5f2a`。它用于审计，不含独立 BDF、per-radio MAC 和多路径修复。
- `main` 分支：推荐编译版本，在作者分支上直接增加下面三个源码提交；应用完设备补丁、加入本项目文档和 feeds 固定之前的源码 tree 为：

```text
67a6d6b5080b00925eec3a2c16710047959044e3
```

`feeds.conf.default` 把 packages、LuCI、routing、telephony、video 五个官方 feed 固定到 2026-07-22 的精确提交。否则 `feeds update -a` 会随时间漂移，即使设备源码 tree 相同也可能构建出不同内容。

直接源码提交如下：

1. `06e83ac02d wifi: ath12k: set per-radio MAC address from DT`
   - 来源：[OpenWrt PR #23786](https://github.com/openwrt/openwrt/pull/23786)
   - 上游提交：`e811bcdf07a8db43d0b6a33171afe4468a34ba02`
   - 用途：从 DT 给单 wiphy 内的三个 radio 设置各自 MAC。
2. `2268c9ebab wifi-scripts: support multiple candidate PCI paths`
   - 来源：[Felix Fietkau 补丁 b83be8f0](https://nbd.name/p/b83be8f0)，设计讨论见 [PR #23840](https://github.com/openwrt/openwrt/pull/23840)
   - 状态：**没有包含在 Andrew 的最终分支中，也未合入 OpenWrt；属于本项目实验性集成**。
   - 用途：把多个可能的 PCI 路径写入 `board.json`，避免 PCI 枚举变化后无线配置重复或消失。
3. `e5a4e1e388 ipq-wifi: vendor Askey SBE1V1K BDF`
   - 来源：[firmware_qca-wireless PR #123](https://github.com/openwrt/firmware_qca-wireless/pull/123)，提交 `0d2b3c0c42b5cae549e59f1a3f003216ed4d6c4b`
   - BDF SHA-256：`5ed8477ace2ce31236d756de24f31e7169acc69d8df18e5b81e7fdea0715e97a`
   - 用途：在 BDF PR 合并前让三频 Wi-Fi 固件有正确的板级数据。

已合入基线而无需额外补丁的关键依赖：

- [PR #21506：qualcommbe Linux 6.18 支持](https://github.com/openwrt/openwrt/pull/21506)，已合并。
- [PR #23908：默认切到 Linux 6.18](https://github.com/openwrt/openwrt/pull/23908)，已合并。
- [PR #21767：从 DT 读取 ath12k calibration variant](https://github.com/openwrt/openwrt/pull/21767)，已合并。
- [PR #23916：PWM period 计算修复](https://github.com/openwrt/openwrt/pull/23916)，已合并。

## 4. 编译环境

推荐 Ubuntu 24.04 x86_64；Windows 用户使用 WSL2 Ubuntu 24.04。不要在 Windows 原生 PowerShell/CMD 中直接编译 OpenWrt，也不要以 root 用户构建。

### 4.1 Windows 安装 WSL2

用管理员 PowerShell 执行：

```powershell
wsl --install -d Ubuntu-24.04
```

按提示重启并创建普通 Linux 用户。为了速度和文件权限正确，OpenWrt 工作树应放在 WSL 的 `$HOME`，不要放在 `/mnt/c` 下。

### 4.2 Ubuntu/WSL 安装依赖

```bash
sudo apt update
sudo apt install -y \
  build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \
  gettext git libncurses-dev libssl-dev python3-setuptools rsync swig \
  unzip zlib1g-dev file wget bc bzip2 libelf-dev liblzma-dev \
  python3-dev time xxd zstd
```

官方依赖说明以 [OpenWrt Build system setup](https://openwrt.org/docs/guide-developer/toolchain/install-buildsystem) 为准。磁盘建议至少留 30 GB，内存建议 8 GB 以上。

## 5. 克隆并直接编译

```bash
mkdir -p "$HOME/src"
git clone https://github.com/luckkyboy/SBE1V1K.git "$HOME/src/SBE1V1K"
cd "$HOME/src/SBE1V1K"

./scripts/feeds update -a
./scripts/feeds install -a
cp configs/sbe1v1k.config .config
make defconfig
make download -j"$(nproc)"
make -j"$(nproc)" world
```

`author-head` 仅用于比较上游作者原始代码，不是推荐构建分支：

```bash
git switch author-head
```

若并行构建失败，用单线程详细日志定位第一处真实错误：

```bash
make -j1 V=s
```

输出目录为 `bin/targets/qualcommbe/ipq95xx/`，本流程需要的两个文件通常是：

```text
openwrt-qualcommbe-ipq95xx-askey_sbe1v1k-initramfs-uImage.itb
openwrt-qualcommbe-ipq95xx-askey_sbe1v1k-squashfs-sysupgrade.bin
```

还会生成 `factory.bin`，但本文的首次安装路径不使用它：先 TFTP 启动 initramfs，再由 OpenWrt 的 `sysupgrade` 正确写 eMMC。

## 6. 拆机与电气安全

### 6.1 工具

- 塑料撬片、合适的螺丝刀、绝缘镊子/瞬时探针。
- 明确支持 1.8 V IO 的 USB-TTL 适配器或电平转换器；3.3 V/5 V TTL 不能直连。
- TFTP 服务器、一根网线、Linux/WSL 电脑。
- 建议使用放大镜、ESD 防护和可恢复的探针夹具。

### 6.2 打开外壳

1. 拔掉电源和所有网线，等待电容放电。
2. 拆下底部两颗螺丝。论坛作者说明卡扣缝隙可从靠近这两颗螺丝的位置开始撬。
3. 使用塑料撬片沿外壳接缝逐段释放卡扣，不要用金属刀片插到 PCB 附近，不要猛拉天线线缆。
4. 卡扣具体分布没有可靠文字图，遇到阻力应换位置。可先对照 [FCC 内部照片组 1](https://device.report/m/74a5883994bfafb18b315eab9f79aa8d31be53b724b47b9b7501cb9168a83eed) 或 [内部照片组 2](https://device.report/m/79ebc4a76a3f9db4a64dd8d985ab373a6e08484aecc50bc6f6382a0f427c5e2e)。

论坛拆机入口：[帖子 #77](https://forum.openwrt.org/t/spectrum-sbe1v1k-ipq9574-openwrt-support/245244/77)。

### 6.3 串口

串口参数为 `115200 8N1`，逻辑电平为 **1.8 V**。论坛照片所示方向从左到右标注为 `RX TX GND VCC`：

- [串口焊盘照片](https://forum.openwrt.org/uploads/default/original/3X/1/4/14ec6bc7f27c90affed6211b4129a60139b0d8f1.jpeg)
- [论坛帖子 #33](https://forum.openwrt.org/t/spectrum-sbe1v1k-ipq9574-openwrt-support/245244/33)

接线原则：路由器 TX 接适配器 RX，路由器 RX 接适配器 TX，GND 共地。不要用 USB-TTL 给路由器 VCC 供电；VCC 只作为 1.8 V 电平参考或下文 glitch 的板端参考点。接线和焊接必须断电进行。

> 论坛有人曾误把 12 V 加到风扇测速线并损坏设备。不要向风扇 TACH/PWM 或任何未知测试点注入电压。

## 7. 首次进入 U-Boot：eMMC glitch

这是整个流程最危险的一步。[设备 PR 的安装说明](https://github.com/openwrt/openwrt/pull/21586) 明确警告：glitch 可能破坏 eMMC 或 bootloader；当 U-Boot 因 glitch 无法正确访问 eMMC 时，在 U-Boot 中持久化环境甚至可能把数据写到闪存开头并覆盖 bootloader。

本节到第 11 节描述的是 OpenWrt PR #21586 的上游式安装路径。若选择 [YYH2913/http-uboot](https://github.com/YYH2913/http-uboot/tree/sbe1v1k) 的 HTTP 二阶段 chainloader，请改按 `SBE1V1K-UBOOT.md` 操作，不要把两套环境变量、GPT 迁移和写入步骤混用。

因此必须遵守：

- **绝对不要在 U-Boot 中执行 `saveenv`。**
- U-Boot 中只用 `setenv` 做本次会话的临时网络设置。
- 持久化环境变量只能在成功启动的 Linux initramfs 中用 `fw_setenv`。
- 没有 1.8 V 工具、稳定串口输出或电子操作经验时，应停止操作。

eMMC CLK 位置参考：

- [eMMC 4-bit 引脚照片](https://forum.openwrt.org/uploads/default/original/3X/a/c/ac53fc8ebaa771d1931796b01ad1d0ecc611a4a1.jpeg)
- [论坛帖子 #5](https://forum.openwrt.org/t/spectrum-sbe1v1k-ipq9574-openwrt-support/245244/5)

操作顺序：

1. PC 打开 1.8 V 串口终端并观察启动日志。
2. 给路由器上电。
3. 在 U-Boot 加载 FIT image 的阶段，用绝缘瞬时探针把 eMMC `CLK` 短接到板上 UART `VCC` 参考点；看到进入 U-Boot 命令行后立即移除短接。
4. 早期论坛贴曾讨论 CLK 对 GND 等方法；本指南以 2026-07-21 更新的设备 PR 为准，不采用旧方法。

得到 `IPQ9574#` 提示符后，只执行：

```text
setenv ipaddr 192.168.1.1
setenv serverip 192.168.1.2
```

再次确认：不要执行 `saveenv`。

## 8. TFTP 临时启动 initramfs

1. 给 PC 的有线网卡设置静态地址 `192.168.1.2/24`，关闭该接口上会干扰的 DHCP/VPN。
2. 将编译出的 initramfs 文件复制到 TFTP 根目录并重命名为 `initramfs.itb`。
3. 用网线连接设备和 PC，启动 TFTP 服务。
4. 在 U-Boot 执行：

```text
tftpboot 0x44000000 initramfs.itb
bootm 0x44000000
```

若加载后报错并重启，PR 建议改用另一个 RAM 地址重试：

```text
tftpboot 0x80000000 initramfs.itb
bootm 0x80000000
```

进入临时 OpenWrt 后，先确认 PC 能 `ping 192.168.1.1`，然后 SSH 登录 `root@192.168.1.1`。此时先备份，不要急着改环境或刷 sysupgrade。

## 9. 完整备份 eMMC

整盘约 8 GB，不能假设路由器 `/tmp` 有足够空间。下面命令应在 PC 的 **Linux/WSL bash** 中运行，把数据经 SSH 流式保存。不要用旧版 Windows PowerShell 的 `>` 重定向二进制流。

```bash
mkdir -p "$HOME/sbe1v1k-backup"
cd "$HOME/sbe1v1k-backup"

ssh root@192.168.1.1 'dd if=/dev/mmcblk0 bs=4M' > sbe1v1k-mmcblk0.img
ssh root@192.168.1.1 'dd if=/dev/mmcblk0boot0 bs=1M' > sbe1v1k-mmcblk0boot0.img
ssh root@192.168.1.1 'dd if=/dev/mmcblk0boot1 bs=1M' > sbe1v1k-mmcblk0boot1.img

ssh root@192.168.1.1 'fw_printenv; echo ---partitions---; cat /proc/partitions' \
  > sbe1v1k-vendor-layout.txt
sha256sum sbe1v1k-* > SHA256SUMS
sha256sum --check SHA256SUMS
```

核对整盘镜像大小：

```bash
remote_sectors="$(ssh root@192.168.1.1 'cat /sys/class/block/mmcblk0/size')"
local_bytes="$(stat -c %s sbe1v1k-mmcblk0.img)"
test "$local_bytes" -eq "$((remote_sectors * 512))" \
  && echo '整盘备份长度正确' \
  || echo '备份长度不匹配，禁止继续刷机'
```

把备份复制到另一块物理磁盘。只有镜像长度和 SHA-256 都保存妥当后才继续。

## 10. 在 Linux 中设置 U-Boot 环境

仍在 initramfs 的 SSH shell 中执行以下三条，保持引号和分号完全一致：

```sh
fw_setenv bootargs 'console=ttyMSM0,115200n8 rootwait root=/dev/mmcblk0p27'
fw_setenv bootcmd 'echo "Hit ctrl+c for shell..."; if sleep 3; then run do_boot; else do_nothing; fi;'
fw_setenv do_boot 'mmc read 0x44000000 0x00014022 0x3800; bootm 0x44000000'
```

立刻核对：

```sh
fw_printenv bootargs bootcmd do_boot
```

这段三秒 `sleep` 是将来从串口按 `Ctrl+C` 进入 U-Boot 的窗口，因为厂商 U-Boot 忽略普通 `bootdelay`。如果以后让原厂固件完整启动，它可能把这些环境恢复为默认，OpenWrt 将无法继续自动启动。

## 11. 安装 sysupgrade

在 PC 上复制镜像：

```bash
scp bin/targets/qualcommbe/ipq95xx/\
openwrt-qualcommbe-ipq95xx-askey_sbe1v1k-squashfs-sysupgrade.bin \
root@192.168.1.1:/tmp/sbe1v1k-sysupgrade.bin
```

在路由器上先验证镜像，再清配置安装：

```sh
sysupgrade -T /tmp/sbe1v1k-sysupgrade.bin
sysupgrade -n -v /tmp/sbe1v1k-sysupgrade.bin
```

刷写过程中保持稳定供电，不要断电、拔线或触碰 glitch 探针。首次安装不要用 `mtd write`、`kmod-mtd-rw` 或手工 `dd` 写 eMMC，也不要把 `factory.bin` 直接写入未知分区。

## 12. 首次启动后的检查

```sh
ubus call system board
cat /tmp/sysinfo/model
ip -br link
iw dev
wifi status
dmesg | grep -Ei 'ath12k|qca8081|rtl826|pwm|mmc|error|fail'
```

逐项验证：

1. 四个物理以太网口分别能协商和传输数据，尤其核对 10G/2.5G 端口。
2. 2.4/5/6 GHz 三个 radio 都出现并能启用。
3. 三个 radio MAC 唯一、稳定；冷启动至少十次，`/etc/config/wireless` 不应重复生成 radio。
4. LED、复位键正常；负载升温时风扇可转，不能只以“空闲时安静”判断。
5. `dmesg` 中没有反复的 eMMC、ath12k firmware、BDF 或 PHY 错误。

## 13. 已知风险和不要做的事

- 设备 PR、BDF PR 和 per-radio MAC PR 仍可能变化。本项目固定提交，不会自动获得未来修正；更新时应审阅上游差异后新增可追溯提交。
- 尚无 PPE/NSS 硬件路由卸载，不能把端口线速等同于 NAT/防火墙线速。
- 2026 年 7 月出现的 HTTP chainloader/重分区方案不是当前 OpenWrt 上游安装路径；本仓库已在 `SBE1V1K-UBOOT.md` 单独审计。使用它前必须理解 `mainline`/`large` 布局、备份边界和非原子写入风险。
- 如果 sysupgrade 报 squashfs 校验/读取错误，先怀疑下载或 eMMC 写入损坏，停止重刷并核对镜像 SHA-256、串口日志和整盘备份。
- 变砖恢复可能需要直接 eMMC 编程器；这也是为什么整盘、boot0、boot1 三份备份缺一不可。

## 14. 论坛中最有价值的讨论位置

- [完整主题](https://forum.openwrt.org/t/spectrum-sbe1v1k-ipq9574-openwrt-support/245244)
- [#5：eMMC 引脚照片](https://forum.openwrt.org/t/spectrum-sbe1v1k-ipq9574-openwrt-support/245244/5)
- [#33：1.8 V 串口和焊盘顺序](https://forum.openwrt.org/t/spectrum-sbe1v1k-ipq9574-openwrt-support/245244/33)
- [#77：两颗底部螺丝及开壳起点](https://forum.openwrt.org/t/spectrum-sbe1v1k-ipq9574-openwrt-support/245244/77)
- [#106：作者报告普通功能已完整运行](https://forum.openwrt.org/t/spectrum-sbe1v1k-ipq9574-openwrt-support/245244/106)
- [#109–#111：仅克隆作者分支缺依赖会造成以太网问题](https://forum.openwrt.org/t/spectrum-sbe1v1k-ipq9574-openwrt-support/245244/109)
- [#123：多 PCI 路径方案连续十次重启稳定](https://forum.openwrt.org/t/spectrum-sbe1v1k-ipq9574-openwrt-support/245244/123)

后续若设备 PR 合并，应优先迁移到官方 OpenWrt `main`，逐项删除已上游化的本地补丁，而不是长期停留在这个冻结快照。
