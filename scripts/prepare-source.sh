#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
# shellcheck disable=SC1091
source "$PROJECT_DIR/sources.lock"

MODE="tested-multipath"
if [[ "${1:-}" == "--mode" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "用法：$0 [--mode author-head|tested-multipath] [目标目录]" >&2
        exit 2
    fi
    MODE="$2"
    shift 2
fi
case "$MODE" in
    author-head|tested-multipath) ;;
    *)
        echo "错误：未知模式：$MODE" >&2
        echo "可用模式：author-head、tested-multipath" >&2
        exit 2
        ;;
esac
if [[ $# -gt 1 ]]; then
    echo "用法：$0 [--mode author-head|tested-multipath] [目标目录]" >&2
    exit 2
fi

DEST="${1:-$PROJECT_DIR/openwrt}"
if [[ -e "$DEST" ]] && [[ -n "$(ls -A "$DEST" 2>/dev/null || true)" ]]; then
    echo "错误：目标目录不是空目录：$DEST" >&2
    echo "请换一个新目录；脚本不会删除或覆盖已有源码。" >&2
    exit 1
fi

mkdir -p "$DEST"
git -C "$DEST" init
git -C "$DEST" remote add origin "$OPENWRT_REPOSITORY"

# GitHub normally permits fetching a reachable commit by object ID.  The branch
# fallback keeps the script usable if a server disables that operation.
if ! git -C "$DEST" fetch --depth=1 origin "$OPENWRT_COMMIT"; then
    git -C "$DEST" fetch origin "$OPENWRT_BRANCH"
fi
git -C "$DEST" cat-file -e "${OPENWRT_COMMIT}^{commit}"
git -C "$DEST" checkout -b "prepared/sbe1v1k-${MODE}-20260722" "$OPENWRT_COMMIT"

case "$MODE" in
    author-head)
        EXPECTED_TREE="$OPENWRT_TREE_AUTHOR_HEAD"
        ;;
    tested-multipath)
        git -C "$DEST" am \
            "$PROJECT_DIR/patches/0001-wifi-ath12k-set-per-radio-MAC-address-from-DT.patch" \
            "$PROJECT_DIR/patches/0002-wifi-scripts-support-multiple-candidate-PCI-paths.patch" \
            "$PROJECT_DIR/patches/0003-ipq-wifi-vendor-Askey-SBE1V1K-BDF.patch"
        EXPECTED_TREE="$OPENWRT_TREE_TESTED_MULTIPATH"
        ;;
esac
cp "$PROJECT_DIR/configs/sbe1v1k.config" "$DEST/sbe1v1k.config"
cp "$PROJECT_DIR/configs/feeds.conf" "$DEST/feeds.conf"

ACTUAL_TREE="$(git -C "$DEST" rev-parse 'HEAD^{tree}')"
if [[ "$ACTUAL_TREE" != "$EXPECTED_TREE" ]]; then
    echo "错误：$MODE 模式的 Git tree 不匹配。" >&2
    echo "期望：$EXPECTED_TREE" >&2
    echo "实际：$ACTUAL_TREE" >&2
    exit 1
fi

if [[ "$MODE" == "tested-multipath" ]]; then
    BDF="$DEST/package/firmware/ipq-wifi/src/board-askey_sbe1v1k.qcn9274"
    printf '%s  %s\n' "$QCN9274_BDF_SHA256" "$BDF" | sha256sum --check --status
else
    echo "警告：author-head 是严格审计模式，未补 BDF、per-radio MAC 或多路径支持；不保证完成镜像构建。" >&2
fi

echo "SBE1V1K 源码已准备完成：$DEST"
echo "模式：$MODE"
echo "分支：$(git -C "$DEST" branch --show-current)"
echo "源码 tree：$ACTUAL_TREE"
if [[ "$MODE" == "tested-multipath" ]]; then
    echo "下一步：$PROJECT_DIR/scripts/build.sh $DEST"
fi
