#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
# shellcheck disable=SC1091
source "$PROJECT_DIR/sources.lock"

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
git -C "$DEST" checkout -b prepared/sbe1v1k-20260722 "$OPENWRT_COMMIT"

git -C "$DEST" am "$PROJECT_DIR"/patches/*.patch
cp "$PROJECT_DIR/configs/sbe1v1k.config" "$DEST/sbe1v1k.config"
cp "$PROJECT_DIR/configs/feeds.conf" "$DEST/feeds.conf"

ACTUAL_TREE="$(git -C "$DEST" rev-parse 'HEAD^{tree}')"
if [[ "$ACTUAL_TREE" != "$OPENWRT_TREE_AFTER_PATCHES" ]]; then
    echo "错误：补丁后的 Git tree 不匹配。" >&2
    echo "期望：$OPENWRT_TREE_AFTER_PATCHES" >&2
    echo "实际：$ACTUAL_TREE" >&2
    exit 1
fi

BDF="$DEST/package/firmware/ipq-wifi/src/board-askey_sbe1v1k.qcn9274"
printf '%s  %s\n' "$QCN9274_BDF_SHA256" "$BDF" | sha256sum --check --status

echo "SBE1V1K 源码已准备完成：$DEST"
echo "分支：$(git -C "$DEST" branch --show-current)"
echo "源码 tree：$ACTUAL_TREE"
echo "下一步：$PROJECT_DIR/scripts/build.sh $DEST"
