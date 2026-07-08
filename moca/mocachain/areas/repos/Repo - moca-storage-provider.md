---
title: Repo - moca-storage-provider
type: repo
status: canonical
legacy_path: docs/repos/moca-storage-provider.md
tags:
  - repos
  - storage
---

# Repo - moca-storage-provider

> [!summary]
> Storage Provider 实现，负责 SP 节点、对象存储、SP 网关、SP 链上注册和相关服务编排。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - moca]], [[Repo - moca-cmd]], [[Repo - moca-common]], [[Repo - moca-go-sdk]], [[Repo - moca-e2e]]

## Role

Storage Provider 实现，负责 SP 节点、对象存储、SP 网关、SP 链上注册和相关服务编排。

## Entry Points

- `cmd/`
- `base/`
- `modular/`
- `store/`
- `model/`
- `Makefile`

## Common Commands

- `make build`
- `make test`
- `make lint`

## Provided Contracts

- `storage-provider-api`

## Consumed Contracts

- `moca-node-api`
- `shared-go-libs`
- `forked-cosmos-sdk`
- `forked-cometbft`
- `forked-cometbft-db`
- `forked-iavl`
- `forked-ibc`
- `forked-go-ethereum`

## Good Starting Points For Changes

- bucket/object/group/payment/SP 生命周期
- SP 网关、SP 配置、后台任务和 SP 诊断
- 任何需要同时看链上 SP 模块和对象存储行为的任务
