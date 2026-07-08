---
title: WORKSPACE
aliases:
  - workspace
  - mocachain workspace legacy
tags:
  - mocachain
  - workspace
  - routing
type: guide
status: active
area: root
---

> [!summary]
> Legacy workspace entry for the current `mocachain` organization area. The canonical routing page is [[Workspace Overview]], while project-level knowledge now lives under [[core/Core Home|Core Home]].

## Navigation

- Root: [[Home]]
- Section home: [[Mocachain Home]]
- Core knowledge: [[core/Core Home|Core Home]]
- Governance: [[Workspace Overview]], [[Contracts]], [[Routing Guide]], [[Collaboration Rules]]
- Repositories: [[Repos Index]]
- Tasks: [[Tasks Index]]

# Workspace

## Repository list
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

## Dependency relations

- 项目级 repo 依赖分层已经移到 [[core/System Architecture|System Architecture]]。
- 当前页只保留当前组织工作区的本地路径、checkout 状态和 workspace 路由信息。

## Routing guidance
- 如果要先理解项目级 repo 分工，先看 [[core/Repo Capability Map|Repo Capability Map]]。
- 如果要先理解稳定 contract 边界，先看 [[core/Project Contracts|Project Contracts]]。
- 改链上模块、交易、节点启动、EVM/Cosmos 兼容逻辑，从 `moca/` 开始。
- 改 SP 注册、对象存储、SP 网关、SP 节点内部任务，从 `moca-storage-provider/` 开始。
- 改通过 CLI 发起的链上账户、转账、bucket/object/group、policy、payment-account、SP 查询等交互，从 `moca-cmd/` 开始。
- 改跨仓共享的通用 Go 能力，从 `moca-common/` 开始；如果是链底层框架能力，再看具体 fork 仓库。
- 改共识、SDK、IBC、状态树等底层框架时，从 `moca-cosmos-sdk/`、`moca-cometbft/`、`moca-iavl/`、`moca-ibc-go/`、`go-ethereum/` 中对应仓库开始，并准备跨仓验证。
- 改索引、链数据导出、面向 UI 的聚合数据，从 `moca-juno/`、`moca-callisto-juno/`、`moca-callisto/` 开始。
- 改本地环境编排、节点/SP 容器和多环境测试脚本，从 `moca-devcontainer/` 开始。
- 改跨仓回归、已知可用组合或集成冒烟，从 `moca-e2e/` 开始。
- 只改路由文档、workspace manifest、跨仓任务记录，从当前仓库 `.` 开始。

## Boundary notes
- 当前机器已经有 `go-ethereum/` 与 `moca-go-sdk/` checkout；修改前仍应确认消费方的 `replace` / 依赖关系是否与目标分支一致。
- 只改 `mocachain/` 下的任务沉淀、路由文档或 workspace 脚本，通常不需要触发跨 repo 验证。
- 改 `moca`、`moca-storage-provider`、`moca-cmd` 之间的接口时，至少要补做相关单仓验证，并优先考虑 `moca-e2e` 集成验证。
- 改 `moca-cosmos-sdk`、`moca-cometbft`、`moca-iavl`、`moca-ibc-go`、`go-ethereum` 等底层 fork 时，默认视为跨 repo 影响，需要回看 `moca`、`moca-storage-provider`、`moca-cmd` 的消费面。
