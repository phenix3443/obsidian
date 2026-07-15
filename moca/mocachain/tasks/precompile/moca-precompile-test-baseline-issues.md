---
title: "Moca 预编译迁移前测试基线子任务拆分"
aliases:
  - precompile-test-baseline-issues
  - moca-precompile-characterization-tests-issues
tags:
  - mocachain
  - task
  - precompile
  - test
  - cosmos-evm
  - moca
  - zh
type: "task-note"
status: "active"
area: "tasks"
topic: "precompile"
language: "zh-CN"
source_path: "tasks/precompile/moca-precompile-test-baseline-issues.md"
---

> [!summary]
> 将“建立 precompile 迁移前测试基线”继续拆成可发布、可独立验证的 issue 级切片，供后续按依赖顺序执行。

## Navigation
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[Moca 预编译迁移前测试基线实施计划]]
- [[Moca 预编译合约切换到 Cosmos EVM 原生模式计划]]

---

# Moca 预编译迁移前测试基线子任务拆分

## 拆分原则

- 每个 issue 都必须是一条可验证的垂直切片，而不是“先搭框架、后补断言”的横向拆法
- 优先复用现有 `EthSetup` 和 `CallEVMWithData` harness，不在测试基线阶段引入新抽象
- 每个 issue 完成后，都应能留下明确的回归信号，供后续 precompile runtime 重构使用
- 测试基线阶段不修改生产逻辑，只固定当前行为

## 子任务列表

### 1. 建立 bank precompile 基线测试

- **Title**: 建立 bank precompile 基线测试
- **Type**: AFK
- **Blocked by**: None - can start immediately
- **Progress**: 基线 commit `2ec1079d` 曾从主干丢失，已在分支 `precompile/bank-baseline` 重建（并修掉当前 lint gate 报的两处问题），开 PR #333 合入 `precompile-integration`；待三基线合并后随矩阵关闭。
- **User stories covered**:
  - 作为迁移执行者，我需要先固定 `bank.send` 的当前行为，避免后续运行时迁移打坏余额语义
  - 作为审计者，我需要看到 `RejectValue`、`EOA-only` 和失败不改余额的明确断言

**What to build**

围绕 `bank.send` 建立迁移前基线测试，覆盖三类行为：

- nonzero native value 被 `RejectValue(contract)` 拒绝
- 当前 `evm.Origin != contract.Caller()` 时，交易型方法会拒绝“contract 转调”
- 真实经过 `EvmKeeper.CallEVMWithData` 的成功路径和失败路径，明确验证余额变化与失败回滚

**Acceptance criteria**

- [x] `bank` 目录下存在 `send` 的真实 EVM dispatch 成功测试
- [x] 明确存在一条 `EOA-only` 历史行为测试，断言错误来自 caller 不一致
- [x] 明确存在一条失败路径测试，断言 sender / receiver 余额未被污染
- [x] `go test ./x/evm/precompiles/bank -count=1` 通过

### 2. 扩展 storageprovider precompile 基线测试

- **Title**: 扩展 storageprovider precompile 基线测试
- **Type**: AFK
- **Blocked by**: None - can start immediately
- **User stories covered**:
  - 作为迁移执行者，我需要在现有 `updateSPPrice` 测试基础上补齐 caller 和失败语义
  - 作为维护者，我需要一个已知可用的 static precompile dispatch 样板继续存在

**What to build**

在现有 `storageprovider.updateSPPrice` 测试上追加迁移前基线断言，覆盖：

- `EOA-only` 历史行为
- 真实 EVM dispatch 成功路径继续成立
- 失败路径不会写入或污染 SP price 状态

**Acceptance criteria**

- [x] `storageprovider` 现有 EVM apply 成功路径继续保留（`TestUpdateSPPrice_EVMApply` 未动）
- [x] 新增一条 `EOA-only` 历史行为测试（`TestUpdateSPPrice_RejectsContractForwarding`）
- [x] 新增一条失败路径测试，断言 SP price 未发生状态污染（`TestUpdateSPPrice_FailureDoesNotMutateState`）
- [x] `go test ./x/evm/precompiles/storageprovider -count=1` 通过

> 落地于分支 `precompile/storageprovider-baseline`，PR #334。

### 3. 建立 storage precompile 基线测试

- **Title**: 建立 storage precompile 基线测试
- **Type**: AFK
- **Blocked by**:
  - 建立 bank precompile 基线测试
- **User stories covered**:
  - 作为迁移执行者，我需要先固定一个代表性的 storage 交易型路径
  - 作为后续 runtime 重构执行者，我需要确认 storage 失败时不会产生部分写入

**What to build**

为 `storage` 选择一个代表性交易型方法，默认目标为 `createBucket`，建立迁移前基线测试，覆盖：

- 真实经过 `EvmKeeper.CallEVMWithData` 的成功路径
- 当前 `EOA-only` 历史行为
- 失败路径不会创建 bucket 或留下半成状态

如果 `createBucket` fixture 成本过高，可换成另一个更容易稳定构造前置条件的 storage 写方法，但必须在文档中明确说明替换原因。

**Acceptance criteria**

- [x] `storage` 至少有一条真实 EVM dispatch 成功测试（`TestCreateGroup_EVMDispatchSuccess`）
- [x] 明确存在一条 `EOA-only` 历史行为测试（`TestCreateGroup_RejectsContractForwarding`）
- [x] 明确存在一条失败路径测试，断言链上状态未被污染（`TestCreateGroup_FailureDoesNotMutateState`，重复 group 名触发 keeper 级失败并回滚）
- [x] 选择的 storage 方法和替换理由有文档记录（改用 `createGroup` 而非 `createBucket`，理由见测试文件头与 PR #335：createBucket 成功 fixture 需 SP+虚拟组+payment+approval 签名，过重）
- [x] `go test ./x/evm/precompiles/storage -count=1` 通过

> 落地于分支 `precompile/storage-baseline`，PR #335。补充：`createGroup` 内部 mint 需要 control-hub 账户（`0x…dead`）存在，测试在 SetupTest 里注册该账户作为 fixture（不改生产码）。

### 4. 验证测试矩阵并回写父计划

- **Title**: 验证测试矩阵并回写父计划
- **Type**: AFK
- **Blocked by**:
  - 建立 bank precompile 基线测试
  - 扩展 storageprovider precompile 基线测试
  - 建立 storage precompile 基线测试
- **User stories covered**:
  - 作为维护者，我需要看到测试基线已经闭环，而不是零散增加几个测试文件
  - 作为后续迁移执行者，我需要父计划和 issue 拆分反映真实基线范围

**What to build**

在三个模块的基线测试都落地后，执行一次测试矩阵收口：

- 跑通目标包测试和 `./x/evm/precompiles/...` 范围测试
- 将实际覆盖到的行为矩阵写回计划文档
- 如果某个模块因 fixture 复杂度缩小了范围，明确记录缩小原因和剩余缺口

**Acceptance criteria**

- [x] `go test ./x/evm/precompiles/bank ./x/evm/precompiles/storageprovider ./x/evm/precompiles/storage -count=1` 通过（在本地把三条基线分支八爪合并后验证，全绿）
- [x] `go test ./x/evm/precompiles/... -count=1` 通过（同上，全部 package 绿，无跨包破坏）
- [x] 父计划文档同步记录实际覆盖矩阵（见 [[Moca 预编译迁移前测试基线实施计划]] 的 Current Progress / 覆盖矩阵）
- [x] 子任务 0 的完成条件可以被明确勾选，而不是靠口头判断

> 说明：三条基线分支尚未合并进 `precompile-integration`（等同事审核 PR #333/#334/#335）。上面的矩阵验证是在本地临时八爪合并的集成态跑的；官方的合并后 sweep 需在三 PR 合并后于 `precompile-integration` 上再跑一次。

## 推荐依赖关系

推荐按以下顺序推进：

1. 建立 bank precompile 基线测试
2. 扩展 storageprovider precompile 基线测试
3. 建立 storage precompile 基线测试
4. 验证测试矩阵并回写父计划

## 建议发布顺序

如果要进一步转成 issue，建议按以下顺序发布：

1. 建立 bank precompile 基线测试
2. 扩展 storageprovider precompile 基线测试
3. 建立 storage precompile 基线测试
4. 验证测试矩阵并回写父计划

## 备注

- `bank` 和 `storageprovider` 可以并行推进；我这里把 `storage` 放在它们之后，是为了先收敛最便宜的 harness 和断言模式。
- `storage` 之所以没有标 `HITL`，是因为是否用 `createBucket` 只是 fixture 成本问题，不是协议层决策问题。
- 这个拆分仍然属于“测试基线”阶段，不意味着已经开始 precompile 原生运行时迁移。

## Related

- [[Moca 预编译迁移前测试基线实施计划]]
- [[Moca 预编译合约切换到 Cosmos EVM 原生模式子任务拆分]]
- [[Moca 预编译合约切换到 Cosmos EVM 原生模式计划]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
