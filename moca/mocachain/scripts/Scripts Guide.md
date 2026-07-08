---
title: Scripts Guide
aliases:
  - scripts guide
  - mocachain scripts
tags:
  - mocachain
  - scripts
  - governance
type: guide
status: active
area: root
---

# Scripts Guide

> [!summary]
> `mocachain/scripts/` 只保存当前组织范围内可复用的通用脚本。任何只服务于单个专项或单类开发任务的脚本，都应跟随对应任务放在 `mocachain/tasks/<task>/scripts/`。

## Classification Rules

- 组织级通用脚本
  - 放在 `mocachain/scripts/`
  - 例如 workspace 同步、跨任务共用的组织级工具
- 任务级脚本
  - 放在 `mocachain/tasks/<task>/scripts/`
  - 例如某次 validator 快照、SP 升级、SP 同步、专项排障所需脚本
- 长期项目知识
  - 不放在 `scripts/`
  - 应沉淀到 `core/` 或 `mocachain/areas/` 中对应的文档页

## Current Organization-Level Scripts

- `workspace-sync-repos.sh`
  - 依据 `mocachain.code-workspace` 批量切换并同步当前组织下的多仓代码
  - 会跳过工作区里的文档根 `obsidian` 条目，只处理代码仓

## Related

- [[Home]]
- [[Mocachain Home]]
- [[Repo - mocachain]]
