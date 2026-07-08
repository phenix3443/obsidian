---
title: Project Contracts
aliases:
  - contract map
  - moca contracts
tags:
  - moca
  - core
  - contracts
  - architecture
type: guide
status: active
area: core
---

# Project Contracts

> [!summary]
> Moca 的稳定系统边界可以用一组跨仓 contract 来理解。它们属于项目本体，不应该随着 GitHub 组织迁移而改变。

## Stable Contract List

| Contract | Provider | Main Consumers | 说明 |
| --- | --- | --- | --- |
| `moca-node-api` | `moca` | `moca-storage-provider` `moca-cmd` `moca-juno` `moca-callisto` `moca-e2e` `moca-devcontainer` | 链上交易、查询、节点配置与多种 API 的主协议边界。 |
| `storage-provider-api` | `moca-storage-provider` | `moca-cmd` `moca-e2e` `moca-devcontainer` | 对象上传下载、SP 管理、SP 诊断的服务边界。 |
| `operator-cli` | `moca-cmd` | `moca-e2e` `moca-devcontainer` 人工运维流程 | 操作者执行链上与 SP 常见动作的命令行边界。 |
| `shared-go-libs` | `moca-common` `moca-go-sdk` | `moca-storage-provider` `moca-cmd` | 被多个上层仓库复用的共享 Go 能力。 |
| `forked-chain-libraries` | `moca-cosmos-sdk` `moca-cometbft` `moca-cometbft-db` `moca-iavl` `moca-ibc-go` `go-ethereum` | `moca` `moca-storage-provider` `moca-cmd` | 定制链框架与兼容层。 |
| `indexer-pipeline` | `moca-juno` `moca-callisto-juno` `moca-callisto` | 外部数据消费方、本地测试环境 | 链数据抓取、加工与查询暴露边界。 |
| `known-good-stack` | `moca-e2e` | 各源仓 CI、发布前回归 | 跨仓已知可用 ref 组合与集成验证基线。 |

## Impact Heuristics

### 改 `moca-node-api`

- 默认按跨仓变更处理
- 至少联动检查 `moca-storage-provider`、`moca-cmd`、索引层和 E2E

### 改 `storage-provider-api`

- 至少联动检查 `moca-cmd`、`moca-e2e`、`moca-devcontainer`
- 如果问题落在 bucket/object/group/payment/SP 行为，通常还要回看 [[Storage And Access Model]]

### 改 `forked-chain-libraries`

- 默认影响 `moca`
- 很多变更会继续传导到 `moca-storage-provider`、`moca-cmd`
- 即使单仓编译通过，也不代表集成面安全

### 改 `known-good-stack`

- 重点看 `moca-e2e/stack.yaml` 指针推进是否与目标变更匹配
- 它更像“跨仓验证基线”而不是业务逻辑入口

## What Is Not In This Page

- 当前机器上的本地 clone 路径
- 当前组织下的 workspace manifest
- 某次任务档案、排障记录、临时脚本

这些内容属于 `mocachain/`。

## Related

- [[Core Home]]
- [[System Architecture]]
- [[Repo Capability Map]]
- [[Storage And Access Model]]
- [[mocachain/areas/governance/Contracts|Contracts]]
