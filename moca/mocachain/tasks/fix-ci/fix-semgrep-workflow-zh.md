---
title: "修复 Semgrep Workflow 中的 git diff 参数问题"
aliases:
  - fix-semgrep-workflow-zh
tags:
  - mocachain
  - task
  - ci-fixes
  - zh
  - fix-ci
  - ci
type: "task-note"
status: "archived"
area: "tasks"
topic: "ci-fixes"
language: "zh-CN"
source_path: "tasks/fix-ci/fix-semgrep-workflow-zh.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 CI Fixes，并补齐索引与语言导航。

## Navigation
- [[Tasks Index]]
- [[CI Fixes Index]]
- [[Topic Index]]
- [[Language Index]]
- [[fix-semgrep-workflow-en|fix-semgrep-workflow-en]]

---

# 修复 Semgrep Workflow 中的 git diff 参数问题

## 问题描述

`moca` 仓库的 `.github/workflows/semgrep.yml` 中，Semgrep 安全扫描从未真正执行过。
所有触发记录显示为 `skipped`，或在有代码变更的 PR 中直接 `FAILURE`。

## 根本原因

workflow 使用了 `technote-space/get-diff-action@v6.1.2` 来获取变更文件列表：

```yaml
- name: Get Diff
  uses: technote-space/get-diff-action@v6.1.2
  with:
    PATTERNS: |
      **/*.go
      **/*.js
      **/*.ts
      **/*.sol
      go.mod
      go.sum
```

然后用它输出的环境变量 `GIT_DIFF_FILTERED` 作为条件控制 semgrep 是否执行：

```yaml
- run: semgrep ci --config=auto
  env:
    SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
  if: "env.GIT_DIFF_FILTERED != ''"
```

这个设计存在两个问题：

**问题 1：`technote-space/get-diff-action` 已停止维护**

该仓库于 2023 年 11 月存档（archived），不再接受更新。

**问题 2：Node.js 版本不兼容导致 git diff 参数错误**

GitHub Actions runner 正在从 Node.js 20 迁移到 Node.js 24（2026 年 6 月 2 日强制切换）。
`get-diff-action@v6.1.2` 依赖 Node.js 20，在新环境下运行时内部传给 `git diff` 的参数出错，
git 无法识别这些参数，直接输出 help 信息并退出，导致：

- `GIT_DIFF_FILTERED` 始终为空
- semgrep 步骤被永久跳过（`skipped`）
- 或 action 本身报错导致整个 job `FAILURE`

PR #70（`chore: remove dead x/inflation module`）的日志中可以看到 git 输出了完整的 diff help 文档，
并有以下警告：

```
Node.js 20 actions are deprecated. The following actions are running on Node.js 20
and may not work as expected: actions/checkout@v4, technote-space/get-diff-action@v6.1.2.
```

## 修复方案

### 前提确认：SEMGREP_APP_TOKEN

`semgrep ci` 命令在连接 Semgrep 云平台时支持 diff-aware 扫描（只报告 PR 新引入的问题）。
这需要在仓库 `Settings → Secrets and variables → Actions` 中配置 `SEMGREP_APP_TOKEN`。

目前该 secret **未配置**，需要先确认：
- 是否有 Semgrep 账号（semgrep.dev）
- token 是否存在但未配入仓库

根据 token 是否可用，选择对应方案：

---

### 方案

直接删除 `get-diff-action` 步骤和 `if` 条件，`semgrep ci` 连接云平台后自动处理 diff-aware。

```yaml
name: Semgrep
on:
  pull_request: {}
  push:
    branches:
      - main
    paths:
      - .github/workflows/semgrep.yml
  schedule:
    - cron: "0 0 * * 0"
jobs:
  semgrep:
    name: Scan
    runs-on: ubuntu-latest
    container:
      image: returntocorp/semgrep
    if: (github.actor != 'dependabot[bot]')
    steps:
      - name: Permission issue fix
        run: git config --global --add safe.directory $GITHUB_WORKSPACE
      - uses: actions/checkout@v4
      - run: semgrep ci --config=auto
        env:
          SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
```

改动点：
- 删除 `get-diff-action` 步骤
- 删除重复的 `actions/checkout@v6`
- 删除 semgrep 步骤上的 `if` 条件
- 将 `actions/checkout@v6` 升级为 `@v4`（v6 不存在，原文件写错了）

---

## 验证方法

修复后，开一个包含 `.go` 文件改动的 PR，检查 Semgrep Scan job 状态：

```bash
# 查看 workflow 运行记录
gh run list --workflow=semgrep.yml --limit 5 --json conclusion,headBranch --jq '.[]'

# 查看具体 PR 的 Scan 状态
gh pr checks <PR号> --json name,state --jq '.[] | select(.name == "Scan")'
```

修复前：`conclusion: skipped` 或 `FAILURE`
修复后：`conclusion: success` 或 `failure`（failure 表示扫到问题，但证明扫描已正常执行）

## 相关文件

- `.github/workflows/semgrep.yml`

## 参考

- [Semgrep CI 文档](https://semgrep.dev/docs/semgrep-ci/sample-ci-configs)
- [technote-space/get-diff-action 存档说明](https://github.com/technote-space/get-diff-action)
- [GitHub Actions Node.js 20 废弃公告](https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/)

## Related
- [[CI Fixes Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
- [[fix-semgrep-workflow-en|fix-semgrep-workflow-en]]
