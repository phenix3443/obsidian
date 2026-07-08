---
title: Key Flows
aliases:
  - moca flows
  - key flows
tags:
  - moca
  - core
  - flows
type: guide
status: active
area: core
---

# Key Flows

> [!summary]
> 这页记录 agent 最常需要理解的关键流程，用来决定“先去哪个系统边界看问题”。

## 1. Chain Transaction And Query Flow

- 主体仓库：`moca`
- 常见协同仓库：`moca-cmd`
- 适用场景：
  - 交易构造、提交、查询
  - 链上模块行为、参数和节点 API 变化
- 第一入口：
  - `moca/cmd/mocad`
  - `moca/app`
  - `moca/x`

## 2. Object Storage Flow

- 主体仓库：`moca-storage-provider`
- 常见协同仓库：`moca`、`moca-cmd`
- 适用场景：
  - bucket/object/group/payment 相关服务端行为
  - SP 网关、对象上传下载、后台任务
- 第一入口：
  - `moca-storage-provider/cmd`
  - `moca-storage-provider/modular`
  - `moca-storage-provider/store`

## 3. SP Lifecycle Flow

- 主体仓库：`moca-storage-provider`
- 常见协同仓库：`moca`、`moca-cmd`、`moca-e2e`
- 适用场景：
  - SP 注册、退出、运维、诊断
  - SP 与链上状态之间的一致性问题
- 第一入口：
  - `moca-storage-provider`
  - `moca-cmd`
  - `mocachain/tasks/` 下对应专项记录
- 长期知识：
  - [[SP Lifecycle]]

## 4. Validator And Network Operations Flow

- 主体仓库：`moca`
- 常见协同仓库：`moca-devcontainer`、`moca-e2e`
- 适用场景：
  - validator 节点、网络拓扑、节点启动参数、主网/测试网运维
- 第一入口：
  - `moca`
  - `moca-devcontainer`
  - `mocachain/tasks/mainnet/`
- 长期知识：
  - [[Validator Onboarding]]

## 5. Precompile And Protocol Extension Flow

- 主体仓库：`moca`
- 常见协同仓库：`mocachain/tasks/precompile/`
- 适用场景：
  - static precompile 运行时模型
  - caller / `tx.origin` 语义
  - Cosmos 状态与 EVM `StateDB` 协调
- 第一入口：
  - `moca/x/evm/precompiles`
  - [[Precompile Architecture]]

## 6. Indexing And Data Export Flow

- 主体仓库：`moca-juno`、`moca-callisto-juno`、`moca-callisto`
- 常见协同仓库：`moca`
- 适用场景：
  - 链数据抓取、聚合和对外查询
  - 面向 UI 或外部消费方的数据问题
- 第一入口：
  - 各 repo 的 `cmd/juno` 或 `cmd/bdjuno`

## 7. Integration And Known-Good Stack Flow

- 主体仓库：`moca-e2e`
- 常见协同仓库：`moca-devcontainer`
- 适用场景：
  - 跨仓回归
  - 已知可用组合
  - 环境级验证
- 第一入口：
  - `moca-e2e/stack.yaml`
  - `moca-e2e/tests`
  - `moca-devcontainer/localnet`

## Related

- [[Domain Concepts]]
- [[System Architecture]]
- [[Precompile Architecture]]
- [[Validator Onboarding]]
- [[SP Lifecycle]]
- [[mocachain/Mocachain Home|Mocachain Home]]
