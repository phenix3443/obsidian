---
title: Repo - moca-cosmos-sdk
type: repo
status: canonical
legacy_path: docs/repos/moca-cosmos-sdk.md
tags:
  - repos
  - fork
---

# Repo - moca-cosmos-sdk

> [!summary]
> Moca 定制的 Cosmos SDK fork，是主链和周边组件的底层框架之一。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - moca]], [[Repo - moca-storage-provider]], [[Repo - moca-cmd]], [[Repo - moca-ibc-go]]

## Role

Moca 定制的 Cosmos SDK fork，是主链和周边组件的底层框架之一。

## Entry Points

- `api/`
- `client/`
- `x/`
- `baseapp/`
- `Makefile`

## Common Commands

- `make build`
- `make test`
- `make lint`

## Provided Contracts

- `forked-cosmos-sdk`

## Good Starting Points For Changes

- Cosmos SDK 底层能力、模块框架、地址格式、签名兼容性
- 会被 `moca`、`moca-storage-provider`、`moca-cmd` 共同消费的基础行为
