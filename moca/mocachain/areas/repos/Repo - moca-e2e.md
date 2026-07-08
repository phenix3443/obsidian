---
title: Repo - moca-e2e
type: repo
status: canonical
legacy_path: docs/repos/moca-e2e.md
tags:
  - repos
  - testing
---

# Repo - moca-e2e

> [!summary]
> 跨仓集成测试中枢，维护 `stack.yaml` 已知可用组件组合，并在 CI 里跑端到端回归。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - moca]], [[Repo - moca-storage-provider]], [[Repo - moca-cmd]], [[Repo - moca-juno]], [[Repo - moca-callisto]], [[Repo - moca-devcontainer]]

## Role

跨仓集成测试中枢，维护 `stack.yaml` 已知可用组件组合，并在 CI 里跑端到端回归。

## Entry Points

- `stack.yaml`
- `Makefile`
- `scripts/`
- `tests/`
- `topology/`

## Common Commands

- `make test`
- `make test-minimal`
- `make test-stress`
- `make validate-stack`

## Provided Contracts

- `known-good-stack`

## Consumed Contracts

- `moca-node-api`
- `storage-provider-api`
- `operator-cli`
- `indexer-pipeline`

## Good Starting Points For Changes

- 跨仓集成冒烟
- stack 指针推进
- 需要验证多个仓库组合是否仍然可用的改动
