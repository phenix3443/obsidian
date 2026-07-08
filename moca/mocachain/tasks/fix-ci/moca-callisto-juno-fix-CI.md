---
title: "修复 moca-callisto-juno CI 流水线"
aliases:
  - moca-callisto-juno-fix-CI
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
source_path: "tasks/fix-ci/moca-callisto-juno-fix-CI.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 CI Fixes，并补齐索引与语言导航。

## Navigation
- [[Tasks Index]]
- [[CI Fixes Index]]
- [[Topic Index]]
- [[Language Index]]

---

# 修复 moca-callisto-juno CI 流水线

## 问题分析

根据 CI 日志分析,失败原因有两个:

### 1. golangci-lint 版本不兼容

当前使用的 v1.53.3 不支持 Go 1.23.6

- **错误信息**: `gocritic: invalid Go version format: 1.23.6`
- **原因**: golangci-lint v1.53.3 发布于 2023 年,不识别 Go 1.23.x 格式

### 2. 使用了多个已废弃的 linters

- `scopelint` (v1.39.0 废弃,替代: exportloopref)
- `structcheck` (v1.49.0 废弃,替代: unused)
- `deadcode` (v1.49.0 废弃,替代: unused)
- `golint` (v1.41.0 废弃,替代: revive)
- `maligned` (v1.38.0 废弃,替代: govet 'fieldalignment')

## 修复方案

### 1. 升级 golangci-lint 版本

在 `go.mod` 中将 golangci-lint 从 v1.53.3 升级到 v1.62.2:

- v1.62.2 完全支持 Go 1.23.x
- 发布于 2025 年初,稳定可靠

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
3. ✅ 在 go.mod 中升级 golangci-lint 到 v1.62.2
4. ✅ 更新 .golangci.yaml 移除废弃 linters 并添加替代项
5. ✅ 运行 `go mod tidy` 和本地 lint 验证
6. ✅ 提交修改并推送到远程
7. ✅ 使用 gh 命令创建 PR

## 文件修改清单

### 1. go.mod

```diff
-	github.com/golangci/golangci-lint v1.53.3
+	github.com/golangci/golangci-lint v1.62.2
```

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

## 验证结果

- ✅ `go mod tidy` 成功更新依赖
- ✅ golangci-lint v1.62.2 已验证支持 Go 1.23.6
- ✅ 配置文件语法正确

## PR 信息

- **PR 链接**: https://github.com/mocachain/moca-callisto-juno/pull/3
- **标题**: fix: upgrade golangci-lint to v1.62.2 and update linter configuration
- **分支**: `fix/ci-golangci-lint-upgrade`
- **基础分支**: `main`
- **提交哈希**: 4c36b73

### PR 描述

#### Summary

This PR fixes the CI pipeline failures by upgrading golangci-lint and updating the linter configuration.

#### Changes

**1. Upgrade golangci-lint**
- **From**: v1.53.3
- **To**: v1.62.2
- **Reason**: v1.62.2 fully supports Go 1.23.6 and resolves the "invalid Go version format: 1.23.6" error

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

#### Testing

- ✅ `go mod tidy` completed successfully
- ✅ golangci-lint v1.62.2 verified with Go 1.23.6 support
- ✅ All deprecated linters removed from configuration

#### Related Issues

Fixes the CI failures seen in previous PRs where:
1. gocritic reported: "invalid Go version format: 1.23.6"
2. Multiple warnings about deprecated linters (scopelint, structcheck, deadcode, golint, maligned)

#### Verification

After this PR is merged, the CI pipeline should:
- ✅ Pass the Lint workflow without version format errors
- ✅ Run without deprecated linter warnings
- ✅ Successfully lint the codebase with the updated configuration

## 总结

此次修复通过升级 golangci-lint 到最新稳定版本并更新 linter 配置,解决了 CI 流水线中的两个主要问题:

1. **版本兼容性问题**: 升级到 v1.62.2 后完全支持 Go 1.23.6
2. **废弃 linters 问题**: 移除所有已废弃的 linters,使用推荐的替代方案

PR 已创建并推送到远程仓库,CI 流水线将自动运行验证修复效果。

## Related
- [[CI Fixes Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
