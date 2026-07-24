# SBE1V1K LEDE PPE Hardware Acceleration

[中文](#中文说明) | [English](#english)

## 中文说明

### 分支定位

`lede-ppe` 是面向 Askey SBE1V1K（亦称 Askey RTQ7300T / Spectrum
SBE1V1K）的实验性 LEDE 硬件加速分支。它以本仓库的 `lede` 分支为基础，
将 Qualcomm QSDK 14 系列的 SSDK、PPE、NSS-DP 和 ECM 数据路径适配到
LEDE 当前使用的 Linux 6.12 内核。

这个分支并不是完整的 Qualcomm QSDK，也不能等同于厂商固件中显示的
“QSDK 12.2 R7”。它只迁移了 SBE1V1K 有线网络硬件加速所需的开源组件，
并继续使用 LEDE/OpenWrt 的用户空间、LuCI、网络配置和软件包体系。

### 主要改动

- 为 IPQ9570/IPQ95xx 引入 QSDK SSDK，负责交换机、PHY、UNIPHY 和 PPE
  硬件初始化。
- 引入 QSDK PPE 驱动，为 IPv4/IPv6、路由、NAT、桥接、VLAN 和 PPPoE
  流量提供硬件规则下发能力。
- 引入 NSS-DP/EDMA v2 数据路径，接管 SBE1V1K 的四个物理以太网端口。
- 引入 ECM PPE 前端，负责识别可加速连接并向 PPE 创建或撤销规则。
- 针对 Linux 6.12 适配 bridge、PPPoE、netfilter、conntrack、sysctl、
  ethtool、VLAN、ARM64 cache 等内核接口。
- 增加 conntrack DSCP remark 扩展，供 ECM/PPE 保存 DSCP 和内部优先级。
- 使用上游 NSSCC 时钟树驱动 QSDK SSDK 和 NSS-DP，避免依赖完整的 QSDK
  私有时钟实现。
- 为 `lan1`、`lan2`、`lan3` 和 `wan` 保留稳定的接口命名与原有 MAC 地址
  来源。
- 固件继续预装 PassWall 和 DDNS。

### SBE1V1K 数据路径

设备树为本机配置了以下 QSDK 数据路径：

| 逻辑接口 | PPE 端口 | PHY | 接口模式 |
| --- | ---: | --- | --- |
| `lan2` | 3 | QCA8075，地址 18 | QSGMII |
| `lan3` | 4 | QCA8075，地址 19 | QSGMII |
| `lan1` | 5 | QCA8081，地址 28 | USXGMII |
| `wan` | 6 | RTL8261N，地址 0 | USXGMII / Clause 45 |

EDMA 使用 QSDK IPQ95xx 的 ring 4–31 / ring 20–23 布局及对应中断映射。
上游 `qcom,ipq9574-ppe` 节点在本分支中保持禁用，同时内核不编译
`CONFIG_QCOM_PPE`，防止上游 PPE 驱动和 QSDK 数据路径同时占用硬件资源。

### PassWall 与 ECM 共存

PassWall 的透明代理依赖 packet mark 和 conntrack mark。ECM 如果提前将这类
连接下发给 PPE，后续数据包可能绕过代理规则。

本分支会拒绝加速带有 mark 的 packet/conntrack 流量，让 PassWall 管理的连接
继续走 Linux 网络栈。普通、无标记且满足条件的路由/NAT 流量仍可由 ECM
下发至 PPE。

由于 SBE1V1K 当前只迁移有线数据路径，本分支暂时关闭 ECM 对 PPE virtual
port 的查询，避免引入 QSDK 私有 skb recycler 和 Wi-Fi VP ABI。此限制不影响
物理以太网端口的基础 PPE 加速，但 Wi-Fi 与 PPE 的直接加速尚未实现。

### 构建

建议在 Ubuntu 22.04/24.04 或 Debian 环境中构建。WSL 用户必须使用大小写
敏感的 Linux 文件系统目录，不要直接在普通 NTFS 目录中构建。

```bash
git clone --branch lede-ppe https://github.com/luckkyboy/SBE1V1K.git
cd SBE1V1K

./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make download -j8

# 避免 WSL 注入的 Windows “Program Files” 路径触发 find -execdir 安全检查
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
make -j"$(nproc)" V=s
```

输出目录：

```text
bin/targets/qualcommbe/ipq95xx/
```

当前已验证的构建基线：

- LEDE revision：`r7867-7aeb8ceff2`
- Linux：`6.12.95`
- 系统版本字符串：`OpenWrt 24.10.5`
- 目标：`qualcommbe/ipq95xx`
- Profile：`askey_sbe1v1k`

构建日志中的 `tuic-client` 缺失提示表示 PassWall 的该可选后端没有进入 feeds；
PassWall 本体以及 sing-box、Xray 等已选择后端仍可构建。`kmod-nf-nat6`
空包提示来自当前内核中 IPv6 NAT 的实现方式，也不是 PPE 构建失败。

### 首次测试与运行时确认

该分支已经通过干净内核构建、全部 QCA 模块编译、完整固件构建以及 DTB
反编译检查，但仍需要 SBE1V1K 实机验证。首次测试建议优先使用
`initramfs-uImage.itb` 从内存启动，并保留串口和可工作的原固件。

启动后至少检查：

```bash
dmesg | grep -Ei 'ssdk|ppe|edma|nss.?dp|ecm|qca8075|qca8081|rtl8261'
ip -br link
ethtool lan1
ethtool lan2
ethtool lan3
ethtool wan
lsmod | grep -E 'qca_ssdk|qca_nss_ppe|qca_nss_dp|ecm'
```

在产生普通 WAN–LAN 流量后，检查 ECM debugfs/sysfs 统计是否出现 accelerated
connection；同时启动 PassWall，确认被标记的透明代理连接仍能正常转发且未被
PPE 接管。

### 已知边界与风险

- 目前完成的是编译和静态设备树验证，不代表已经完成实机稳定性认证。
- PPE/EDMA 时钟、reset、PHY link、长时间大流量和多核中断分配仍需实机验证。
- Wi-Fi virtual port、QSDK skb recycler、Wi-Fi PPE direct path 未迁移。
- 某些隧道、IPsec、特殊桥接/VLAN 拓扑可能回退到 Linux 软件转发。
- 刷写错误或设备树运行时问题可能导致所有以太网口不可用；首次启动应使用
  initramfs，并提前准备串口、原厂镜像和恢复方法。

如需回到不含 QSDK PPE 迁移的 LEDE 实现，请切换到本仓库的 `lede` 分支。

## English

### Purpose

`lede-ppe` is an experimental hardware-acceleration branch for the Askey
SBE1V1K, also sold as the Askey RTQ7300T and Spectrum SBE1V1K. It is based on
this repository's `lede` branch and ports the Qualcomm QSDK 14 SSDK, PPE,
NSS-DP and ECM data path to LEDE's Linux 6.12 kernel.

This is not a complete Qualcomm QSDK distribution and it must not be confused
with vendor firmware labels such as “QSDK 12.2 R7”. Only the open-source
components needed for the SBE1V1K wired acceleration path are integrated.
LEDE/OpenWrt userspace, LuCI, networking and package management remain in use.

### What changed

- QSDK SSDK initializes the IPQ9570 switch, PHYs, UNIPHY and PPE hardware.
- QSDK PPE provides hardware rule programming for eligible IPv4/IPv6 routing,
  NAT, bridge, VLAN and PPPoE flows.
- NSS-DP with EDMA v2 owns the four physical Ethernet data ports.
- The ECM PPE frontend classifies connections and creates/removes PPE rules.
- Linux 6.12 compatibility covers bridge, PPPoE, netfilter, conntrack, sysctl,
  ethtool, VLAN and ARM64 cache APIs.
- A conntrack DSCP remark extension preserves DSCP and internal priority data.
- QSDK drivers use the upstream NSSCC clock tree.
- Stable `lan1`, `lan2`, `lan3` and `wan` names and the board MAC-address
  sources are retained.
- PassWall and DDNS remain included in the firmware.

The physical port mapping is:

| Interface | PPE port | PHY | Mode |
| --- | ---: | --- | --- |
| `lan2` | 3 | QCA8075 at address 18 | QSGMII |
| `lan3` | 4 | QCA8075 at address 19 | QSGMII |
| `lan1` | 5 | QCA8081 at address 28 | USXGMII |
| `wan` | 6 | RTL8261N at address 0 | USXGMII / Clause 45 |

The upstream `qcom,ipq9574-ppe` node and `CONFIG_QCOM_PPE` are disabled to
prevent the upstream and QSDK drivers from claiming the same hardware.

### PassWall coexistence

ECM deliberately rejects packet-marked or conntrack-marked flows so PassWall
transparent-proxy traffic continues through the Linux networking stack.
Eligible unmarked routing/NAT traffic can still be accelerated by PPE.

PPE virtual-port lookups are currently disabled because the QSDK private skb
recycler and Wi-Fi VP ABI are outside the wired-only scope of this port.
Physical Ethernet acceleration is the current target; direct Wi-Fi PPE
acceleration is not implemented.

### Build and validation

Use the commands in the Chinese build section above. Images are produced in:

```text
bin/targets/qualcommbe/ipq95xx/
```

The current verified build baseline is LEDE `r7867-7aeb8ceff2`, Linux
`6.12.95`, target `qualcommbe/ipq95xx`, profile `askey_sbe1v1k`.

The branch passes clean kernel compilation, all QCA module builds, a complete
firmware build and decompiled-DTB inspection. It has not yet completed
SBE1V1K hardware validation. Start with the initramfs image, retain serial
console access and a recovery image, then verify SSDK/PPE/EDMA/NSS-DP/ECM
logs, all four links and both accelerated and PassWall-marked traffic before
installing a persistent image.

Switch back to the repository's `lede` branch to use the LEDE build without
this QSDK PPE migration.
