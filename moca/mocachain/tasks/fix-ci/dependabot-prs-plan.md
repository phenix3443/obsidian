---
title: "Mocachain Dependabot PRs 处理计划"
aliases:
  - dependabot-prs-plan
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
source_path: "tasks/fix-ci/dependabot-prs-plan.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 CI Fixes，并补齐索引与语言导航。

## Navigation
- [[Tasks Index]]
- [[CI Fixes Index]]
- [[Topic Index]]
- [[Language Index]]

---

# Mocachain Dependabot PRs 处理计划

## 概览

根据扫描结果,以下仓库有待处理的 dependabot PRs:

| 仓库 | PR 数量 | 类型 | 优先级 |
|------|---------|------|--------|
| moca-ibc-go | 27 | Go 模块 + GitHub Actions | 高 |
| moca-callisto | 10 | GitHub Actions | 高 |
| moca-cometbft-db | 5 | Go 模块 + GitHub Actions | 中 |
| moca-iavl | 5 | Go 模块 + GitHub Actions | 中 |
| moca | 4 | Go 模块 | 中 |

**总计**: 51 个 dependabot PRs

## 处理策略

### 策略 A: 批量合并 (GitHub Actions 更新)

**适用场景**: GitHub Actions 版本升级,通常风险较低

**处理方式**:
1. 检查 PR 的 CI 状态
2. 如果 CI 通过,批量合并
3. 使用 `gh pr merge --auto --squash` 自动合并

**适用仓库**:
- moca-callisto (10 个 actions PRs)
- moca-cometbft-db (部分 actions PRs)
- moca-iavl (部分 actions PRs)
- moca-ibc-go (部分 actions PRs)

### 策略 B: 逐个审查 (Go 模块更新)

**适用场景**: Go 依赖包升级,可能影响功能

**处理方式**:
1. 检查版本变更范围 (major/minor/patch)
2. 查看 CHANGELOG 了解破坏性变更
3. 确认 CI 测试通过
4. 逐个合并或批量合并 patch 版本

**适用仓库**:
- moca (4 个 Go 模块 PRs)
- moca-cometbft-db (Go 模块 PRs)
- moca-iavl (Go 模块 PRs)
- moca-ibc-go (大量 Go 模块 PRs)

### 策略 C: 谨慎处理 (Major 版本升级)

**适用场景**: Major 版本升级,可能有破坏性变更

**处理方式**:
1. 详细阅读 CHANGELOG
2. 检查迁移指南
3. 本地测试验证
4. 确认所有测试通过后再合并

**示例**:
- cosmossdk.io/x/evidence: 0.1.1 → 0.2.0 (minor)
- cosmossdk.io/core: 0.11.1 → 1.0.0 (major)

## 详细处理计划

### 第一阶段: moca-callisto (10 个 GitHub Actions PRs)

**目标**: 批量处理所有 GitHub Actions 升级

**PRs 列表**:
1. PR #1: actions/checkout 3 → 6
2. PR #2: docker/build-push-action 4 → 7
3. PR #3: docker/login-action 2 → 4
4. PR #4: docker/setup-qemu-action 2 → 4
5. PR #5: golangci/golangci-lint-action 3.4.0 → 9.2.0 (注意: 与我们的 PR #13 冲突)
6. PR #6: codecov/codecov-action 3 → 5
7. PR #7: actions/cache 3 → 5
8. PR #8: actions/setup-go 3 → 6
9. PR #9: docker/setup-buildx-action 2 → 4
10. PR #10: amannn/action-semantic-pull-request 5.1.0 → 6.1.1

**处理步骤**:
1. 检查每个 PR 的 CI 状态
2. PR #5 需要特殊处理 (与我们的 PR #13 有重叠)
3. 其他 PRs 如果 CI 通过,可以批量合并
4. 建议顺序: 先合并 PR #13 (我们的修复),然后关闭 PR #5,最后合并其他 PRs

**命令示例**:
```bash
cd /home/lsl/github/mocachain/moca-callisto
# 检查 CI 状态
gh pr checks 1
# 如果通过,合并
gh pr merge 1 --auto --squash
```

### 第二阶段: moca-cometbft-db (5 个 PRs)

**PRs 分类**:

**GitHub Actions (3 个)**:
- PR #16: actions/checkout 4 → 6
- PR #18: golangci/golangci-lint-action 3.7.0 → 9.2.0
- PR #19: docker/setup-buildx-action 3.0.0 → 3.12.0
- PR #22: docker/login-action 3.0.0 → 3.7.0

**Go 模块 (1 个)**:
- PR #24: github.com/linxGnu/grocksdb 1.8.12 → 1.10.7 (minor 升级)

**处理步骤**:
1. 先合并 GitHub Actions PRs (风险低)
2. 检查 grocksdb 的 CHANGELOG
3. 确认测试通过后合并 Go 模块 PR

### 第三阶段: moca-iavl (5 个 PRs)

**PRs 分类**:

**GitHub Actions (2 个)**:
- PR #14: golangci/golangci-lint-action 3 → 9
- PR #17: actions/checkout 3 → 6

**Go 模块 (3 个)**:
- PR #18: github.com/emicklei/dot 1.4.2 → 1.10.0 (minor)
- PR #20: google.golang.org/protobuf 1.30.0 → 1.36.11 (patch)
- PR #22: golang.org/x/crypto 0.12.0 → 0.47.0 (patch,安全更新)

**处理步骤**:
1. 优先处理 PR #22 (安全更新)
2. 合并 GitHub Actions PRs
3. 合并其他 Go 模块 PRs

### 第四阶段: moca (4 个 Go 模块 PRs)

**PRs 列表**:
- PR #93: google.golang.org/protobuf 1.36.10 → 1.36.11 (patch,安全)
- PR #95: github.com/rakyll/statik 0.1.7 → 0.1.8 (patch)
- PR #98: github.com/samber/lo 1.39.0 → 1.53.0 (minor)
- PR #99: cosmossdk.io/x/evidence 0.1.1 → 0.2.0 (minor)

**处理步骤**:
1. 优先处理 PR #93 (protobuf 安全更新)
2. 按 PR 编号顺序处理其他
3. 检查每个 PR 的测试状态

### 第五阶段: moca-ibc-go (27 个 PRs)

**数量最多,需要分批处理**

**建议分类**:

1. **安全更新 (优先)**:
   - golang.org/x/crypto 相关
   - google.golang.org/protobuf 相关
   - golang.org/x/mod 相关

2. **GitHub Actions (批量)**:
   - actions/checkout
   - actions/setup-python
   - actions/download-artifact
   - golangci/golangci-lint-action
   - 其他 actions

3. **Cosmos SDK 相关 (谨慎)**:
   - github.com/cosmos/cosmos-sdk 升级
   - cosmossdk.io/* 模块升级
   - 可能有破坏性变更,需要详细测试

4. **其他依赖 (常规)**:
   - github.com/stretchr/testify
   - github.com/docker/docker
   - 其他库

**处理步骤**:
1. 先处理所有 GitHub Actions PRs
2. 处理安全相关的 Go 模块
3. 最后处理 Cosmos SDK 相关 (需要仔细审查)

## 执行计划

### 阶段 1: 准备工作 (5 分钟)
- [ ] 创建工作分支跟踪表
- [ ] 检查所有 PRs 的 CI 状态
- [ ] 识别有冲突的 PRs

### 阶段 2: 快速胜利 - GitHub Actions (30 分钟)
- [ ] moca-callisto: 合并 9 个 actions PRs (跳过 PR #5)
- [ ] moca-cometbft-db: 合并 4 个 actions PRs
- [ ] moca-iavl: 合并 2 个 actions PRs
- [ ] moca-ibc-go: 合并所有 actions PRs

**预计合并**: ~25 个 PRs

### 阶段 3: 安全更新 (20 分钟)
- [ ] moca-iavl PR #22: golang.org/x/crypto
- [ ] moca PR #93: google.golang.org/protobuf
- [ ] moca-ibc-go: 所有安全相关 PRs

**预计合并**: ~5 个 PRs

### 阶段 4: 常规 Go 模块更新 (40 分钟)
- [ ] moca: 剩余 3 个 PRs
- [ ] moca-cometbft-db PR #24: grocksdb
- [ ] moca-iavl: 剩余 2 个 PRs
- [ ] moca-ibc-go: 常规依赖 PRs

**预计合并**: ~15 个 PRs

### 阶段 5: Cosmos SDK 相关 (需要审查)
- [ ] moca-ibc-go: Cosmos SDK 相关 PRs
- [ ] 详细检查 CHANGELOG
- [ ] 确认测试通过
- [ ] 逐个合并

**预计合并**: ~6 个 PRs

## 批量操作脚本

### 检查 PR CI 状态

```bash
#!/bin/bash
REPO_PATH="/home/lsl/github/mocachain/moca-callisto"
cd "$REPO_PATH"

for pr in 1 2 3 4 6 7 8 9 10; do
  echo "=== PR #$pr ==="
  gh pr checks "$pr" --json name,conclusion | jq -r '.[] | "\(.name): \(.conclusion)"'
  echo ""
done
```

### 批量合并通过的 PRs

```bash
#!/bin/bash
REPO_PATH="/home/lsl/github/mocachain/moca-callisto"
cd "$REPO_PATH"

# PRs to merge (excluding #5 which conflicts with our PR #13)
PRS=(1 2 3 4 6 7 8 9 10)

for pr in "${PRS[@]}"; do
  echo "Checking PR #$pr..."
  # Check if all checks passed
  FAILED=$(gh pr checks "$pr" --json conclusion | jq '[.[] | select(.conclusion != "success")] | length')

  if [ "$FAILED" -eq 0 ]; then
    echo "✅ PR #$pr passed all checks, merging..."
    gh pr merge "$pr" --squash --auto
  else
    echo "❌ PR #$pr has failing checks, skipping"
  fi
  echo ""
done
```

## 冲突处理

### moca-callisto PR #5 vs PR #13

**冲突**: 两个 PR 都更新 golangci-lint-action

- **PR #5 (dependabot)**: 3.4.0 → 9.2.0
- **PR #13 (我们的)**: 3.4.0 → v6 + 配置修复

**解决方案**:
1. 先合并 PR #13 (包含配置修复)
2. 关闭 PR #5 (dependabot)
3. 或者: 将 PR #13 中的版本改为 9.2.0

**建议**: 先合并 PR #13,然后手动更新到 9.2.0 (如果需要)

## 风险评估

### 低风险 (可以自动合并)
- ✅ GitHub Actions patch 版本升级
- ✅ actions/checkout, actions/setup-go 等标准 actions
- ✅ Docker actions 升级

### 中风险 (需要检查 CI)
- ⚠️ Go 模块 minor 版本升级
- ⚠️ protobuf, crypto 等核心库
- ⚠️ 工具库升级

### 高风险 (需要详细审查)
- 🔴 Cosmos SDK major 版本升级
- 🔴 cosmossdk.io/core 0.x → 1.0
- 🔴 可能影响核心功能的依赖

## 详细 PR 清单

### moca-callisto (10 个 PRs)

所有都是 GitHub Actions 升级,创建时间: 2026-03-18

| PR | 标题 | 类型 | 建议 |
|----|------|------|------|
| #1 | actions/checkout 3 → 6 | Actions | ✅ 自动合并 |
| #2 | docker/build-push-action 4 → 7 | Actions | ✅ 自动合并 |
| #3 | docker/login-action 2 → 4 | Actions | ✅ 自动合并 |
| #4 | docker/setup-qemu-action 2 → 4 | Actions | ✅ 自动合并 |
| #5 | golangci/golangci-lint-action 3.4.0 → 9.2.0 | Actions | ⚠️ 与 PR #13 冲突,先合并 #13 |
| #6 | codecov/codecov-action 3 → 5 | Actions | ✅ 自动合并 |
| #7 | actions/cache 3 → 5 | Actions | ✅ 自动合并 |
| #8 | actions/setup-go 3 → 6 | Actions | ✅ 自动合并 |
| #9 | docker/setup-buildx-action 2 → 4 | Actions | ✅ 自动合并 |
| #10 | amannn/action-semantic-pull-request 5.1.0 → 6.1.1 | Actions | ✅ 自动合并 |

**执行计划**:
1. 先合并我们的 PR #13 (golangci-lint 配置修复)
2. 关闭或更新 dependabot PR #5
3. 批量合并其他 9 个 PRs

### moca (4 个 Go 模块 PRs)

| PR | 标题 | 版本变更 | 类型 | 建议 |
|----|------|---------|------|------|
| #93 | google.golang.org/protobuf | 1.36.10 → 1.36.11 | Patch | ✅ 优先合并 (安全) |
| #95 | github.com/rakyll/statik | 0.1.7 → 0.1.8 | Patch | ✅ 合并 |
| #98 | github.com/samber/lo | 1.39.0 → 1.53.0 | Minor | ⚠️ 检查 CI 后合并 |
| #99 | cosmossdk.io/x/evidence | 0.1.1 → 0.2.0 | Minor | ⚠️ 检查 CI 后合并 |

**执行计划**:
1. 优先合并 #93 (protobuf 安全更新)
2. 合并 #95 (patch 升级)
3. 检查 #98 和 #99 的 CI 状态后合并

### moca-cometbft-db (5 个 PRs)

| PR | 标题 | 类型 | 建议 |
|----|------|------|------|
| #16 | actions/checkout 4 → 6 | Actions | ✅ 自动合并 |
| #18 | golangci/golangci-lint-action 3.7.0 → 9.2.0 | Actions | ✅ 自动合并 |
| #19 | docker/setup-buildx-action 3.0.0 → 3.12.0 | Actions | ✅ 自动合并 |
| #22 | docker/login-action 3.0.0 → 3.7.0 | Actions | ✅ 自动合并 |
| #24 | github.com/linxGnu/grocksdb 1.8.12 → 1.10.7 | Go Module | ⚠️ 检查 CI 后合并 |

**执行计划**:
1. 批量合并 4 个 actions PRs
2. 检查 PR #24 的测试状态后合并

### moca-iavl (5 个 PRs)

| PR | 标题 | 类型 | 建议 |
|----|------|------|------|
| #14 | golangci/golangci-lint-action 3 → 9 | Actions | ✅ 自动合并 |
| #17 | actions/checkout 3 → 6 | Actions | ✅ 自动合并 |
| #18 | github.com/emicklei/dot 1.4.2 → 1.10.0 | Go Module | ⚠️ 检查后合并 |
| #20 | google.golang.org/protobuf 1.30.0 → 1.36.11 | Go Module | ✅ 优先合并 (安全) |
| #22 | golang.org/x/crypto 0.12.0 → 0.47.0 | Go Module | ✅ 优先合并 (安全) |

**执行计划**:
1. 优先合并 #20 和 #22 (安全更新)
2. 合并 actions PRs
3. 检查 #18 后合并

### moca-ibc-go (27 个 PRs)

**数量最多,需要分批处理**

**建议分组**:

**Group 1: GitHub Actions (优先,~10 个)**
- actions/checkout 4 → 6
- actions/setup-python 5 → 6
- actions/download-artifact 4 → 7
- golangci/golangci-lint-action 升级
- 其他 actions

**Group 2: 安全更新 (高优先级,~3 个)**
- google.golang.org/protobuf 升级
- golang.org/x/mod 升级
- google.golang.org/grpc 升级

**Group 3: 常规依赖 (中优先级,~8 个)**
- github.com/stretchr/testify
- github.com/docker/docker
- go.uber.org/zap
- 其他工具库

**Group 4: Cosmos SDK (需要审查,~6 个)**
- github.com/cosmos/cosmos-sdk
- cosmossdk.io/core (major 升级!)
- cosmossdk.io/x/* 模块
- 需要详细测试

**执行计划**:
1. 批量合并 Group 1 (actions)
2. 优先合并 Group 2 (安全)
3. 逐个检查合并 Group 3
4. 详细审查 Group 4,可能需要单独的 PR 或测试

## 自动化工具

### 批量检查脚本

```bash
#!/bin/bash
# check-dependabot-prs.sh

REPOS=(
  "moca-callisto"
  "moca-cometbft-db"
  "moca-iavl"
  "moca"
  "moca-ibc-go"
)

for repo in "${REPOS[@]}"; do
  echo "========================================="
  echo "Repository: $repo"
  echo "========================================="
  cd "/home/lsl/github/mocachain/$repo"

  # Get all dependabot PRs
  gh pr list --author "app/dependabot" --state open --json number,title,url,headRefName \
    --jq '.[] | "PR #\(.number): \(.title)\n  URL: \(.url)\n  Branch: \(.headRefName)\n"'

  echo ""
done
```

### 批量合并脚本 (GitHub Actions only)

```bash
#!/bin/bash
# merge-actions-prs.sh

merge_actions_prs() {
  local repo=$1
  shift
  local prs=("$@")

  cd "/home/lsl/github/mocachain/$repo"
  echo "Processing $repo..."

  for pr in "${prs[@]}"; do
    echo "  Checking PR #$pr..."

    # Check if it's an actions PR
    TITLE=$(gh pr view "$pr" --json title --jq '.title')
    if [[ "$TITLE" == *"build(deps)"* ]] || [[ "$TITLE" == *"actions/"* ]] || [[ "$TITLE" == *"docker/"* ]]; then
      # Check CI status
      FAILED=$(gh pr checks "$pr" --json conclusion --jq '[.[] | select(.conclusion != "success" and .conclusion != "skipped")] | length')

      if [ "$FAILED" -eq 0 ]; then
        echo "    ✅ Merging PR #$pr"
        gh pr merge "$pr" --squash --auto
      else
        echo "    ❌ PR #$pr has failing checks"
      fi
    else
      echo "    ⏭️  Skipping non-actions PR #$pr"
    fi
  done
}

# Usage examples:
# merge_actions_prs "moca-callisto" 1 2 3 4 6 7 8 9 10
# merge_actions_prs "moca-cometbft-db" 16 18 19 22
# merge_actions_prs "moca-iavl" 14 17
```

## 时间估算

| 阶段 | 仓库 | PRs 数量 | 预计时间 |
|------|------|---------|---------|
| 1 | 准备工作 | - | 5 分钟 |
| 2 | GitHub Actions | ~25 | 30 分钟 |
| 3 | 安全更新 | ~5 | 20 分钟 |
| 4 | 常规更新 | ~15 | 40 分钟 |
| 5 | Cosmos SDK | ~6 | 60 分钟 |
| **总计** | | **51** | **~2.5 小时** |

## 注意事项

### 1. PR #13 优先级

我们创建的 PR #13 (moca-callisto) 需要先合并,因为:
- 包含重要的配置修复
- 与 dependabot PR #5 有冲突
- 修复了 CI 流水线问题

### 2. 冲突解决

如果遇到冲突:
1. 优先保留我们的修复
2. 手动更新到 dependabot 建议的版本
3. 关闭 dependabot PR 或让它自动更新

### 3. 测试验证

对于 Go 模块更新:
1. 必须确认 CI 测试通过
2. 对于 major 版本升级,需要本地测试
3. 对于 Cosmos SDK 相关,需要集成测试

### 4. 回滚计划

如果合并后出现问题:
1. 使用 `git revert` 回滚提交
2. 创建新的 PR 修复问题
3. 更新 dependabot 配置忽略问题版本

## 执行命令参考

### 检查单个 PR

```bash
cd /home/lsl/github/mocachain/moca-callisto
gh pr view 1
gh pr checks 1
gh pr diff 1
```

### 合并单个 PR

```bash
# 自动合并 (当 CI 通过时)
gh pr merge 1 --squash --auto

# 立即合并 (如果 CI 已通过)
gh pr merge 1 --squash

# 合并并删除分支
gh pr merge 1 --squash --delete-branch
```

### 关闭 PR

```bash
gh pr close 5 --comment "Closing in favor of PR #13 which includes additional configuration fixes"
```

### 批量查看状态

```bash
cd /home/lsl/github/mocachain/moca-callisto
gh pr list --author "app/dependabot" --state open --json number,title,url,statusCheckRollup \
  --jq '.[] | "PR #\(.number): \(.statusCheckRollup // "no checks")"'
```

## 成功标准

完成后应达到:
- ✅ 所有低风险的 GitHub Actions PRs 已合并
- ✅ 所有安全更新已合并
- ✅ 常规依赖更新已合并或有明确的处理决策
- ✅ 高风险的 Cosmos SDK 更新已审查并有处理计划
- ✅ 没有遗留的冲突 PRs
- ✅ 所有仓库的 CI 流水线正常运行

## 后续维护

### 短期 (1 周内)
- 监控合并后的 CI 状态
- 处理任何回归问题
- 完成剩余的高风险 PRs

### 中期 (1 个月内)
- 配置 dependabot 自动合并规则
- 设置 PR 批量审查流程
- 建立依赖更新的 SOP

### 长期 (持续)
- 定期审查 dependabot 配置
- 优化自动化流程
- 保持依赖的及时更新

## 文档输出

处理完成后,创建总结文档:
- `/home/lsl/github/phenix3443/zkme/mocachain/dependabot-prs-summary.md`

包含:
- 处理的 PRs 统计
- 合并的 PRs 列表
- 跳过或关闭的 PRs 及原因
- 遇到的问题和解决方案
- 后续建议

## Related
- [[CI Fixes Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
