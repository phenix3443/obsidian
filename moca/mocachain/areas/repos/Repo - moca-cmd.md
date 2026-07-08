---
title: Repo - moca-cmd
type: repo
status: canonical
legacy_path: docs/repos/moca-cmd.md
tags:
  - repos
  - tooling
---

# Repo - moca-cmd

> [!summary]
> 与 `moca` chain 交互的客户端 CLI，封装账户、bank、bucket、object、group、policy、payment-account、SP 等链上与存储常见流程。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - moca]], [[Repo - moca-storage-provider]], [[Repo - moca-common]], [[Repo - moca-go-sdk]], [[Repo - moca-e2e]]

## Role

与 `moca` chain 交互的客户端 CLI，封装账户、bank、bucket、object、group、policy、payment-account、SP 等链上与存储常见流程。

## Entry Points

- `cmd/`
- `deployment/`
- `scripts/`
- `Makefile`

## Common Commands

- `make build`
- `make lint`
- `make build-docker`

## Provided Contracts

- `operator-cli`

## Consumed Contracts

- `moca-node-api`
- `storage-provider-api`
- `shared-go-libs`
- `forked-cosmos-sdk`
- `forked-cometbft`
- `forked-cometbft-db`
- `forked-iavl`
- `forked-ibc`
- `forked-go-ethereum`

## Good Starting Points For Changes

- CLI 子命令、交互体验、测试脚本依赖的命令格式
- bucket/object/group/sp/payment 相关操作流
- 与 `moca-go-sdk` 协同的调用封装
