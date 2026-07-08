---
title: Repo - moca-callisto-juno
type: repo
status: canonical
legacy_path: docs/repos/moca-callisto-juno.md
tags:
  - repos
  - indexer
---

# Repo - moca-callisto-juno

> [!summary]
> Callisto 依赖的 Juno fork，是 Callisto 链路里的基础索引层。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - moca-juno]], [[Repo - moca-callisto]], [[Repo - moca]], [[Repo - moca-e2e]]

## Role

Callisto 依赖的 Juno fork，是 Callisto 链路里的基础索引层。

## Entry Points

- `cmd/juno`
- `modules/`
- `parser/`
- `database/`
- `Makefile`

## Common Commands

- `make build`
- `make test-unit`
- `make lint`

## Provided Contracts

- `indexer-pipeline`

## Consumed Contracts

- `moca-node-api`

## Good Starting Points For Changes

- Callisto 需要但主线 `moca-juno` 未覆盖的索引基础能力
- Callisto 链路的底层 parser / model / database 行为
