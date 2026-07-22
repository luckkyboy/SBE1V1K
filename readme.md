# Spectrum / Askey SBE1V1K OpenWrt

本项目保存一套可追溯、可重复生成的 SBE1V1K OpenWrt 源码方案。它以设备支持 PR 作者 Andrew Lamarche 的固定提交为基线，再应用尚未全部合入 OpenWrt 主线、但该设备实际需要的补丁。

> 截至 2026-07-22，SBE1V1K 的设备支持 PR 仍未合并，OpenWrt 官方下载站没有该机型的正式镜像。本项目属于测试方案。首次安装需要拆机、1.8V 串口和 eMMC glitch，有损坏引导程序乃至变砖的风险。

## 快速开始

在 Ubuntu 24.04 或 WSL2 Ubuntu 中运行：

```bash
git clone https://github.com/luckkyboy/SBE1V1K.git
cd SBE1V1K
./scripts/prepare-source.sh "$HOME/src/openwrt-sbe1v1k"
./scripts/build.sh "$HOME/src/openwrt-sbe1v1k"
```

固定基线、补丁来源和校验值见 [sources.lock](sources.lock)，完整构建、拆机、备份和刷机步骤见 [SBE1V1K-OpenWrt-Guide.md](SBE1V1K-OpenWrt-Guide.md)。

## 本项目包含什么

- `patches/0001-*`：OpenWrt PR #23786 的 ath12k 单 wiphy、多 radio MAC 修复。
- `patches/0002-*`：Felix Fietkau 提出的多个 PCI 路径候选修复。
- `patches/0003-*`：firmware_qca-wireless PR #123 的精确 QCN9274 BDF 二进制补丁。
- `configs/sbe1v1k.config`：同时生成 initramfs 和 squashfs sysupgrade 的最小配置。
- `configs/feeds.conf`：把 packages、LuCI、routing、telephony、video 五个官方 feed 固定到调查日提交。
- `scripts/prepare-source.sh`：获取固定作者基线并依次应用补丁，最后核对 Git tree 和 BDF SHA-256。
- `scripts/build.sh`：更新 feeds、生成配置并编译目标镜像。

OpenWrt 完整工作树和编译产物不直接提交到本仓库；它们由固定提交和补丁确定性还原，避免复制数 GB 上游历史，同时保留每项改动的来源。

## 主要上游资料

- [设备支持 PR #21586](https://github.com/openwrt/openwrt/pull/21586)
- [PR 作者的 OpenWrt 分支](https://github.com/andrewjlamarche/openwrt/tree/sbe1v1k)
- [OpenWrt 论坛详细讨论](https://forum.openwrt.org/t/spectrum-sbe1v1k-ipq9574-openwrt-support/245244)
- [QCN9274 BDF PR #123](https://github.com/openwrt/firmware_qca-wireless/pull/123)

## 许可证与风险

本项目的脚本和文档使用仓库中的 MIT License。OpenWrt 及补丁中的第三方代码仍分别服从其上游许可证。刷机风险由操作者自行承担；没有完整 eMMC 备份时不要进行首次安装。
