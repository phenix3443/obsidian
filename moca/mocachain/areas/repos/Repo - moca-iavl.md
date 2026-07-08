---
title: Repo - moca-iavl
type: repo
status: canonical
legacy_path: docs/repos/moca-iavl.md
tags:
  - repos
  - fork
---

# Repo - moca-iavl

> [!summary]
> IAVL fork，负责状态树与相关存储结构。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - moca]], [[Repo - moca-storage-provider]], [[Repo - moca-cmd]]

## Role

IAVL fork，负责状态树与相关存储结构。

## Entry Points

- `cmd/`
- `db/`
- `fastnode/`
- `proto/`
- `Makefile`

## Common Commands

- `make build`
- `make test`
- `make lint`

## Provided Contracts

- `forked-iavl`

## Good Starting Points For Changes

- 状态树存储、索引和性能相关问题
- 被 `moca` 和相关链组件共享消费的 IAVL 行为
