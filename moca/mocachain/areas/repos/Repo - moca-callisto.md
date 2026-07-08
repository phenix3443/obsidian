---
title: Repo - moca-callisto
type: repo
status: canonical
legacy_path: docs/repos/moca-callisto.md
tags:
  - repos
  - indexer
---

# Repo - moca-callisto

> [!summary]
> Moca 定制索引器，在 Juno 风格能力基础上增加面向 Moca UI/业务的数据处理。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - moca]], [[Repo - moca-juno]], [[Repo - moca-callisto-juno]], [[Repo - moca-e2e]]

## Role

Moca 定制索引器，在 Juno 风格能力基础上增加面向 Moca UI/业务的数据处理。

## Entry Points

- `cmd/bdjuno`
- `modules/`
- `database/`
- `hasura/`
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

- UI 或数据消费依赖的定制索引逻辑
- 在 `moca-juno` 之上叠加的 Moca 专属 handler / model / query
