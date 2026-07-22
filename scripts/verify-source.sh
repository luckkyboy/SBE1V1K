#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
# shellcheck disable=SC1091
source "$PROJECT_DIR/sources.lock"

MODE="tested-multipath"
if [[ "${1:-}" == "--mode" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "用法：$0 [--mode author-head|tested-multipath] [源码目录]" >&2
        exit 2
    fi
    MODE="$2"
    shift 2
fi
case "$MODE" in
    author-head) EXPECTED_TREE="$OPENWRT_TREE_AUTHOR_HEAD" ;;
    tested-multipath) EXPECTED_TREE="$OPENWRT_TREE_TESTED_MULTIPATH" ;;
    *)
        echo "错误：未知模式：$MODE" >&2
        exit 2
        ;;
esac
if [[ $# -gt 1 ]]; then
    echo "用法：$0 [--mode author-head|tested-multipath] [源码目录]" >&2
    exit 2
fi
SOURCE_DIR="${1:-$PROJECT_DIR/openwrt}"

ACTUAL_TREE="$(git -C "$SOURCE_DIR" rev-parse 'HEAD^{tree}')"
[[ "$ACTUAL_TREE" == "$EXPECTED_TREE" ]]

if [[ "$MODE" == "tested-multipath" ]]; then
    BDF="$SOURCE_DIR/package/firmware/ipq-wifi/src/board-askey_sbe1v1k.qcn9274"
    printf '%s  %s\n' "$QCN9274_BDF_SHA256" "$BDF" | sha256sum --check
fi

git -C "$SOURCE_DIR" log --oneline --decorate -4
echo "验证通过：$MODE / $ACTUAL_TREE"
