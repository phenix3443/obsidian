---
title: Repo - moca-cometbft-db
type: repo
status: canonical
legacy_path: docs/repos/moca-cometbft-db.md
tags:
  - repos
  - fork
---

# Repo - moca-cometbft-db

> [!summary]
> CometBFT DB fork，提供底层数据库适配和存储抽象。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - moca]], [[Repo - moca-storage-provider]], [[Repo - moca-cmd]], [[Repo - moca-cometbft]]

## Role

CometBFT DB fork，提供底层数据库适配和存储抽象。

## Entry Points

- 仓库根目录数据库实现文件
- `Makefile`

## Common Commands

- `make test`
- `make lint`

## Provided Contracts

- `forked-cometbft-db`

## Good Starting Points For Changes

- 底层 DB 适配
- 由 `moca`、`moca-storage-provider` 或 `moca-cmd` 间接暴露出来的 DB 行为问题
