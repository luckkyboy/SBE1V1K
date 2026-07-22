# 补丁状态与适用模式

本目录中的补丁并不都属于 Andrew LaMarche 的最终 `sbe1v1k` 分支。项目刻意保留来源和成熟度差异，不能把它们统称为“作者最终代码”。

| 补丁 | 来源 | 状态 | `author-head` | `tested-multipath` |
|---|---|---|---:|---:|
| `0001-*` | OpenWrt PR #23786，提交 `e811bcdf...` | 上游 PR 待合并；Andrew 确认在 SBE1V1K 上测试通过 | 否 | 是 |
| `0002-*` | Felix Fietkau `b83be8f0` | **实验性、未在作者分支、未合入 OpenWrt**；论坛有社区重启测试 | 否 | 是 |
| `0003-*` | firmware_qca-wireless PR #123，提交 `0d2b3c0c...` | 独立固件 PR 待合并；精确 BDF 二进制 | 否 | 是 |

## 为什么 `tested-multipath` 包含 0002

作者提交 `525e623` 调用：

```sh
ucidef_add_wlan "$DEV_PATH_PCIE0" "$DEV_PATH_PCIE1" "$DEV_PATH_PCIE2"
```

但该提交基线中的 `ucidef_add_wlan()` 只把第一个参数登记为 `path`，其余参数被交给 `json_add_fields`，不会成为另外两个无线候选路径。OpenWrt PR #21586 的审查也指出了这一点；PR 依赖列表写的是等待 nbd168 的正式补丁。

0002 把 `path` 改成候选路径数组，并修改 wifi-scripts 依次匹配候选项，因此能让作者的三参数调用获得预期语义。它是本项目为功能完整性作出的、公开可审计的集成选择，不是 Andrew 最终采用或 OpenWrt 已接受的方案。

参考：

- https://github.com/openwrt/openwrt/pull/21586
- https://github.com/openwrt/openwrt/pull/23840
- https://nbd.name/p/b83be8f0
- https://github.com/openwrt/openwrt/pull/23786
- https://github.com/openwrt/firmware_qca-wireless/pull/123
