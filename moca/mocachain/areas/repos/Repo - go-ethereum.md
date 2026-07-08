---
title: Repo - go-ethereum
type: repo
status: canonical
legacy_path: docs/repos/go-ethereum.md
tags:
  - repos
  - fork
---

# Repo - go-ethereum

> [!summary]
> Moca 定制的 go-ethereum fork，为链和周边组件提供 EVM / JSON-RPC 兼容层。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - mocachain]], [[Repo - moca]], [[Repo - moca-storage-provider]], [[Repo - moca-cmd]]

## Role

Moca 定制的 go-ethereum fork，为链和周边组件提供 EVM / JSON-RPC 兼容层。

## Current Status

该仓库已出现在 `mocachain.code-workspace` 中，当前机器本地路径可用；同步脚本默认会把它对齐到 `develop`。

## Entry Points

- 以实际 checkout 后的 `README.md`、`Makefile`、核心包目录为准。

## Provided Contracts

- `forked-go-ethereum`

## Good Starting Points For Changes

- EVM 兼容层问题
- JSON-RPC、账户、交易和其他 go-ethereum 侧行为

## Notes

开始修改前，先确认本地路径 `../../../mocachain/go-ethereum` 的当前分支与目标消费方兼容，并注意同步脚本默认会把它对齐到 `develop`。
