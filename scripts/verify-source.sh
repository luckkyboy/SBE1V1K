#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
# shellcheck disable=SC1091
source "$PROJECT_DIR/sources.lock"
SOURCE_DIR="${1:-$PROJECT_DIR/openwrt}"

ACTUAL_TREE="$(git -C "$SOURCE_DIR" rev-parse 'HEAD^{tree}')"
[[ "$ACTUAL_TREE" == "$OPENWRT_TREE_AFTER_PATCHES" ]]

BDF="$SOURCE_DIR/package/firmware/ipq-wifi/src/board-askey_sbe1v1k.qcn9274"
printf '%s  %s\n' "$QCN9274_BDF_SHA256" "$BDF" | sha256sum --check

git -C "$SOURCE_DIR" log --oneline --decorate -4
echo "验证通过：$ACTUAL_TREE"
