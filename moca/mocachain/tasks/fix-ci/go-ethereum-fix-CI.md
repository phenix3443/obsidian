---
title: "修复 go-ethereum CI 流水线"
aliases:
  - go-ethereum-fix-CI
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
source_path: "tasks/fix-ci/go-ethereum-fix-CI.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 CI Fixes，并补齐索引与语言导航。

## Navigation
- [[Tasks Index]]
- [[CI Fixes Index]]
- [[Topic Index]]
- [[Language Index]]

---

# 修复 go-ethereum CI 流水线

## 问题分析

根据 CI 配置分析,存在以下问题:

### 1. 使用了废弃的 linters

- `deadcode` (v1.49.0 废弃,替代: unused)
- `varcheck` (v1.49.0 废弃,替代: unused)

### 2. GitHub Action 版本较旧

- 使用 golangci-lint-action@v3.3.1 (较旧)
- 需要升级到 v6 以获得更好的兼容性

### 3. Go 版本说明

- 当前使用 Go 1.19
- 这是有意保持与上游 go-ethereum 一致
- **不建议升级 Go 版本**以维持上游兼容性

## 修复方案

### 1. 移除废弃的 linters

在 `.golangci.yml` 中:

- 移除 `deadcode` linter
- 移除 `varcheck` linter
- 保留 `unused` linter (已在配置中,是两者的替代)

### 2. 升级 GitHub Action

在 `.github/workflows/lint.yml` 中:

- 升级 `golangci/golangci-lint-action` 从 v3.3.1 到 v6
- 移除 `github-token` 参数 (v6 中不需要)
- 保持 `version: latest` 以使用最新的 golangci-lint

### 3. 更新 issue 排除规则

- 移除 `crypto/bn256/cloudflare/optate.go` 文件中对 `deadcode` 的排除
- 保留对 `staticcheck` 的排除

## 实施步骤

1. ✅ 切换到 develop 分支并拉取最新代码
2. ✅ 创建修复分支 `fix/ci-golangci-lint-upgrade`
3. ✅ 更新 .golangci.yml 移除废弃 linters
4. ✅ 更新 .github/workflows/lint.yml 升级 action 版本
5. ✅ 提交修改并推送到远程
6. ✅ 使用 gh 命令创建 PR

## 文件修改清单

### 1. .golangci.yml

**移除的 linters:**
- `deadcode`
- `varcheck`

**保留的 linters:**
- `unused` (已有,是 deadcode 和 varcheck 的替代)

**issue 排除规则更新:**
```diff
   exclude-rules:
     - path: crypto/bn256/cloudflare/optate.go
       linters:
-        - deadcode
         - staticcheck
```

### 2. .github/workflows/lint.yml

```diff
-      - uses: golangci/golangci-lint-action@v3.3.1
+      - uses: golangci/golangci-lint-action@v6
         with:
-          # Required: the version of golangci-lint is required and must be specified without patch version: we always use the latest patch version.
           version: latest
           args: --timeout 10m
-          github-token: ${{ secrets.github_token }}
-        # Check only if there are differences in the source code
         if: env.GIT_DIFF
```

**主要变更:**
- 升级 action 版本: v3.3.1 → v6
- 移除 `github-token` 参数 (v6 中不再需要)
- 简化注释

## 验证结果

- ✅ 配置文件语法正确
- ✅ 所有废弃的 linters 已移除
- ✅ GitHub Actions workflow 已更新

## PR 信息

- **PR 链接**: https://github.com/mocachain/go-ethereum/pull/3
- **标题**: fix: upgrade golangci-lint-action and remove deprecated linters
- **分支**: `fix/ci-golangci-lint-upgrade`
- **基础分支**: `develop`
- **提交哈希**: 1343cd629

### PR 描述

#### Summary

This PR fixes the CI pipeline by upgrading golangci-lint-action and removing deprecated linters.

#### Changes

**1. Upgrade golangci-lint-action**
- **From**: v3.3.1
- **To**: v6
- **Reason**: Better compatibility with latest golangci-lint versions
- **Changes**:
  - Removed `github-token` parameter (not needed in v6)
  - Keeping `version: latest` for flexibility

**2. Remove Deprecated Linters**

**Removed from .golangci.yml:**
- `deadcode` (deprecated since v1.49.0) → replaced by `unused`
- `varcheck` (deprecated since v1.49.0) → replaced by `unused`

**Note**: The `unused` linter is already enabled in the configuration, which serves as the replacement for both deprecated linters.

**3. Update Issue Exclusion Rules**
- Removed `deadcode` from crypto/bn256/cloudflare/optate.go exclusions
- Kept `staticcheck` exclusion for the same file

#### Testing

- ✅ Configuration syntax verified
- ✅ Deprecated linters removed
- ✅ Workflow updated to use latest action version

#### Related Issues

Fixes CI warnings about deprecated linters:
- deadcode: "The owner seems to have abandoned the linter. Replaced by unused."
- varcheck: "The owner seems to have abandoned the linter. Replaced by unused."

#### Verification

After this PR is merged, the CI pipeline should:
- ✅ Run without deprecated linter warnings
- ✅ Use the latest golangci-lint-action with better performance
- ✅ Successfully lint the codebase with Go 1.19

#### Notes

- This PR maintains compatibility with Go 1.19 as used in the upstream go-ethereum
- No Go version upgrade is included to maintain upstream compatibility

## 特殊性说明

### 为什么不升级 Go 版本?

go-ethereum 是一个 fork 仓库,基于上游的 ethereum/go-ethereum:

1. **上游兼容性**: 上游 go-ethereum 使用 Go 1.19
2. **同步便利性**: 保持相同的 Go 版本使得合并上游更新更容易
3. **测试一致性**: 确保与上游的行为一致

### 与其他 mocachain 仓库的区别

| 特性 | go-ethereum | 其他 mocachain 仓库 |
|------|-------------|-------------------|
| Go 版本 | 1.19 | 1.23.6 |
| 修复方式 | 只更新 workflow + 移除废弃 linters | 升级 golangci-lint + 更新配置 |
| golangci-lint 版本 | latest (通过 action) | v1.62.2 (明确指定) |
| 基础分支 | develop | main |

### 修复范围

go-ethereum 的修复相对简单:

1. **不涉及 go.mod 修改**: 因为使用 workflow 中的 `version: latest`
2. **只移除 2 个废弃 linters**: deadcode 和 varcheck
3. **保持 Go 版本不变**: 维持与上游一致

## 总结

此次修复通过两个主要改动解决了 CI 流水线问题:

1. **升级 GitHub Action**: 从 v3.3.1 升级到 v6,提供更好的兼容性
2. **移除废弃 linters**: 移除 deadcode 和 varcheck,使用已有的 unused 替代

这些改动确保了:
- CI 流水线可以正常运行
- 不再有废弃 linters 的警告信息
- 保持与上游 go-ethereum 的兼容性 (Go 1.19)
- 代码质量检查使用现代化的 linters

PR 已创建并推送到远程仓库,CI 流水线将自动运行验证修复效果。

## 注意事项

由于修改了 GitHub Actions workflow 文件,推送时需要使用 SSH 方式或具有 `workflow` scope 的 Personal Access Token。本次修复使用了 SSH 方式成功推送。

## Related
- [[CI Fixes Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
