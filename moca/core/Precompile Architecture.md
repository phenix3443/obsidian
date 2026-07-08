---
title: Precompile Architecture
aliases:
  - precompile architecture
  - moca precompile architecture
tags:
  - moca
  - core
  - architecture
  - precompile
type: guide
status: active
area: core
---

# Precompile Architecture

> [!summary]
> Moca 的 precompile 体系属于项目本体知识。这里记录长期有效的运行时模型、调用语义和迁移方向；具体实施计划与现场验证留在 `mocachain/tasks/precompile/`。

## Scope

这里讨论的是 `moca` 链内的 static precompile 体系，包括：

- precompile 的注册方式
- 执行运行时模型
- Cosmos 状态与 EVM `StateDB` 的协调方式
- `contract.Caller()`、`evm.Origin`、Cosmos `Msg` sender 之间的语义边界

## Current Architectural State

当前 Moca 已经基于 `cosmos/evm` 注册了一组 static precompile，但历史实现仍保留了较多自定义运行时逻辑。

稳定事实包括：

- `moca` 已使用 `cosmos/evm` 体系管理 EVM keeper
- 一组链定制 precompile 已作为 static precompile 激活
- 历史实现中，多个 precompile 仍保留手写的 cache context、snapshot、revert 与 commit 处理

因此，当前不是“有没有 precompile”，而是“precompile 是否已经完全对齐到 Cosmos EVM 原生模型”。

## Stable Problem Areas

### 1. Runtime Model Drift

如果每个 precompile 都各自维护一套 `Run()/CacheContext()/Snapshot()/commit()` 模板，就会出现：

- 运行时行为漂移
- 回滚语义不一致
- 升级 `cosmos/evm` 时兼容成本变高

### 2. Cosmos State And StateDB Reconciliation

涉及余额或状态副作用的 precompile，不能只关心 keeper 侧状态，也不能只关心 EVM 内存态。

长期有效的架构要求是：

- Cosmos 侧真实状态变化要可追踪
- EVM `StateDB` 侧可见状态要一致
- 两边应通过统一机制协调，而不是模块各自补丁式处理

### 3. Caller Semantics

Moca precompile 的长期难点之一是调用身份语义：

- `evm.Origin`
- `contract.Caller()`
- Cosmos `Msg` 中的 sender / operator / delegator / voter

这些语义如果混用，会导致：

- 审计边界不清
- 合约调用场景难以扩展
- 业务权限模型依赖历史兼容行为

## Target Model

长期目标应是对齐 Cosmos EVM 原生模式，而不是继续固化自定义兼容层。

### Runtime

- 统一使用 `cosmos/evm` 的 precompile 组织方式
- 统一 `Run -> Execute` 执行骨架
- 统一 ABI 分发、只读校验、gas 计量和 revert 语义

### Balance / State Synchronization

- 对有余额副作用的路径使用统一的 balance/state 协调模型
- 避免 keeper 状态与 `StateDB` 余额出现“双写但不同步”的结构性风险

### Caller Semantics

- 最终业务身份应以 direct caller 为中心，而不是长期依赖 `tx.origin`
- Cosmos `Msg` 的关键身份字段应与 direct caller 语义保持一致

## Stable Safety Constraint

在没有完整证明“原生币 value 与 keeper 侧资金变化能够安全一致同步”之前，precompile 不应默认接受 native value。

这条约束是长期有效的安全边界，不是某次任务的临时技巧。

## Module Groups

当前长期值得分组理解的 precompile 模块包括：

- 资金与账户相关
  - `bank`
- 治理与系统模块
  - `authz`
  - `gov`
  - `staking`
  - `distribution`
  - `slashing`
  - `permission`
- Moca 业务最强相关
  - `storage`
  - `payment`
  - `storageprovider`
  - `virtualgroup`

其中业务相关模块通常同时牵涉：

- keeper 状态变更
- 调用身份语义
- 复杂的回滚与一致性要求

## What Stays In Tasks

以下内容不属于本页，而应继续留在 `mocachain/tasks/precompile/`：

- 某次迁移的阶段拆分
- 某个版本的测试基线
- 某轮排障发现
- 某次 PR 或 commit 驱动的实施计划

## Related

- [[Core Home]]
- [[System Architecture]]
- [[Key Flows]]
- [[mocachain/areas/tasks/Precompile Index|Precompile Index]]
