---
title: Workspace Overview
aliases:
  - workspace overview
  - mocachain workspace
tags:
  - mocachain
  - workspace
  - governance
  - routing
type: guide
status: active
area: governance
---

# Workspace Overview

> [!summary]
> Current `mocachain` organization workspace overview. This page covers the active multi-repo layout, dependency layers, and routing guidance for the present organization view, not the full Moca domain knowledge set.

## Navigation

- Root: [[Home]]
- Section home: [[Mocachain Home]]
- Core knowledge: [[core/Core Home|Core Home]]
- Governance: [[Contracts]], [[Routing Guide]], [[Collaboration Rules]]
- Repo index: [[Repos Index]]
- Task index: [[Tasks Index]]
- Scripts guide: [[mocachain/scripts/Scripts Guide|Scripts Guide]]
- Legacy anchors: [[WORKSPACE]], [[AGENTS]]

## Repository List

- 以下路径只是当前 `mocachain` 组织工作区在这台机器上的相对路径示例。
- 不同组织或不同机器上的本地 clone 路径可以不同；项目级依赖结构请看 [[core/System Architecture|System Architecture]]。
- `.`：当前 `mocachain` 组织的协调仓库，保存 `mocachain.code-workspace`、组织级路由文档、任务脚本和任务沉淀。
- `../../../github/mocachain/moca`：Moca 主链实现，主入口是 `cmd/mocad`，负责链上模块、节点启动和链 API。
- `../../../github/mocachain/moca-storage-provider`：Storage Provider 服务实现，主入口是 `cmd/` 与 SP 相关模块目录。
- `../../../github/mocachain/moca-cmd`：与 `moca` chain 交互的客户端 CLI，主入口是 `cmd/*.go`，覆盖账户、bank、bucket、object、group、policy、payment-account、sp 等链上与存储请求。
- `../../../github/mocachain/moca-common`：跨仓共享 Go 库，主入口是 `go/`。
- `../../../github/mocachain/moca-cosmos-sdk`：Moca 定制 Cosmos SDK fork。
- `../../../github/mocachain/moca-cometbft`：Moca 定制 CometBFT fork。
- `../../../github/mocachain/moca-cometbft-db`：CometBFT DB fork。
- `../../../github/mocachain/moca-iavl`：IAVL fork。
- `../../../github/mocachain/moca-ibc-go`：IBC fork。
- `../../../github/mocachain/moca-juno`：链数据索引与导出层，主入口是 `cmd/juno`。
- `../../../github/mocachain/moca-callisto`：Moca 定制索引器，主入口是 `cmd/bdjuno`。
- `../../../github/mocachain/moca-callisto-juno`：Callisto 使用的 Juno fork，主入口是 `cmd/juno`。
- `../../../github/mocachain/moca-devcontainer`：本地和多环境 Docker 测试环境，入口是根 `Makefile` 与 `localnet/`。
- `../../../github/mocachain/moca-e2e`：跨仓 E2E hub，入口是根 `Makefile`、`scripts/`、`tests/`、`stack.yaml`。
- `../../../github/mocachain/go-ethereum`：Moca 定制 go-ethereum fork；当前机器已 checkout，且同步脚本默认跟随 `develop`。
- `../../../github/mocachain/moca-go-sdk`：Go SDK；当前机器已 checkout，被 `moca-cmd` 与 `moca-storage-provider` 引用。

## Dependency Relations

- 项目级 repo 依赖分层已经移到 [[core/System Architecture|System Architecture]]。
- 当前页只保留当前组织工作区的本地路径、checkout 状态和 workspace 路由信息。

## Routing Guidance

- 如果要先理解“这些 repo 在项目里各自负责什么”，先看 [[core/Repo Capability Map|Repo Capability Map]]。
- 如果要先理解稳定 contract 边界，先看 [[core/Project Contracts|Project Contracts]]。
- 改链上模块、交易、节点启动、EVM/Cosmos 兼容逻辑，从 `moca/` 开始。
- 改 SP 注册、对象存储、SP 网关、SP 节点内部任务，从 `moca-storage-provider/` 开始。
- 改通过 CLI 发起的链上与存储交互，从 `moca-cmd/` 开始。
- 改跨仓共享 Go 能力，从 `moca-common/` 开始；链底层框架能力看对应 fork 仓库。
- 改共识、SDK、IBC、状态树等底层框架时，从 `moca-cosmos-sdk/`、`moca-cometbft/`、`moca-iavl/`、`moca-ibc-go/`、`go-ethereum/` 中对应仓库开始。
- 改索引、链数据导出、面向 UI 的聚合数据，从 `moca-juno/`、`moca-callisto-juno/`、`moca-callisto/` 开始。
- 改本地环境编排和多环境测试脚本，从 `moca-devcontainer/` 开始。
- 改跨仓回归和集成冒烟，从 `moca-e2e/` 开始。
- 只改路由文档、workspace manifest、跨仓任务记录，从当前仓库 `.` 开始。

## Boundary Notes

> [!info]
> 当前机器已经有 `go-ethereum/` 与 `moca-go-sdk/` checkout；修改前仍应确认消费方依赖和目标分支是否匹配。

- 只改 `mocachain/` 下的任务沉淀、路由文档或 workspace 脚本，通常不需要触发跨 repo 验证。
- 改 `moca`、`moca-storage-provider`、`moca-cmd` 之间的接口时，至少要补做相关单仓验证，并优先考虑 `moca-e2e` 集成验证。
- 改底层 fork 时，默认视为跨 repo 影响，需要回看 `moca`、`moca-storage-provider`、`moca-cmd` 的消费面。

## Related

- [[WORKSPACE]]
- [[Contracts]]
- [[Routing Guide]]
- [[Repos Index]]
