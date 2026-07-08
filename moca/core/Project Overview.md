---
title: Project Overview
aliases:
  - moca overview
  - project overview
tags:
  - moca
  - core
  - overview
type: guide
status: active
area: core
---

# Project Overview

> [!summary]
> Moca 是一个由链、存储服务、操作工具、索引层和跨仓测试环境共同组成的多仓系统，而不是单一代码仓库。

## What Moca Includes

- 链本体：`moca`
  - 提供 `mocad` 节点、链上模块、交易与查询 API
- Storage Provider 服务：`moca-storage-provider`
  - 提供对象存储、SP 节点、SP 网关与 SP 生命周期实现
- Operator CLI：`moca-cmd`
  - 提供账户、资产、bucket/object/group、policy、payment account、SP 等常见操作入口
- 索引与数据层：`moca-juno`、`moca-callisto-juno`、`moca-callisto`
  - 提供链数据抓取、加工和面向外部系统的查询能力
- 共享库与底层 fork：`moca-common`、`moca-go-sdk`、`moca-cosmos-sdk`、`moca-cometbft`、`moca-iavl`、`moca-ibc-go`、`go-ethereum`
- 开发与集成环境：`moca-devcontainer`、`moca-e2e`

## What This Core Section Does

- 统一描述 Moca 的长期知识，而不是当前某个 GitHub 组织的仓库布局
- 为 agent 提供稳定的项目心智模型，避免把“组织迁移”误当作“系统边界”
- 帮助开发者在进入具体 repo 前，先明确业务概念、架构分层和关键流程

## What This Core Section Does Not Do

- 不维护具体组织下的 repo 清单、workspace 脚本或任务档案
- 不替代 `mocachain/` 中的 repo 路由说明和专项任务记录
- 不把一次性的排障过程沉淀成长期知识，除非它已经上升为稳定规律

## Stable Mental Model

可以把 Moca 理解成五层：

1. 链协议与执行层
2. 存储与服务提供者层
3. 操作者工具层
4. 索引与数据消费层
5. 开发、测试与集成支撑层

不同组织下的 repo 位置可能变过，但这五层职责本身不应该随着组织迁移而改变。

## Related

- [[Core Home]]
- [[Domain Concepts]]
- [[System Architecture]]
- [[Precompile Architecture]]
- [[Validator Onboarding]]
- [[SP Lifecycle]]
