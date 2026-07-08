---
title: Repo - mocachain
type: repo
status: canonical
legacy_path: docs/repos/mocachain.md
tags:
  - repos
  - workspace
---

# Repo - mocachain

> [!summary]
> 当前 `mocachain` 组织的协调仓库，不承载主业务代码，主要负责多仓入口、组织级路由文档、任务沉淀和 workspace 脚本。

## Navigation

- [[Mocachain Home]]
- [[Workspace Overview]]
- [[Contracts]]
- [[Repos Index]]
- Related: [[Repo - moca]], [[Repo - moca-storage-provider]], [[Repo - moca-cmd]], [[Repo - moca-e2e]]

## Role

当前 `mocachain` 组织的协调仓库，不承载主业务代码，主要负责多仓入口、组织级路由文档、任务沉淀和 workspace 脚本。

## Entry Points

- `mocachain.code-workspace`：多仓根清单。
- `scripts/workspace-sync-repos.sh`：按 workspace 批量切分支并拉取。
- `tasks/`：历史任务文档和脚本。
- `AGENTS.md`、`WORKSPACE.md`、`areas/`、`docs/repos/*`、`context.yaml`：共享上下文层。

## Common Commands

- `bash scripts/workspace-sync-repos.sh --dry-run`
- `bash scripts/workspace-sync-repos.sh -b main`

默认情况下，`scripts/workspace-sync-repos.sh` 会将大多数 repo 对齐到 `main`，但 `go-ethereum` 例外使用 `develop`。
工作区中的文档根 `obsidian` 条目不会参与同步。

## Provided Contracts

- `workspace-routing-docs`
- `workspace-manifest`

## Good Starting Points For Changes

- 新增或修正粗路由 / 精路由文档
- 调整 workspace 清单和批量脚本
- 记录跨仓任务计划、排障和沉淀

## Boundary Note

这里只回答“当前 `mocachain` 组织里该去哪个 repo / 文档”，不负责解释 Moca 项目本体知识；后者统一放在 [[core/Core Home|Core Home]]。
