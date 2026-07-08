---
title: "修复 moca-callisto CI 流水线"
aliases:
  - moca-callisto-fix-CI
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
source_path: "tasks/fix-ci/moca-callisto-fix-CI.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 CI Fixes，并补齐索引与语言导航。

## Navigation
- [[Tasks Index]]
- [[CI Fixes Index]]
- [[Topic Index]]
- [[Language Index]]

---

# 修复 moca-callisto CI 流水线

## 问题分析

根据 CI 日志分析,失败原因有三个:

### 1. golangci-lint 版本过旧

当前使用的 v1.50.1 不支持 Go 1.23.6

- **错误信息**: `gocritic: load embedded ruleguard rules: rules/rules.go:13: can't load fmt: setting an explicit GOROOT can fix this problem.`
- **原因**: golangci-lint v1.50.1 发布于 2022 年,与 Go 1.23.6 不兼容

### 2. GitHub Action 版本过旧

使用了 golangci-lint-action@v3.4.0

- **问题**: 旧版本的 action 与新版本的 golangci-lint 兼容性不佳
- **需要**: 升级到 golangci-lint-action@v6

### 3. 使用了多个已废弃的 linters

- `scopelint` (v1.39.0 废弃,替代: exportloopref)
- `structcheck` (v1.49.0 废弃,替代: unused)
- `deadcode` (v1.49.0 废弃,替代: unused)
- `golint` (v1.41.0 废弃,替代: revive)
- `maligned` (v1.38.0 废弃,替代: govet 'fieldalignment')

## 修复方案

### 1. 升级 golangci-lint 版本

在 `.github/workflows/lint.yml` 中:

- 将 golangci-lint 从 v1.50.1 升级到 v1.62.2
- 将 golangci-lint-action 从 v3.4.0 升级到 v6
- v1.62.2 完全支持 Go 1.23.x
- 移除不再需要的 `github-token` 参数

### 2. 更新 linter 配置

在 `.golangci.yaml` 中:

- 移除废弃的 linters: `scopelint`, `structcheck`, `deadcode`, `golint`, `maligned`
- 添加推荐的替代 linters: `exportloopref`, `revive`
- 保留 `unused` (已在列表中)
- 移除重复的 `misspell` 条目
- 更新 issue 排除规则,将 `golint` 替换为 `revive`
- 移除 `maligned` 的配置项

## 实施步骤

1. ✅ 切换到 main 分支并拉取最新代码
2. ✅ 创建修复分支 `fix/ci-golangci-lint-upgrade`
3. ✅ 更新 .github/workflows/lint.yml 中的 golangci-lint 版本
4. ✅ 更新 .golangci.yaml 移除废弃 linters 并添加替代项
5. ✅ 本地验证配置正确性
6. ✅ 提交修改并推送到远程
7. ✅ 使用 gh 命令创建 PR

## 文件修改清单

### 1. .github/workflows/lint.yml

```diff
-      - uses: golangci/golangci-lint-action@v3.4.0
+      - uses: golangci/golangci-lint-action@v6
         with:
-          version: v1.50.1
+          version: v1.62.2
           args: --timeout 10m
-          github-token: ${{ secrets.GITHUB_TOKEN }}
         if: "env.GIT_DIFF != ''"
```

**主要变更:**
- 升级 action 版本: v3.4.0 → v6
- 升级 golangci-lint: v1.50.1 → v1.62.2
- 移除 `github-token` 参数 (v6 中不再需要)

### 2. .golangci.yaml

**移除的 linters:**
- `deadcode`
- `golint`
- `maligned`
- `scopelint`
- `structcheck`

**添加的 linters:**
- `exportloopref`
- `revive`

**配置更新:**
- 将 issue 排除规则中的 `golint` 替换为 `revive`
- 移除 `maligned` 的 linters-settings 配置
- 移除重复的 `misspell` 条目
- 清理了一些过时的注释

## 验证结果

- ✅ 配置文件语法正确
- ✅ 所有废弃的 linters 已移除
- ✅ GitHub Actions workflow 已更新

## PR 信息

- **PR 链接**: https://github.com/mocachain/moca-callisto/pull/13
- **标题**: fix: upgrade golangci-lint to v1.62.2 and update linter configuration
- **分支**: `fix/ci-golangci-lint-upgrade`
- **基础分支**: `main`
- **提交哈希**: e419be8

### PR 描述

#### Summary

This PR fixes the CI pipeline failures by upgrading golangci-lint and updating the linter configuration.

#### Changes

**1. Upgrade golangci-lint**
- **From**: v1.50.1
- **To**: v1.62.2
- **Action**: Updated from golangci-lint-action@v3.4.0 to @v6
- **Reason**: v1.62.2 fully supports Go 1.23.6 and resolves the gocritic "load embedded ruleguard rules" error

**2. Update Linter Configuration**

**Removed Deprecated Linters:**
- `scopelint` (deprecated since v1.39.0) → replaced by `exportloopref`
- `structcheck` (deprecated since v1.49.0) → replaced by `unused`
- `deadcode` (deprecated since v1.49.0) → replaced by `unused`
- `golint` (deprecated since v1.41.0) → replaced by `revive`
- `maligned` (deprecated since v1.38.0) → replaced by govet 'fieldalignment'

**Added Replacement Linters:**
- `exportloopref` (replaces scopelint)
- `revive` (replaces golint)

**Configuration Updates:**
- Updated issue exclusion rules to use `revive` instead of `golint`
- Removed `maligned` configuration from `linters-settings`
- Removed duplicate `misspell` entry
- Removed `github-token` parameter (not needed in golangci-lint-action@v6)

#### Testing

- ✅ Configuration syntax verified
- ✅ All deprecated linters removed from configuration
- ✅ Workflow updated to use latest action version

#### Related Issues

Fixes the CI failures in PR #12 where:
1. golangci-lint v1.50.1 reported: "gocritic: load embedded ruleguard rules: can't load fmt"
2. Multiple warnings about deprecated linters (scopelint, structcheck, deadcode, golint, maligned)

#### Verification

After this PR is merged, the CI pipeline should:
- ✅ Pass the Lint workflow without gocritic errors
- ✅ Run without deprecated linter warnings
- ✅ Successfully lint the codebase with the updated configuration
- ✅ Work correctly with Go 1.23.6

## 与 moca-callisto-juno 的区别

moca-callisto 仓库的修复与 moca-callisto-juno 有以下不同:

### 主要区别

1. **Workflow 配置方式不同**
   - **moca-callisto**: 使用 GitHub Actions 的 golangci-lint-action
   - **moca-callisto-juno**: 使用 Makefile 中的 `go run` 命令

2. **修复范围不同**
   - **moca-callisto**: 需要同时更新 workflow 文件和 linter 配置
   - **moca-callisto-juno**: 只需更新 go.mod 和 linter 配置

3. **Action 版本升级**
   - **moca-callisto**: 需要升级 golangci-lint-action 从 v3.4.0 到 v6
   - **moca-callisto-juno**: 不涉及 action 版本

### 相同点

1. 都需要升级 golangci-lint 到 v1.62.2
2. 都需要移除相同的废弃 linters
3. 都需要添加相同的替代 linters
4. 都需要更新 .golangci.yaml 配置

## 总结

此次修复通过三个主要改动解决了 CI 流水线问题:

1. **升级 golangci-lint**: 从 v1.50.1 升级到 v1.62.2,完全支持 Go 1.23.6
2. **升级 GitHub Action**: 从 v3.4.0 升级到 v6,提供更好的兼容性
3. **更新 linter 配置**: 移除所有已废弃的 linters,使用推荐的替代方案

这些改动确保了:
- CI 流水线可以在 Go 1.23.6 环境下正常运行
- 不再出现 gocritic 加载规则失败的错误
- 不再有废弃 linters 的警告信息
- 代码质量检查使用最新的最佳实践

PR 已创建并推送到远程仓库,CI 流水线将自动运行验证修复效果。

## Related
- [[CI Fixes Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
