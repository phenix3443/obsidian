---
title: Repo - moca-common
type: repo
status: canonical
legacy_path: docs/repos/moca-common.md
tags:
  - repos
  - shared-lib
---

# Repo - moca-common

> [!summary]
> 跨仓共享 Go 库，集中放置多个 Moca 仓库都会复用的基础能力。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - moca-storage-provider]], [[Repo - moca-cmd]], [[Repo - moca-go-sdk]]

## Role

跨仓共享 Go 库，集中放置多个 Moca 仓库都会复用的基础能力。

## Entry Points

- `go/`
- `Makefile`
- `README.md`

## Common Commands

- `make build`

## Provided Contracts

- `shared-go-libs`

## Good Starting Points For Changes

- 多个 repo 都会用到的通用库
- 不适合直接塞进 `moca`、`moca-storage-provider`、`moca-cmd` 单仓的共享实现
