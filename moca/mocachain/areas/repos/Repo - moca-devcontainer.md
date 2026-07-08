---
title: Repo - moca-devcontainer
type: repo
status: canonical
legacy_path: docs/repos/moca-devcontainer.md
tags:
  - repos
  - environment
---

# Repo - moca-devcontainer

> [!summary]
> 本地和多环境 Docker 测试环境，负责 validator、SP、helper CLI 容器的编排和基础测试脚本。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - moca]], [[Repo - moca-storage-provider]], [[Repo - moca-cmd]], [[Repo - moca-e2e]]

## Role

本地和多环境 Docker 测试环境，负责 validator、SP、helper CLI 容器的编排和基础测试脚本。

## Entry Points

- 根 `Makefile`
- `localnet/`
- `networks/`
- `tests/`
- `scripts/`

## Common Commands

- `make help`
- `make build-all`
- `make create-validator`
- `make create-sp`

## Provided Contracts

- `local-docker-topology`

## Consumed Contracts

- `moca-node-api`
- `storage-provider-api`
- `operator-cli`

## Good Starting Points For Changes

- 本地网络拓扑、节点和 SP 容器生命周期
- 依赖固定端口、环境变量或测试容器布局的问题
