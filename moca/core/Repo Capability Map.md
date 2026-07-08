---
title: Repo Capability Map
aliases:
  - repo map
  - capability map
  - moca repo roles
tags:
  - moca
  - core
  - repos
  - routing
type: guide
status: active
area: core
---

# Repo Capability Map

> [!summary]
> 这页回答“某类问题通常先看哪个 repo”。它描述的是项目级能力分工，不依赖某个组织下的本地路径布局。

## Core Chain And Runtime

- `moca`
  - 链上模块、`mocad`、交易与查询 API、EVM/Cosmos 兼容层
- `moca-cosmos-sdk`
  - Moca 定制 SDK 框架能力
- `moca-cometbft`
  - 共识与节点网络层
- `moca-cometbft-db`
  - 底层数据库适配
- `moca-iavl`
  - 状态树存储
- `moca-ibc-go`
  - IBC 协议层
- `go-ethereum`
  - EVM / JSON-RPC / 兼容层相关 fork

## Storage And Operator Surface

- `moca-storage-provider`
  - SP 节点、对象存储、SP 网关、SP 注册与运维
- `moca-cmd`
  - 操作者 CLI，封装账户、bank、bucket/object/group、policy、payment-account、SP 等常见流程
- `moca-common`
  - 多仓共享 Go 工具与公共实现
- `moca-go-sdk`
  - 上层工具与服务复用的 Go SDK

## Data And Query Surface

- `moca-juno`
  - 基础链数据索引、解析与导出
- `moca-callisto-juno`
  - Callisto 使用的 Juno 侧 fork / 扩展
- `moca-callisto`
  - 面向 UI / 业务的数据加工与查询扩展

## Integration And Environment

- `moca-devcontainer`
  - 本地 validator / SP / CLI 的环境编排
- `moca-e2e`
  - 跨仓已知可用组合、集成测试与回归验证

## Practical Routing

- 改链执行、节点行为、模块 keeper、RPC/gRPC/REST/JSON-RPC
  - 从 `moca` 开始
- 改 bucket/object/group/policy/payment/SP 服务端行为
  - 从 `moca-storage-provider` 开始
- 改操作者命令、脚本依赖的命令格式、CLI 交互流
  - 从 `moca-cmd` 开始
- 改链数据导出、索引落库、面向 UI 的聚合查询
  - 从 `moca-juno` / `moca-callisto` 开始
- 改底层共识、SDK、状态树、IBC、EVM 兼容框架
  - 从对应 fork 仓库开始
- 改跨仓冒烟、stack 指针、环境级回归
  - 从 `moca-e2e` 或 `moca-devcontainer` 开始

## Boundary Note

- 当前页定义“项目能力归属”。
- 当前组织下这些 repo 在哪、当前机器有没有 clone、该从哪个相对路径进入，统一留在 `mocachain/`。

## Related

- [[Core Home]]
- [[Project Overview]]
- [[System Architecture]]
- [[Project Contracts]]
- [[mocachain/areas/repos/Repos Index|Repos Index]]
