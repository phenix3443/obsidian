---
title: Repo - moca-go-sdk
type: repo
status: canonical
legacy_path: docs/repos/moca-go-sdk.md
tags:
  - repos
  - shared-lib
---

# Repo - moca-go-sdk

> [!summary]
> Go SDK，主要被 `moca-cmd` 和 `moca-storage-provider` 使用。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - mocachain]], [[Repo - moca-common]], [[Repo - moca-storage-provider]], [[Repo - moca-cmd]]

## Role

Go SDK，主要被 `moca-cmd` 和 `moca-storage-provider` 使用。

## Current Status

该仓库已出现在 `mocachain.code-workspace` 中，当前机器本地路径可用。

## Entry Points

- 以实际 checkout 后的 `README.md`、`go.mod`、核心包目录为准。

## Provided Contracts

- `shared-go-libs`

## Good Starting Points For Changes

- SDK 封装、共享客户端逻辑
- 同时被 CLI 和 SP 使用的调用模型

## Notes

开始修改前，先确认本地路径 `../../../mocachain/moca-go-sdk` 的分支与 `moca-cmd`、`moca-storage-provider` 当前消费关系一致。
