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
> 将“把当前预编译合约实现方式改成 `cosmos/evm` 原生模式”的总任务，拆分为一组可独立推进、可验证、尽量 AFK 的子任务。

> [!info]
> 长期有效的项目级知识已沉淀到 [[core/Precompile Architecture|Precompile Architecture]]。当前页保留任务拆分、执行边界和阶段依赖。

## Navigation
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[Moca 预编译合约切换到 Cosmos EVM 原生模式计划]]
- [[core/Precompile Architecture|Precompile Architecture]]

---

# Moca 预编译合约切换到 Cosmos EVM 原生模式子任务拆分

## 拆分原则

本拆分遵循以下原则：

- 每个子任务尽量是一个可验证的垂直切片，而不是纯横向重构
- 每个子任务完成后，应至少能独立通过一组针对性测试
- 尽量优先 AFK 子任务，减少必须停下来等设计确认的节点
- 对 caller 语义风险高的部分，先通过“运行时模型对齐”把基础设施收敛，再进入业务身份切换

## 子任务列表

### 0. 建立迁移前测试基线

- **Title**: 建立迁移前测试基线
- **Type**: AFK
- **Blocked by**: None - should happen before runtime refactor
- **User stories covered**:
  - 作为迁移执行者，我需要先把当前 precompile 行为冻结成回归测试，避免重写运行时后静默改变语义
  - 作为审计者，我需要在迁移前就看到 caller、回滚、value-reject、dispatch 这些高风险路径的明确断言

**What to build**

在不改变现有 precompile 代码行为的前提下，先补一组迁移前 `characterization tests`，优先覆盖：

- `bank`：`RejectValue(contract)`、`EOA-only`、至少 1 条经过 `EvmKeeper` 的真实 dispatch 路径、至少 1 条余额副作用校验
- `storageprovider`：保留并扩展现有 EVM apply 测试，补 caller / revert 语义
- `storage`：至少选 1 个代表性交易型方法，覆盖 `EOA-only`、dispatch、失败回滚

这一任务的目标不是一次性补齐所有模块，而是先把后续运行时迁移最容易打坏的行为固定下来。

**Acceptance criteria**

- [ ] `bank`、`storageprovider`、`storage` 至少各有一组迁移前基线测试
- [ ] 明确覆盖当前“EOA 直调成功、contract 转调失败”的历史行为
- [ ] 明确覆盖 `RejectValue(contract)` 与 readonly / revert 中至少两类关键保护语义
- [ ] 至少一组测试真正通过 `EvmKeeper` 触发 static precompile dispatch，而不是只测 ABI decode

### 1. 建立 Moca 预编译原生运行时基座

- **Title**: 建立 Moca 预编译原生运行时基座
- **Type**: AFK
- **Blocked by**:
  - 建立迁移前测试基线
- **User stories covered**:
  - 作为链开发者，我需要一个统一的 precompile 运行时骨架，避免每个模块手写 `Run/cacheCtx/snapshot/commit`
  - 作为后续迁移任务的执行者，我需要一个可复用的 base 层来承接 `cosmos/evm` 原生模式

**What to build**

在 `moca/x/evm/precompiles/` 下建立统一的 Moca precompile 基座，薄封装 `cosmos/evm/precompiles/common.Precompile` 的运行方式，用于后续模块迁移。该任务不要求一次性迁移全部业务模块，但要提供足够稳定的公共入口，覆盖：

- `Run -> RunNativeAction -> Execute` 的统一执行骨架
- ABI setup / tx-query 分流 helper
- 统一的 revert / gas / readonly 处理约定
- 保留 `RejectValue(contract)` 作为所有 precompile 的公共前置校验

**Acceptance criteria**

- [ ] `moca` 中新增统一的 precompile base 层，而不是继续复制每个模块自己的 `Run()` 模板
- [ ] 公共层明确支持 `Execute(ctx, stateDB, contract, readonly)` 这一原生执行模式
- [ ] 公共层保留对 nonzero native value 的统一拒绝
- [ ] 至少有一组公共层单元测试覆盖基础执行流程或 helper 行为

### 2. 将 bank precompile 迁移到原生模式

- **Title**: 将 bank precompile 迁移到原生模式
- **Type**: AFK
- **Blocked by**:
  - 建立迁移前测试基线
  - 建立 Moca 预编译原生运行时基座
- **User stories covered**:
  - 作为链开发者，我需要一个代表性的官方模式 precompile 样板
  - 作为后续任务执行者，我需要先验证余额同步和 tx/query 分流是否跑通

**What to build**

将 `bank` 预编译从当前自定义执行模型改到 `cosmos/evm` 原生模式，完整接入统一运行时基座，并验证：

- query / tx 方法 ABI 分流
- 余额变化是否通过官方 balance handler 模型同步回 `StateDB`
- `RejectValue(contract)` 是否继续生效

该任务不要求放开“合约调用”，可以先只完成运行时模型对齐。

**Acceptance criteria**

- [ ] `bank` 不再使用当前手写 `Run()/GetCacheContext()/commit()` 模式
- [ ] `bank` 改为通过统一基座执行
- [ ] `bank` 对资金变化路径接入 balance handler 语义
- [ ] `bank` 现有 query / tx 测试通过，并补充原生运行时路径测试

### 3. 将 storage 系列预编译迁移到原生模式

- **Title**: 将 storage 系列预编译迁移到原生模式
- **Type**: AFK
- **Blocked by**:
  - 建立迁移前测试基线
  - 建立 Moca 预编译原生运行时基座
  - 将 bank precompile 迁移到原生模式
- **User stories covered**:
  - 作为链开发者，我需要将 Moca 最核心的 storage 业务 precompile 迁移到官方执行模型
  - 作为审计者，我需要 storage 相关 precompile 的 StateDB / keeper 执行边界清晰一致

**What to build**

迁移 `storage`、`payment`、`storageprovider`、`virtualgroup` 这组 Moca 自定义业务最强的 precompile，使它们统一使用原生执行模型。重点是：

- 统一 `Run/Execute`
- 清理手写 cache / snapshot 逻辑
- 验证是否存在需要额外补的 balance 同步路径

**Acceptance criteria**

- [ ] `storage`、`payment`、`storageprovider`、`virtualgroup` 都改为统一运行时模型
- [ ] 不再各自维护复制粘贴式的 `Run()` 模板
- [ ] 对涉及余额副作用的路径明确验证 balance sync 是否完整
- [ ] 至少补一组 end-to-end 测试，证明 cosmos/evm static precompile dispatch 仍然生效

### 4. 将治理与系统模块预编译迁移到原生模式

- **Title**: 将治理与系统模块预编译迁移到原生模式
- **Type**: AFK
- **Blocked by**:
  - 建立迁移前测试基线
  - 建立 Moca 预编译原生运行时基座
  - 将 bank precompile 迁移到原生模式
- **User stories covered**:
  - 作为链开发者，我需要让剩余系统类 precompile 的实现方式统一
  - 作为维护者，我需要降低后续升级 `cosmos/evm` 时的兼容成本

**What to build**

迁移以下模块到原生模式：

- `authz`
- `gov`
- `staking`
- `distribution`
- `slashing`
- `permission`

这组模块的重点不是余额同步，而是 tx/query 分流、只读语义、事件发射以及 caller 约束的未来统一。

**Acceptance criteria**

- [ ] 以上模块都切换到统一 precompile 运行时模型
- [ ] 保持 ABI、query、event 基本兼容
- [ ] 保留 `RejectValue(contract)` 和只读保护
- [ ] 模块级测试覆盖 Execute 路径

### 5. 重构内部 keeper 调用层以兼容原生 precompile 模型

- **Title**: 重构内部 keeper 调用层以兼容原生 precompile 模型
- **Type**: AFK
- **Blocked by**:
  - 建立迁移前测试基线
  - 将 bank precompile 迁移到原生模式
  - 将 storage 系列预编译迁移到原生模式
- **User stories covered**:
  - 作为链开发者，我需要 keeper 内部 EVM 调用继续在新模式下可用
  - 作为维护者，我需要明确 `CallEVM/CallEVMWithData/stateDB/callFromPrecompile` 的边界

**What to build**

梳理并重构 `x/storage/keeper/evm.go` 及其相关 interface / mock，使 keeper 内部 EVM 调用与新的 precompile 执行模式兼容。重点关注：

- `stateDB` 的创建与传递
- `commit` 语义
- `callFromPrecompile` 的传递边界
- 内部系统调用与外部用户调用的差异

**Acceptance criteria**

- [ ] `x/storage/keeper/evm.go` 与新运行时模型兼容
- [ ] 对应 `expected_keepers.go` / mocks 同步更新
- [ ] storage keeper 相关测试继续通过
- [ ] 内部 EVM 调用路径有明确测试覆盖

### 6. 清理 EOA-only 限制并引入合约调用支持

- **Title**: 清理 EOA-only 限制并引入合约调用支持
- **Type**: HITL
- **Blocked by**:
  - 建立迁移前测试基线
  - 将 bank precompile 迁移到原生模式
  - 将 storage 系列预编译迁移到原生模式
  - 将治理与系统模块预编译迁移到原生模式
- **User stories covered**:
  - 作为合约开发者，我希望合约能够直接调用 precompile
  - 作为协议设计者，我需要明确 caller / msg sender 的最终语义

**Why HITL**

这是整个任务里最敏感的决策点，因为这里会从“EOA-only”切换到“允许合约调用”，并且需要最终确定：

- 是短期兼容 `tx.origin`
- 还是直接切到 `contract.Caller()` 原生语义

当前总计划建议最终目标是 direct caller 原生语义，因此该任务默认按最终目标推进，但需要人工确认不会破坏外部集成预期。

**What to build**

删除所有交易型 precompile 中的 `EOA-only` 限制，并统一 caller 鉴权语义。默认目标：

- 允许合约调用
- 业务身份按 `contract.Caller()` 计算
- Cosmos msg sender / operator / voter / delegator 与 direct caller 对齐

**Acceptance criteria**

- [ ] 交易型 precompile 不再通过 `evm.Origin != contract.Caller()` 拒绝合约调用
- [ ] caller 语义在代码与文档中得到统一定义
- [ ] 新增测试覆盖“EOA 直调”和“contract 转调”
- [ ] 明确记录不再以 `tx.origin` 作为预编译权限主体

### 7. 补齐全量测试与迁移文档

- **Title**: 补齐全量测试与迁移文档
- **Type**: AFK
- **Blocked by**:
  - 重构内部 keeper 调用层以兼容原生 precompile 模型
  - 清理 EOA-only 限制并引入合约调用支持
- **User stories covered**:
  - 作为维护者，我需要完整测试矩阵证明迁移是安全的
  - 作为后续升级执行者，我需要书面化的 precompile 架构与 caller 语义说明

**What to build**

完成整项迁移后的收口工作：

- 完整测试矩阵
- caller 语义文档
- “继续拒绝 native value” 的安全说明
- 预编译原生模式迁移说明

**Acceptance criteria**

- [ ] 覆盖 EOA、contract、readonly、revert、value-reject、nested-call 的测试矩阵齐全
- [ ] 相关 lint / typecheck / test 全部通过
- [ ] `moca` 内部新增或更新 precompile 架构说明文档
- [ ] 迁移文档说明当前模式已从兼容层切换为 `cosmos/evm` 原生模式

## 推荐依赖关系

推荐按以下顺序推进：

1. 建立迁移前测试基线
2. 建立 Moca 预编译原生运行时基座
3. 将 bank precompile 迁移到原生模式
4. 将 storage 系列预编译迁移到原生模式
5. 将治理与系统模块预编译迁移到原生模式
6. 重构内部 keeper 调用层以兼容原生 precompile 模型
7. 清理 EOA-only 限制并引入合约调用支持
8. 补齐全量测试与迁移文档

## 建议发布顺序

如果要进一步转成 issue，建议先发布 blocker：

1. 建立迁移前测试基线
2. 建立 Moca 预编译原生运行时基座
3. 将 bank precompile 迁移到原生模式
4. 将 storage 系列预编译迁移到原生模式
5. 将治理与系统模块预编译迁移到原生模式
6. 重构内部 keeper 调用层以兼容原生 precompile 模型
7. 清理 EOA-only 限制并引入合约调用支持
8. 补齐全量测试与迁移文档

## 备注

- 当前拆分刻意把“运行时对齐”和“caller 语义切换”分开，以降低一次性变更风险。
- 其中第 6 个子任务被标记为 `HITL`，不是因为无法实现，而是因为它最可能影响业务/集成预期，应当在落地前再次确认。

## Related
- [[Moca 预编译合约切换到 Cosmos EVM 原生模式计划]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
