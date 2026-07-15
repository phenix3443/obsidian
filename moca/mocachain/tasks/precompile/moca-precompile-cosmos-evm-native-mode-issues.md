---
title: "Moca 预编译合约切换到 Cosmos EVM 原生模式子任务拆分"
aliases:
  - precompile-cosmos-evm-native-mode-issues
  - precompile-native-mode-issues
tags:
  - mocachain
  - task
  - precompile
  - cosmos-evm
  - moca
  - zh
type: "task-note"
status: "active"
area: "tasks"
topic: "precompile"
language: "zh-CN"
source_path: "tasks/precompile/moca-precompile-cosmos-evm-native-mode-issues.md"
---

> [!summary]
> 将“把当前预编译合约实现方式改成 `cosmos/evm` 原生模式”的总任务，拆分为一组可独立推进、可验证、尽量 AFK 的子任务。本页已按实际落地情况回写：**原生模式迁移由 PR #332 完成（且顺带修了一个正在生效的原生币通胀漏洞），已合入 `main`；测试与文档在 `precompile-integration-v2`（=main+我们的增量）上补齐，汇总为 PR #349（→ main，就绪待合），含 bank/staking/payment 三个已验证的通胀回归守卫、bank/storage characterization、架构文档、balance-handler 完整性审计；caller 语义变更（去 EOA-only / direct-caller / 链升级）有意推迟，尚未做。**

> [!note]
> **进度快照（2026-07-14）**：#332 已入 main；#349（我们的测试/文档增量）OPEN 指向 main、无冲突、待人工合并。后续开发（其余动币守卫、7702 e2e、gated direct-caller）暂缓。

> [!info]
> 长期有效的项目级知识已沉淀到 [[core/Precompile Architecture|Precompile Architecture]]。当前页保留任务拆分、执行边界、阶段依赖，以及落地现状。

## Navigation
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[Moca 预编译合约切换到 Cosmos EVM 原生模式计划]]
- [[core/Precompile Architecture|Precompile Architecture]]

---

# Moca 预编译合约切换到 Cosmos EVM 原生模式子任务拆分

## 落地现状（2026-07，按实际回写）

原生模式迁移**没有沿用本页最初设想的多子任务路线**，而是收敛到了同事 puneet2019 的 **PR #332**：

- **#332** 把 **11 个 precompile 全部内嵌 `cosmos/evm` 的 `cmn.Precompile` 并走 `RunNativeAction`**，全部接 `BalanceHandlerFactory`，计量真实 store gas。
- 关键：#332 **不只是迁移，还修了一个正在生效的原生币通胀漏洞**——旧的 `GetCacheContext→keeper写→commit` 模式只改 bank store、不同步 EVM StateDB stateObject 余额；配合 EIP-7702，攻击者可让 EOA 变成带旧余额的 dirty stateObject，`StateDB.Commit` 对账时把扣掉的钱铸回，**每块可重复，+90 MOCA/次**。本页最初的拆分**没有识别出这个漏洞**（只提到 value-reject 和 balance-sync 风险）。
- 我们这边原本平行做了一版迁移（含一个 `base` 封装包），但它**冗余且缺安全核心**（只给 bank 接了 BalanceHandler），已放弃，改为**以 #332 为基座**。

集成分支：**`precompile-integration-v2` = #332 + 我们续的测试/文档**：

| PR | 内容 |
|---|---|
| **#332**（基座） | 11 个 precompile 迁到 `RunNativeAction`，全接 BalanceHandler，修通胀，计量 gas，**保留 EOA-only** |
| **#346** | bank 回归测试：`TestBankSend_NoSupplyInflation`（通胀不变量）+ dispatch + 原生 revert |
| **#347** | storage createGroup 回归：dispatch / EOA-only / 失败干净回滚 |
| **#348** | `x/evm/precompiles/README.md` 架构文档 |

## 子任务状态一览

| 子任务 | 状态 | 落地 / 说明 |
|---|---|---|
| 0 迁移前测试基线 | 🟡 部分 | bank（含通胀）+ storage createGroup 回归已加；storageprovider 用 #332 自带 dispatch 测试；未铺满全部 11 个 |
| 1 原生运行时基座 | ✅ | #332。**偏差**：直接内嵌 `cmn.Precompile`，而非本页说的“新增 moca `base` 包”——目标（统一运行时、去手写模板）达成，形式不同 |
| 2 bank 迁移 | ✅ | #332 |
| 3 storage 系列（storage/payment/storageprovider/virtualgroup） | ✅ | #332 |
| 4 治理/系统（authz/gov/staking/distribution/slashing/permission） | ✅ | #332 |
| 5 内部 keeper 调用层 | ✅ | #332 未动 `x/storage/keeper/evm.go`，验证兼容（createGroup 内部 CallEVM 走通） |
| 6 清 EOA-only / direct-caller | ❌ 未做（有意推迟，HITL） | #332 **特意保留 EOA-only**，合约仍不能调 precompile。见下“为什么做 subtask 6” |
| 7 全量测试 + 文档 | 🟡 部分 | 文档 #348 已加；测试缺 contract-caller（属 subtask 6）与其余动币模块的通胀守卫 |
| 8 caller 语义链升级 | ❌ 未做（HITL） | 依赖 subtask 6 |

对照原计划 8 条“完成标准”：①原生模式 ②去手写模板 ⑥保留 RejectValue ⑦测试通过 → ✅；③去 EOA-only ④合约可调 ⑧链升级 → ❌；⑤caller/msg/事件文档+测试 → 🟡。**约 4.5 / 8。**

---

## 为什么要做“清理 EOA-only 限制并引入合约调用支持”（subtask 6）

这**本质是产品决策，不是技术必然**，回写时把它讲清楚：

**EOA-only 现在拦住的**：任何**智能合约都不能调**用 bank/staking/gov/storage 等 precompile，只有 EOA 直接发交易能调。

**为什么这是问题**：precompile 存在的意义就是让 EVM 合约与 Cosmos 模块组合。EOA-only 等于把 precompile 变成“只能 CLI/钱包直连”，合约层用不了——写不了帮用户 `delegate` 的 DeFi 合约、代成员 `gov.vote` 的 DAO 合约、管理 bucket / 转账的合约。放开合约调用 = 让 precompile 真正可组合，这是有 precompile 的**初衷**。

**EOA-only 当初为什么存在**：很可能就是个**安全闸**——因为余额对账是坏的（就是 #332 修的通胀漏洞），先用 EOA-only 限制爆炸半径。**#332 修好根因后，这个安全理由大幅减弱。**

**结论**：
- 若 moca 要合约可组合性 → EOA-only 必须去，这是 subtask 6 的正当理由；
- 若只要 EOA 通过 EVM 交易访问 Cosmos 模块 → EOA-only 可留，subtask 6 可不做。
- 原计划**默认了要 direct-caller**，那是个假设，需产品确认。
- 即便要做，#332 只移除了**通胀**这一个阻碍；放开后每个 precompile 的**授权语义**（谁能代谁做敏感操作）仍需逐个审。

---

## 6. 清理 EOA-only 限制并引入合约调用支持（未做，HITL）

- **Type**: HITL — 需产品确认是否要合约可组合性
- **Blocked by**: 上游 #332 合入 main（作为基座）
- **前置澄清**：#332 已修通胀根因、并**保留** EOA-only；本子任务是在其之上把 EOA-only 改掉

**What to build（若确认要做）**

- 删除交易型 precompile 的 `evm.Origin != contract.Caller()`（“only allow EOA can call this method”）守卫
- 业务身份取直接调用者 `contract.Caller()`；逐个 precompile 审 msg sender / operator / voter / delegator 授权语义
- **务必与 subtask 8 绑定**：改成**有条件**守卫（升级高度前保留 EOA-only，升级后放开），不能像早先关掉的 #344 那样**无条件**删——那会在升级前就改变共识执行、且被同事标为 “opens for hack”

**Acceptance criteria**

- [ ] 交易型 precompile 不再无条件用 EOA-only 拒绝合约调用；行为由升级高度 gate
- [ ] caller 语义在代码与文档统一定义
- [ ] 新增测试覆盖“EOA 直调”和“contract 转调”
- [ ] 逐 precompile 审授权语义，记录谁能代谁做敏感操作
- [ ] 覆盖 `x/storage/keeper/evm.go` 内部 EVM 调用，证明系统调用边界不变

## 7. 补齐全量测试与迁移文档（部分完成）

- **状态**: 文档 #348 完成；测试矩阵未齐
- **已做**: bank 通胀/dispatch/revert（#346）、storage createGroup dispatch/EOA/revert（#347）、README（#348）
- **待补**:
  - [ ] 其余动币 precompile（staking.delegate / distribution.withdraw / gov.deposit / payment）的 total-supply 不变量守卫
  - [ ] type-4（7702）端到端通胀复现回归（#332 建议的 CI 集成测试，较重）
  - [ ] contract-caller 测试矩阵（随 subtask 6）

## 8. 准备并执行 caller 语义链升级（未做，HITL）

- **Type**: HITL — 依赖 subtask 6
- **Blocked by**: subtask 6
- 早先关掉的 #345 有一份升级 handler 骨架 + 迁移文档草稿可复用；gating 机制（链上 param 开关 vs 升级高度）待定
- “执行升级”本身（选高度、测试网 fork/replay、发迁移公告）是运维步骤，非 AFK

---

## 已放弃 / 已关闭

- 我们平行的一版迁移（含 `base` 包，subtask 1–4 的自实现）——被 #332 取代，放弃
- **#344**（无条件删 EOA-only）——“opens for hack”，关闭；以后在 #332 之上做 gated 版
- **#345**（升级骨架）——过早，关闭；草稿留作 subtask 8 参考
- **#308**（最早的 bank 基线，pre-native 断言）——过时，关闭；由 #346 取代

## 未决事项（需团队 / 产品定）

1. **是否要合约可组合性**（决定 subtask 6/8 做不做）
2. #332 何时合入 main；`precompile-integration-v2` 何时/是否合入 main
3. 若做 subtask 6：gating 机制（param 开关 vs 升级高度）

## Related

- [[Moca 预编译合约切换到 Cosmos EVM 原生模式计划]]
- [[Moca 预编译迁移前测试基线实施计划]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
