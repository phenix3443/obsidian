---
title: System Architecture
aliases:
  - architecture
  - moca architecture
tags:
  - moca
  - core
  - architecture
type: guide
status: active
area: core
---

# System Architecture

> [!summary]
> Moca 的核心结构是“链为中心，SP 和 CLI 围绕链运行，索引层消费链数据，测试环境把多仓组合成可验证拓扑”。

## Layered View

### Layer 1: Foundation Forks

- `moca-cosmos-sdk`
- `moca-cometbft`
- `moca-cometbft-db`
- `moca-iavl`
- `moca-ibc-go`
- `go-ethereum`

这一层提供链运行所依赖的底层框架与兼容能力。

### Layer 2: Core Chain

- `moca`

这一层提供链上模块、节点启动、查询与交易接口，是系统的主协议边界。

### Layer 3: Service And Tooling

- `moca-storage-provider`
- `moca-cmd`
- `moca-common`
- `moca-go-sdk`

这一层围绕链构建服务端实现、共享库和操作者工具。

### Layer 4: Data And Indexing

- `moca-juno`
- `moca-callisto-juno`
- `moca-callisto`

这一层消费链数据，并把它转换成更适合检索、聚合和外部消费的形式。

### Layer 5: Integration And Environment

- `moca-devcontainer`
- `moca-e2e`

这一层负责把多个 repo 组合成开发环境和回归验证拓扑。

## Repository Dependency Layers

下面这组依赖层描述的是 Moca 项目本体的稳定结构，不依赖具体 GitHub 组织，也不依赖某台机器上的本地 clone 路径。

- Layer 1（基础依赖）
  - `moca-cometbft`
  - `moca-iavl`
- Layer 2（核心 SDK）
  - `moca-cosmos-sdk`
  - 依赖 Layer 1
- Layer 3（扩展模块）
  - `moca-ibc-go`
  - 依赖 Layer 2
- Layer 4（核心应用）
  - `moca`
  - 依赖 Layer 2、Layer 3
  - 另外直接依赖 `moca-cometbft-db` 与 `go-ethereum`
- Layer 5（公共库 / 索引层）
  - `moca-common`
    - 依赖 Layer 2 和 Layer 4 `moca`
  - `moca-juno`
    - 依赖 Layer 2 和 Layer 4 `moca`
  - `moca-callisto-juno`
    - 依赖 Layer 2、Layer 3
- Layer 6（工具 / 服务共享层）
  - `moca-go-sdk`
  - 依赖 Layer 2、Layer 5、Layer 4
- Layer 7（上层应用）
  - `moca-cmd`
    - 依赖 Layer 6 `moca-go-sdk`
  - `moca-relayer`
    - 依赖 Layer 6 `moca-go-sdk`
  - `moca-storage-provider`
    - 依赖 Layer 6 `moca-go-sdk`、Layer 5 `moca-juno`
    - 在运行与开发场景中还会与 `moca`、`moca-common`、`moca-cosmos-sdk`、`moca-cometbft`、`go-ethereum` 协同
  - `moca-callisto`
    - 依赖 Layer 2、Layer 3、Layer 4、Layer 5 `moca-callisto-juno`
- Workspace 协调与集成层
  - `moca-e2e`
    - 依赖 `moca`、`moca-storage-provider`、`moca-cmd`、`moca-juno`
  - `moca-devcontainer`
    - 依赖 `moca`、`moca-storage-provider`、`moca-cmd`
  - 组织级协调仓
    - 依赖所有 repo，但它只属于具体组织工作区，不属于项目本体层

## Path Independence Note

- 不同组织和不同机器上的本地 clone 路径可以不同。
- `core/` 只记录 repo 名称、职责和依赖关系，不记录某个组织下的具体本地路径。
- 具体路径、workspace 清单和当前机器 checkout 状态，统一留在 `mocachain/` 这类组织资料区。

## Stable Contracts

- `moca-node-api`
  - 由 `moca` 提供，服务端实现、CLI、索引层和测试环境都会消费
- `storage-provider-api`
  - 由 `moca-storage-provider` 提供，CLI 和测试环境会消费
- `operator-cli`
  - 由 `moca-cmd` 提供，脚本、集成测试和人工运维会消费
- `indexer-pipeline`
  - 由索引层仓库提供，面向数据消费方
- `known-good-stack`
  - 由 `moca-e2e` 提供，用来固定跨仓组合的可验证基线

## Architectural Boundaries

- 项目本体知识和当前组织资料分开维护
  - 本体知识在 `core/`
  - 当前组织路由和任务在 `mocachain/`
- `workspace` 不是业务层
  - 它只是当前组织下协调多仓开发的入口
- 底层 fork 变更默认按跨仓影响处理
  - 因为最终都会汇入链、服务端、CLI 或集成环境

## Related

- [[Project Overview]]
- [[Domain Concepts]]
- [[Project Contracts]]
- [[Repo Capability Map]]
- [[Key Flows]]
- [[mocachain/areas/governance/Workspace Overview|Workspace Overview]]
