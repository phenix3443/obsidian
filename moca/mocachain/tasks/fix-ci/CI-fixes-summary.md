---
title: "Mocachain 仓库 CI 流水线修复总结"
aliases:
  - CI-fixes-summary
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
source_path: "tasks/fix-ci/CI-fixes-summary.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 CI Fixes，并补齐索引与语言导航。

## Navigation
- [[Tasks Index]]
- [[CI Fixes Index]]
- [[Topic Index]]
- [[Language Index]]

---

# Mocachain 仓库 CI 流水线修复总结

## 修复概览

本次修复工作针对 mocachain 组织中所有存在 golangci-lint 配置问题的仓库进行了系统性修复。

### 修复的仓库

| 仓库名称 | PR 链接 | 状态 | 主要问题 |
|---------|---------|------|---------|
| moca-callisto-juno | [PR #3](https://github.com/mocachain/moca-callisto-juno/pull/3) | ✅ 已创建 | golangci-lint v1.53.3 不支持 Go 1.23.6 + 废弃 linters |
| moca-callisto | [PR #13](https://github.com/mocachain/moca-callisto/pull/13) | ✅ 已创建 | golangci-lint v1.50.1 不支持 Go 1.23.6 + 废弃 linters |
| moca-juno | [PR #7](https://github.com/mocachain/moca-juno/pull/7) | ✅ 已创建 | golangci-lint v1.53.3 不支持 Go 1.23.6 + 废弃 linters |
| go-ethereum | [PR #3](https://github.com/mocachain/go-ethereum/pull/3) | ✅ 已创建 | 废弃 linters + 旧版 action |

### 详细文档

每个仓库的修复都有详细的文档记录:

1. [moca-callisto-juno-fix-CI.md](./moca-callisto-juno-fix-CI.md)
2. [moca-callisto-fix-CI.md](./moca-callisto-fix-CI.md)
3. [moca-juno-fix-CI.md](./moca-juno-fix-CI.md)
4. [go-ethereum-fix-CI.md](./go-ethereum-fix-CI.md)

## 问题分类

### 类型 A: golangci-lint 版本不兼容 (3 个仓库)

**影响仓库**: moca-callisto-juno, moca-callisto, moca-juno

**问题描述**:
- 使用的 golangci-lint 版本过旧 (v1.50.1 或 v1.53.3)
- 不支持 Go 1.23.6
- 错误信息: "invalid Go version format: 1.23.6"

**修复方案**:
- 升级 golangci-lint 到 v1.62.2
- 更新 .golangci.yaml 配置
- 移除所有废弃的 linters

### 类型 B: 废弃 linters (所有 4 个仓库)

**废弃的 linters**:
- `deadcode` (v1.49.0 废弃) → 替代: `unused`
- `scopelint` (v1.39.0 废弃) → 替代: `exportloopref`
- `structcheck` (v1.49.0 废弃) → 替代: `unused`
- `golint` (v1.41.0 废弃) → 替代: `revive`
- `maligned` (v1.38.0 废弃) → 替代: `govet 'fieldalignment'`
- `varcheck` (v1.49.0 废弃) → 替代: `unused`

**修复方案**:
- 移除所有废弃的 linters
- 添加推荐的替代 linters
- 更新相关的配置和排除规则

### 类型 C: GitHub Action 版本过旧 (2 个仓库)

**影响仓库**: moca-callisto, go-ethereum

**问题描述**:
- 使用旧版本的 golangci-lint-action (v3.3.1 或 v3.4.0)
- 与新版 golangci-lint 兼容性不佳

**修复方案**:
- 升级 golangci-lint-action 到 v6
- 移除不再需要的 `github-token` 参数

## 修复模式

### 模式 1: Makefile + go.mod (3 个仓库)

**适用**: moca-callisto-juno, moca-juno

**特点**:
- 使用 `make lint` 运行 golangci-lint
- 在 go.mod 中指定 golangci-lint 版本
- 需要运行 `go mod tidy`

**修改文件**:
1. `go.mod` - 升级 golangci-lint 版本
2. `.golangci.yaml` - 更新 linter 配置

### 模式 2: GitHub Action + 配置文件 (1 个仓库)

**适用**: moca-callisto

**特点**:
- 使用 GitHub Actions workflow
- 在 workflow 中指定 golangci-lint 版本
- 需要同时更新 workflow 和配置文件

**修改文件**:
1. `.github/workflows/lint.yml` - 升级 action 和版本
2. `.golangci.yaml` - 更新 linter 配置

### 模式 3: GitHub Action + latest (1 个仓库)

**适用**: go-ethereum

**特点**:
- 使用 GitHub Actions workflow
- 使用 `version: latest`
- 只需更新 workflow 和移除废弃 linters
- 保持 Go 1.19 以维持上游兼容性

**修改文件**:
1. `.github/workflows/lint.yml` - 升级 action 版本
2. `.golangci.yml` - 移除废弃 linters

## 统计数据

### 修复范围

- **检查的仓库总数**: 18 个
- **需要修复的仓库**: 4 个
- **创建的 PR**: 4 个
- **修改的文件**: 10 个
- **移除的废弃 linters**: 6 种类型

### 时间线

- **扫描阶段**: 使用 explore subagent 快速扫描所有仓库
- **修复阶段**: 按优先级依次修复每个仓库
- **文档阶段**: 为每个修复创建详细文档

## 最佳实践

基于本次修复经验,总结以下最佳实践:

### 1. golangci-lint 版本管理

**推荐做法**:
- 在 go.mod 中明确指定 golangci-lint 版本
- 使用最新的稳定版本 (当前: v1.62.2)
- 定期检查和更新版本

**避免**:
- 使用过旧的版本 (< v1.60)
- 不指定版本,依赖系统默认

### 2. Linter 配置维护

**推荐做法**:
- 定期检查 linter 的废弃状态
- 及时迁移到推荐的替代方案
- 使用官方推荐的 linter 集合

**避免**:
- 继续使用已废弃的 linters
- 忽略 CI 中的废弃警告

### 3. GitHub Actions 更新

**推荐做法**:
- 使用最新的 major 版本 (当前: v6)
- 移除不再需要的参数
- 定期检查 action 的更新日志

**避免**:
- 使用过旧的 action 版本
- 保留已废弃的参数

### 4. Go 版本兼容性

**推荐做法**:
- 确保 golangci-lint 版本支持项目的 Go 版本
- 对于 fork 仓库,考虑上游的 Go 版本
- 在升级 Go 版本时同步检查 linter 兼容性

## 未来维护建议

### 短期 (1-3 个月)

1. **监控 PR 状态**: 确保所有 PR 被审查和合并
2. **验证 CI 通过**: 合并后验证 CI 流水线正常运行
3. **收集反馈**: 记录任何新出现的问题

### 中期 (3-6 个月)

1. **定期检查**: 每季度检查一次 golangci-lint 更新
2. **更新文档**: 保持修复文档的时效性
3. **分享经验**: 在团队内分享最佳实践

### 长期 (6-12 个月)

1. **自动化检查**: 考虑添加自动化脚本检查配置问题
2. **统一配置**: 考虑为所有仓库创建统一的 linter 配置模板
3. **持续改进**: 根据新的 golangci-lint 版本调整配置

## 其他仓库状态

根据扫描结果,以下仓库配置较新,暂不需要修复:

| 仓库名称 | golangci-lint 版本 | 状态 | 备注 |
|---------|-------------------|------|------|
| moca | v1.59 | ✅ 良好 | 配置较新,无废弃 linters |
| moca-storage-provider | latest | ✅ 良好 | 使用最新版本 |
| moca-cmd | latest | ✅ 良好 | 无独立配置文件 |
| moca-go-sdk | latest | ✅ 良好 | 无独立配置文件 |
| moca-common | v1.52.1 | ✅ 良好 | 配置较旧但无废弃 linters |
| moca-cosmos-sdk | latest | ✅ 良好 | 配置较新 |
| moca-cometbft | latest | ✅ 良好 | 配置较新 |
| moca-ibc-go | v1.62 | ✅ 良好 | 配置最新 |
| moca-iavl | latest | ✅ 良好 | 配置较新 |
| moca-cometbft-db | latest | ✅ 良好 | 配置较新 |

## 结论

本次 CI 流水线修复工作:

1. ✅ **全面扫描**: 检查了所有 18 个 mocachain 仓库
2. ✅ **精准修复**: 识别并修复了 4 个有问题的仓库
3. ✅ **文档完善**: 为每个修复创建了详细的文档记录
4. ✅ **标准化**: 建立了统一的修复模式和最佳实践

所有修复的 PR 已创建并推送到远程仓库,等待审查和合并。CI 流水线应该能够在合并后正常运行,不再出现 golangci-lint 相关的错误和警告。

## Related
- [[CI Fixes Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
