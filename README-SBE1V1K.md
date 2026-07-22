# SBE1V1K OpenWrt 源码分支

本仓库的 `main` 本身就是完整 OpenWrt 源码树，以 Andrew LaMarche 的 SBE1V1K 设备提交 `525e6238f4` 为上游基线。克隆后不需要运行源码生成脚本，也不需要再克隆另一个 OpenWrt 仓库。

## 源码提交组成

```text
e5a4e1e388 ipq-wifi: vendor Askey SBE1V1K BDF
2268c9ebab wifi-scripts: support multiple candidate PCI paths
06e83ac02d wifi: ath12k: set per-radio MAC address from DT
f8a9d12081 Merge SBE1V1K project history onto OpenWrt
525e6238f4 qualcommbe: add support for Askey SBE1V1K
```

- `525e6238f4` 是 [PR 作者分支](https://github.com/andrewjlamarche/openwrt/tree/sbe1v1k)的设备支持提交。
- `06e83ac02d` 来自 OpenWrt PR #23786 的 ath12k per-radio MAC 修复。
- `2268c9ebab` 是 Felix Fietkau 多候选 PCI 路径方案的实验性集成；它不在 Andrew 最终分支，也未合入 OpenWrt。
- `e5a4e1e388` 固定 firmware_qca-wireless PR #123 的 SBE1V1K QCN9274 BDF。

`author-head` 分支严格指向 Andrew 的代码，用于比较；`project-meta` 保留迁移前的脚本/补丁项目历史。推荐编译 `main`。

## Ubuntu / WSL2 编译

先安装依赖：

```bash
sudo apt update
sudo apt install -y \
  build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \
  gettext git libncurses-dev libssl-dev python3-setuptools rsync swig \
  unzip zlib1g-dev file wget bc bzip2 libelf-dev liblzma-dev \
  python3-dev time xxd zstd
```

然后直接在本仓库根目录编译：

```bash
git clone https://github.com/luckkyboy/SBE1V1K.git
cd SBE1V1K

./scripts/feeds update -a
./scripts/feeds install -a
cp configs/sbe1v1k.config .config
make defconfig
make download -j"$(nproc)"
make -j"$(nproc)" world
```

五个官方 feeds 已在 `feeds.conf.default` 中固定到精确提交。目标输出在：

```text
bin/targets/qualcommbe/ipq95xx/openwrt-qualcommbe-ipq95xx-askey_sbe1v1k-initramfs-uImage.itb
bin/targets/qualcommbe/ipq95xx/openwrt-qualcommbe-ipq95xx-askey_sbe1v1k-squashfs-sysupgrade.bin
```

若并行构建失败：

```bash
make -j1 V=s
```

详细支持状态、拆机与刷机步骤见 `SBE1V1K-OpenWrt-Guide.md`。可选的 HTTP U-Boot chainloader 用法见 `SBE1V1K-UBOOT.md`。
