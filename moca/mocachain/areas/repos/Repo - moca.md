---
title: Repo - moca
type: repo
status: canonical
legacy_path: docs/repos/moca.md
tags:
  - repos
  - chain
---

# Repo - moca

> [!summary]
> Moca 主链仓库，提供 `mocad` 二进制、链上模块、节点配置与查询/交易 API。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - mocachain]], [[Repo - moca-cosmos-sdk]], [[Repo - moca-cometbft]], [[Repo - moca-storage-provider]], [[Repo - moca-cmd]]

## Role

Moca 主链仓库，提供 `mocad` 二进制、链上模块、节点配置与查询/交易 API。

## Entry Points

- `cmd/mocad`
- `app/`
- `x/`
- `client/`
- `Makefile`

## Common Commands

- `make build`
- `make test`
- `make lint`

## Provided Contracts

- `moca-node-api`

## Consumed Contracts

- `forked-cosmos-sdk`
- `forked-cometbft`
- `forked-cometbft-db`
- `forked-iavl`
- `forked-go-ethereum`

## Good Starting Points For Changes

- 链上模块、参数、交易和查询逻辑
- 节点启动、链配置、EVM/Cosmos 兼容层
- 任何影响 `mocad` 的行为变更
