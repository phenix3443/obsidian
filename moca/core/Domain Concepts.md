---
title: Domain Concepts
aliases:
  - concepts
  - moca concepts
tags:
  - moca
  - core
  - domain
type: guide
status: active
area: core
---

# Domain Concepts

> [!summary]
> 这页定义 Moca 开发中反复出现的核心对象和术语，优先解决“这是什么、由谁负责、通常去哪个 repo 看”。

## Core Roles

- `validator`
  - 维护链共识与出块的节点角色，主要关注 `moca`
- `storage provider` / `SP`
  - 承接对象存储、SP 注册、SP 网关和链上协同的服务节点，主要关注 `moca-storage-provider`
- `operator`
  - 使用 CLI、脚本和运行环境执行链上与 SP 操作的人或自动化流程，主要关注 `moca-cmd`、`moca-devcontainer`、`moca-e2e`

## Core Data And Resource Concepts

- `account`
  - 用户或操作者在链上的身份与资产入口
- `bucket`
  - 对象存储的逻辑容器，通常是对象组织与访问控制的起点
- `object`
  - 被存储、查询、上传下载的具体数据对象
- `group`
  - 与对象、权限或协作边界相关的逻辑集合
- `policy`
  - 用于描述访问控制或操作约束的规则对象
- `payment account`
  - 与支付、计费或资源消费相关的链上账户或关系

## System Components

- `chain`
  - 指 `moca` 及其链上模块、节点接口和执行环境
- `SP gateway`
  - 对外暴露对象存储访问能力的 SP 侧入口
- `operator CLI`
  - 把链操作和 SP 操作封装成稳定命令行接口的工具层
- `indexer`
  - 把链数据抓取、转换后提供给外部系统消费的组件
- `workspace`
  - 当前组织下用于协调多仓开发、任务和脚本的文档与环境层，不等于 Moca 项目本体

## Practical Routing

- 看到 `transaction`、`module`、`RPC`、`gRPC`、`REST`、`JSON-RPC`
  - 先看 `moca`
- 看到 `SP`、`object storage`、`gateway`、`bucket/object/group/payment` 的服务端实现
  - 先看 `moca-storage-provider`
- 看到 `CLI`、操作者流程、自动化命令
  - 先看 `moca-cmd`
- 看到链数据导出、聚合查询、索引同步
  - 先看 `moca-juno`、`moca-callisto-juno`、`moca-callisto`
- 看到本地拓扑、已知可用组合、集成验证
  - 先看 `moca-devcontainer`、`moca-e2e`

## Related

- [[Project Overview]]
- [[Storage And Access Model]]
- [[System Architecture]]
- [[Key Flows]]
