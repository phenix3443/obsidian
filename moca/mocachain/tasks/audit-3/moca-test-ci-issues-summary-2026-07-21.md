---
title: Moca Test CI Issues Summary 2026-07-21
aliases:
  - moca test ci issues 2026-07-21
tags:
  - moca
  - ci
  - testing
  - audit
type: report
status: active
area: mocachain
---

# Moca Test & CI 问题摘要（2026-07-21）

> [!summary]
> `moca` 与 `moca-storage-provider` 的单元测试均为绿色，`moca-e2e` 的完整跨仓栈也已在 2026-07-21 恢复通过。当前最需要处理的是 storage-provider 三条真实链 E2E 的陈旧失败：它们仍显示 chain-id 不一致，且尚未在 moca 侧修复后重新触发，因而修复是否生效尚未确认。

来源：[[moca-test-ci-report-2026-07-21]]。除非另有说明，状态均截至 2026-07-21。

## 待确认的失败

| 优先级 | 范围 | 问题 | 证据与影响 | 建议动作 |
| --- | --- | --- | --- | --- |
| P0 | `moca-storage-provider` | 三条真实链 E2E 仍为红色：`e2e-test`、`e2e-sdk`、`sp-exit-e2e`。 | 最近一次运行是 2026-07-14；signer 使用的 chain-id 为 `262144`，链侧为 `5151`。这三项分别覆盖对象上传/复制/封存/下载、bucket 迁移，以及 SP 优雅退出和数据迁移。报告指出 moca 侧 chain-id/gas 修复后尚未重跑，因此当前红色结果已陈旧但仍未被验证消除。 | 重新触发三条 suite；若仍失败，保留首个失败日志并从 signer 配置与链配置的 chain-id 一致性开始定位。 |
| P1 | `moca` proto CI gate | `proto.yml` 持续失败。 | 自 2026-03-10 后未重跑；失败来自 `buf-lint` 与过时的 `ethermint/feemarket` protobuf。该 gate 仅在 protobuf 变更的 PR 上触发，当前会阻塞相关改动的合入验证。 | 在包含 proto 改动的分支上重跑，修复 lint 与过时 proto，再确认 break-check 通过。 |
| P1 | `moca-e2e` PR #58 | SP 完整退出的 EVM 交易发生 revert，导致 PR #58 的 SP-exit/object-failover 加固工作仍为红色。 | 已恢复的 29 场景完整栈不受此前 gas 回归影响；该问题是新的退出/故障转移路径问题。报告称场景需要第 9 个 SP。 | 以 9 个 SP 的拓扑复现 `complete-SP-exit`，分析 revert 原因并补充该场景的回归覆盖。 |

## 测试保障缺口

| 优先级 | 范围 | 缺口 | 风险 | 建议动作 |
| --- | --- | --- | --- | --- |
| P1 | `moca` Go E2E | 约 135 个深层 SDK/keeper 测试没有接入任何 CI workflow。 | challenge、payment、storage、permission、virtualgroup 等主路径只能依赖本地 localnet 验证，回归可能在合并后才被发现。 | 为 localnet E2E 提供可重复的 CI job，并明确运行触发条件。 |
| P1 | SP exit 与 EVM bridge | 关键路径单元测试覆盖率过低。 | `x/virtualgroup/keeper` 仅 7.7%，其中包含可能导致链停机的 SP-exit 路径；`precompiles/*` 为 0--21%，其中 authz、gov、permission、slashing 为 0%。 | 优先为 SP-exit 状态转换、失败恢复和零覆盖 precompile 补充单元及集成测试。 |
| P2 | `moca-storage-provider` | signer 和 SP-exit 相关模块覆盖率不足。 | `modular/signer` 仅 0.7%，`modular/manager` 为 18%；前者承担密钥管理和交易广播，正与当前 chain-id E2E 失败路径相关。 | 覆盖 chain-id 选择、签名和广播失败分支，并补充退出/迁移编排测试。 |
| P2 | `moca-storage-provider` | `p2p` 模块未纳入测试门禁。 | P2P 与核心接口的覆盖率为 0--15%，但不会阻止 CI 通过。 | 评估是否应纳入 `make test` 或建立独立门禁。 |

## 发布就绪性风险

- `moca` 的 `Deploy for testint` 与 `Publish Main GHCR Image` 在 2026-07-21 为红色。它们不是功能测试，因此不改变当前单元/E2E 结论，但会影响测试环境部署和镜像发布。
- 本机约 41 个 `moca` 边缘或无测试包无法以 Go 1.25.0 编译，而项目要求 Go 1.25.8；CI 已通过，因此这是本机工具链问题，不应定性为产品缺陷。完整本地验证应使用 Go 1.25.8 或 amd64 test-box。
- 两个未跟踪的本地草稿路径 `app/sp_exit_orphan_family_halt_test.go` 与 `cmd/iavl-tree-html/` 会失败，且不在 `main` 或 CI 范围内，不计入本报告的问题清单。

## 已恢复或已通过的项目

- `moca-e2e` 29 场景完整跨仓栈已于 2026-07-21 通过，已越过 2026-06-17 至 07-20 的冻结点；此前 gas 回归已修复。
- `moca` 的 `Tests` 与 `moca-storage-provider` 的 `Unit Test` CI 均为绿色；本地执行的核心模块单元测试没有真实失败。

## 建议任务拆分

按仓库、优先级和可独立验收的产出拆分如下。不要在根因未确认时把跨仓改动捆绑到同一个任务。

| 优先级 | 仓库 | 建议任务 | 完成判定 |
| --- | --- | --- | --- |
| P0 | `moca-storage-provider` | 重跑并确认三条真实链 E2E 的 chain-id 回归。 | `e2e-test`、`e2e-sdk`、`sp-exit-e2e` 均在 moca 侧修复后重新执行；记录结果和首个失败日志。若仍失败，再按已确认根因创建修复任务。 |
| P1 | `moca` | 修复 `proto.yml` 的 `buf-lint` 与过时 `ethermint/feemarket` proto。 | 在包含 proto 改动的分支上，lint 和 break-check 均通过。 |
| P1 | `moca-e2e` | 以 9 个 SP 的拓扑复现并定位 `completeSpExit` EVM revert。 | 得到稳定复现步骤、revert 原因和对应回归场景；若根因属于 `moca` 或 `moca-storage-provider`，分别创建代码修复任务。 |
| P1 | `moca` | 将约 135 个 Go E2E SDK/keeper 测试接入 CI。 | CI workflow 可重复启动所需 localnet，并在约定的触发条件下执行该 suite。若实施需要环境编排改动，再为 `moca-devcontainer` 单独建依赖任务。 |
| P1 | `moca` | 补齐 `x/virtualgroup/keeper` 的 SP-exit 关键路径回归测试。 | 覆盖状态转换、迁移和失败恢复；测试直接保护当前 7.7% 覆盖率所暴露的链停机风险路径。 |
| P1 | `moca` | 补齐零覆盖 EVM precompile 的回归测试。 | authz、gov、permission、slashing 均有覆盖；不与 virtualgroup 测试任务合并，避免跨模块扩大 PR。 |
| P2 | `moca-storage-provider` | 提升 signer 与 SP-exit manager 的回归覆盖。 | 覆盖 chain-id 选择、签名、广播失败分支及退出/迁移编排。若 P0 确认失败仍在，相关 signer 测试应随该修复一并完成。 |
| P2 | `moca-storage-provider` | 决定并实施 P2P 测试门禁策略。 | 明确将 P2P 纳入 `make test` 或新建独立 CI workflow，并使选定门禁稳定执行。 |

### 延后拆分的发布任务

`moca` 的 `Deploy for testint` 和 `Publish Main GHCR Image` 可先作为一个低优先级 CI 排查任务处理。两项均影响发布就绪性而非功能测试；只有确认根因不同后，才拆分为独立的 deploy 和 image publish 修复任务。

### 不建任务的事项

- 本机 Go 1.25.0 与项目所需 Go 1.25.8 的不匹配是环境问题，CI 已通过，不作为产品缺陷建任务。
- 未跟踪的本地草稿路径不在 `main` 和 CI 范围内，不纳入任务清单。
