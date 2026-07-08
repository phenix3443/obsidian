---
title: AGENTS
aliases:
  - agent rules
  - mocachain agents
tags:
  - mocachain
  - workspace
  - governance
type: guide
status: active
area: root
---

> [!summary]
> Stable agent and collaborator rules for the Moca workspace. The canonical Obsidian reading page is [[Collaboration Rules]], while this file remains the tool-facing anchor.

## Navigation

- Root: [[Home]]
- Section home: [[Mocachain Home]]
- Core knowledge: [[core/Core Home|Core Home]]
- Governance: [[Collaboration Rules]], [[Workspace Overview]], [[Contracts]], [[Routing Guide]]
- Repositories: [[Repos Index]]
- Tasks: [[Tasks Index]]

<claude-mem-context>
# Memory Context

# [mocachain] recent context, 2026-05-28 5:27pm GMT+8

No previous sessions found.
</claude-mem-context>

# Agent Rules

## 通用规则

### 改动原则

- 只做与当前任务直接相关的最小改动。
- 手动修复后必须立刻回写到源码、脚本或配置，不能只停留在终端操作。
- 不引入未被要求的新抽象、fallback 或大范围重排。
- 不覆盖、不回滚他人的在途改动，除非用户明确要求。

### 任务规划

- 修改代码前，必须先制定方案。
- 在方案明确前，不得开始实际代码修改。
- 方案确定后，必须先创建对应的 issue 和 PR，再在对应 PR 中实施改动。
- 当用户要求“记住某件事”时，先判断它是否属于长期有效的 workspace / 仓库协作规则；若属于，则同步写入对应的 `AGENTS.md`，若只是当前任务的临时上下文或一次性偏好，则不写入。

### Git 工作流

- 当提交 PR 后，必须持续进行 CR（代码审查）并处理发现的问题，直到没有 CR 问题为止。
- 当用户说“收尾这个 issue”时，默认必须依次执行：
  1. 更新对应 issue 和 PR 的标题、正文、必要评论，使其反映当前分支最新代码变化。
  2. 自动合并对应 PR，并关闭对应 issue。
  3. 将对应仓库本地分支切换回 `main`，同步最新远端代码，并清理已合并的本地功能分支与远程功能分支。
- 当 PR 已完成合并后，必须将对应仓库本地分支切换回 `main`，同步最新远端代码，并清理已合并的本地功能分支与远程功能分支。
- issue 和 PR 的标题、正文、评论中禁止出现本地绝对路径；如需引用方案或文档，只能使用仓库相对路径、GitHub 文件链接，或直接概述内容。

### 分支与提交

- 分支名必须是 `type/short-description`。
- `type` 仅允许：`feat`、`fix`、`chore`、`refactor`、`docs`、`test`。
- commit message 和 PR title 必须符合 Conventional Commits。
- 一个 PR 只做一个逻辑变更，不捆绑无关修改。

### 完成定义

任务完成前必须满足：

1. 相关验证、测试或构建命令已执行并通过；如果未执行，必须明确说明原因。
2. 如果修改影响架构、流程、接口、命令或协作约束，相关文档已同步更新。
3. 没有停留在终端里的临时修复。

## 项目相关规则

### Workspace 入口

本 workspace 的代码仓根目录是 `/Users/liushangliang/github/mocachain`。除非用户明确指定其他路径，所有仓库路由、依赖解析、代码修改和命令执行都应基于这个根目录，而不是其他同名或 fork 的工作区副本。

### Current Organization Scope

- 当前仓 `mocachain/` 只负责组织级协调：
  - `mocachain.code-workspace`
  - workspace 路由文档
  - 跨仓任务脚本
  - 历史任务沉淀
- 稳定的项目级 repo 职责请看 [[core/Repo Capability Map|Repo Capability Map]]
- 稳定的项目级 contract 边界请看 [[core/Project Contracts|Project Contracts]]
- bucket/object/group/policy/payment/virtual group 这类业务对象关系请看 [[core/Storage And Access Model|Storage And Access Model]]

### Local Path Notes

- `go-ethereum/` 默认路径是 `/Users/liushangliang/github/mocachain/go-ethereum`；若本机未 checkout，先确认路径
- `moca-go-sdk/` 默认路径是 `/Users/liushangliang/github/mocachain/moca-go-sdk`；若本机未 checkout，先确认路径

### Read Next

- `WORKSPACE.md`：当前组织工作区的路径、checkout 状态和本地路由建议。
- `areas/governance/Contracts.md`：当前组织自己的 workspace contract。
- `areas/repos/Repo - <name>.md`：当前工作区下单个 repo 的本地入口、命令、适用改动范围。
