---
title: Repo - moca-cometbft
type: repo
status: canonical
legacy_path: docs/repos/moca-cometbft.md
tags:
  - repos
  - fork
---

# Repo - moca-cometbft

> [!summary]
> Moca 定制的 CometBFT fork，负责共识、节点网络、区块同步等底层能力。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - moca]], [[Repo - moca-storage-provider]], [[Repo - moca-cmd]], [[Repo - moca-cometbft-db]]

## Role

Moca 定制的 CometBFT fork，负责共识、节点网络、区块同步等底层能力。

## Entry Points

- `cmd/`
- `abci/`
- `consensus/`
- `node/`
- `config/`
- `Makefile`

## Common Commands

- `make build`
- `make test`
- `make lint`

## Provided Contracts

- `forked-cometbft`

## Good Starting Points For Changes

- 共识相关问题
- 节点网络、同步、配置或运维行为
- `moca` 上游依赖但不应直接在 `moca` 里修的底层问题
