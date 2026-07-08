---
title: Repo - moca-juno
type: repo
status: canonical
legacy_path: docs/repos/moca-juno.md
tags:
  - repos
  - indexer
---

# Repo - moca-juno

> [!summary]
> 链数据索引聚合和导出层，为上层数据消费提供基础索引能力。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - moca]], [[Repo - moca-callisto]], [[Repo - moca-callisto-juno]], [[Repo - moca-e2e]]

## Role

链数据索引聚合和导出层，为上层数据消费提供基础索引能力。

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

- 索引抓取、解析和落库逻辑
- 需要看链数据导出而不是链执行本身的问题
