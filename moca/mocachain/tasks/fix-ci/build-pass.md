---
title: "Mocachain 全仓构建通过计划"
aliases:
  - build-pass
  - 所有 mocachain 的仓先使用本地路径。/scripts/check-build-by-branch.sh --branch main  > logs/build.log 2 命令是否可以执行成功，如果有遇到问题，从 main 分支创建 feat/build-pass 分支解决问题，并且创建 PR，后续我们将会使用远程分支替换本地分支。
tags:
  - mocachain
  - task
  - ci-fixes
  - zh
  - fix-ci
  - ci
type: "task-note"
status: "archived"
area: "tasks"
topic: "ci-fixes"
language: "zh-CN"
source_path: "tasks/fix-ci/build-pass.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 CI Fixes，并补齐索引与语言导航。

## Navigation
- [[Tasks Index]]
- [[CI Fixes Index]]
- [[Topic Index]]
- [[Language Index]]
- [[build-pass-en|build-pass-en]]


# Mocachain 全仓构建通过计划

---

所有 mocachain 的仓先使用本地路径。/scripts/check-build-by-branch.sh --branch main  > logs/build.log 2 命令是否可以执行成功，如果有遇到问题，从 main 分支创建 feat/build-pass 分支解决问题，并且创建 PR，后续我们将会使用远程分支替换本地分支。

## PR 列表

| 仓库 | PR | 说明 |
|------|-----|------|
| moca-devcontainer | [#4](https://github.com/mocachain/moca-devcontainer/pull/4) | 移除脚本中的硬编码路径，修复伪版本生成逻辑 |
| moca-cometbft | [#6](https://github.com/mocachain/moca-cometbft/pull/6) | 统一 btcd/btcec/v2 到 v2.3.4，适配 secp256k1 API |
| moca-cosmos-sdk | [#6](https://github.com/mocachain/moca-cosmos-sdk/pull/6) | 统一 btcd/btcec/v2 到 v2.3.4 |
| moca-ibc-go | [#70](https://github.com/mocachain/moca-ibc-go/pull/70) | 统一 btcd/btcec/v2 到 v2.3.4，修复 replace 指令 |****
| moca | [#83](https://github.com/mocachain/moca/pull/83) | 统一 btcd/btcec/v2 到 v2.3.4 |
| moca-common | [#9](https://github.com/mocachain/moca-common/pull/9) | 统一 btcd/btcec/v2 到 v2.3.4 |
| moca-juno | [#6](https://github.com/mocachain/moca-juno/pull/6) | 统一 btcd/btcec/v2 到 v2.3.4 |
| moca-go-sdk | [#9](https://github.com/mocachain/moca-go-sdk/pull/9) | 统一 btcd/btcec/v2 到 v2.3.4 |
| moca-cmd | [#9](https://github.com/mocachain/moca-cmd/pull/9) | 统一 btcd/btcec/v2 到 v2.3.4 |
| moca-storage-provider | [#11](https://github.com/mocachain/moca-storage-provider/pull/11) | 统一 btcd/btcec/v2 到 v2.3.4 |
| moca-callisto-juno | [#4](https://github.com/mocachain/moca-callisto-juno/pull/4) | 统一 btcd/btcec/v2 到 v2.3.4 |
| moca-callisto | [#25](https://github.com/mocachain/moca-callisto/pull/25) | 统一 btcd/btcec/v2 到 v2.3.4 |

### 未创建 PR 的仓库

| 仓库 | 原因 |
|------|------|
| moca-iavl | 无代码改动 |
| moca-cometbft-db | 无代码改动 |
| moca-relayer | 仓库已归档（只读） |

## Related
- [[CI Fixes Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
- [[build-pass-en|build-pass-en]]
