#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="${1:-$PROJECT_DIR/openwrt}"
JOBS="${JOBS:-$(nproc)}"

if [[ "$(id -u)" -eq 0 ]]; then
    echo "错误：OpenWrt 构建不能以 root 用户运行。" >&2
    exit 1
fi
if [[ ! -x "$SOURCE_DIR/scripts/feeds" ]]; then
    echo "错误：不是有效的 OpenWrt 源码目录：$SOURCE_DIR" >&2
    exit 1
fi

cd "$SOURCE_DIR"
./scripts/feeds update -a
./scripts/feeds install -a
cp "$PROJECT_DIR/configs/sbe1v1k.config" .config
make defconfig

grep -q '^CONFIG_TARGET_qualcommbe_ipq95xx_DEVICE_askey_sbe1v1k=y$' .config
grep -q '^CONFIG_TARGET_ROOTFS_INITRAMFS=y$' .config
grep -q '^CONFIG_TARGET_ROOTFS_SQUASHFS=y$' .config

make download -j"$JOBS"
make -j"$JOBS" world

echo "构建完成。SBE1V1K 文件位于："
find bin/targets/qualcommbe/ipq95xx -maxdepth 1 -type f \
    -name '*askey_sbe1v1k*' -print | sort

