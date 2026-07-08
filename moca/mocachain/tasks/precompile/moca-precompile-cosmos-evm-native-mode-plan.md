---
title: "Moca 预编译合约切换到 Cosmos EVM 原生模式计划"
aliases:
  - precompile-cosmos-evm-native-mode-plan
  - precompile-native-mode-plan
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
source_path: "tasks/precompile/moca-precompile-cosmos-evm-native-mode-plan.md"
---

> [!summary]
> 将 `moca` 当前自定义预编译合约执行模型，迁移为 `cosmos/evm v0.6.0` 的原生 precompile 模式，统一运行时、StateDB 同步、caller 语义与测试模型，并为“允许合约调用 precompile”提供安全落地路径。

> [!info]
> 长期有效的项目级知识已沉淀到 [[core/Precompile Architecture|Precompile Architecture]]。当前页保留任务目标、迁移策略和实施范围。

## Navigation
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[core/Precompile Architecture|Precompile Architecture]]

---

# Moca 预编译合约切换到 Cosmos EVM 原生模式计划

## 任务目标

将 `moca` 仓库中现有的链定制预编译合约，从“自定义 static precompile 兼容层”改为 `cosmos/evm` 官方原生实现模式，达到以下结果：

- 预编译运行时统一走 `cosmos/evm/precompiles/common.Precompile`
- 预编译状态变更统一走官方 `RunNativeAction` / `BalanceHandlerFactory`
- 预编译的 ABI 分发、只读校验、gas 计量、revert 语义与 `cosmos/evm` 官方实现一致
- 去除当前广泛存在的 `EOA-only` 限制，使合约可以调用 precompile
- 明确 caller / msg sender / tx origin 语义，不再依赖历史兼容行为

## 背景结论

### 当前已经完成的部分

- `moca` 已经切到 `github.com/cosmos/evm v0.6.0`
- `moca` 已经将 11 个预编译合约作为 static precompile 注册到 `EvmKeeper`
- `x/vm Params.ActiveStaticPrecompiles` 已经启用这些地址

因此，当前不是“还没接入 cosmos/evm”，而是：

- **EVM keeper 已迁移**
- **precompile 运行模式仍是自定义实现**

### 同事所说“把预编译合约用 cosmos/evm 的模式写”具体指什么

不是简单地替换依赖版本，而是将预编译合约改成 `cosmos/evm` 官方 precompile 组织方式：

1. 使用 `cosmos/evm/precompiles/common.Precompile` 作为统一基类
2. `Run()` 统一通过 `RunNativeAction(...)` 执行
3. `Execute(ctx, stateDB, contract, readonly)` 内统一处理 ABI 分发
4. 状态变更型 precompile 接入 `BalanceHandlerFactory`
5. 交易型方法按照官方模式以 `contract.Caller()` 作为直接调用者，而不是禁止合约调用

## 当前实现方式存在的问题

### 1. 运行时模型是自定义的，不是 Cosmos EVM 原生模型

当前 `moca/x/evm/precompiles/*/contract.go` 中每个 precompile 都在手动处理：

- `StateDB.GetCacheContext()`
- `CacheContext()`
- `Snapshot()`
- `RevertToSnapshot()`
- `commit()`

这套逻辑在多个 precompile 中重复出现，容易漂移，也难与官方实现保持一致。

### 2. Balance / StateDB 同步机制没有按官方模式接入

`cosmos/evm` 官方 precompile 在状态变更型场景中，会通过 `BalanceHandlerFactory` 把 Cosmos bank 事件同步回 EVM `StateDB`。

`moca` 当前 static precompile 没有统一使用这套机制，已经产生过一类高风险问题：

- `2026-06-29` 修复 `fix(evm)!: reject native value to precompiles (prevents mint via StateDB reconciliation)`

问题本质：

- keeper 侧真实资金变更
- EVM 内存 `StateDB` 余额变化
- 两边没有通过官方 balance handler 统一协调

最终导致：

- 带原生 value 调 precompile 时，可能在提交阶段产生错误对账，等效铸币

虽然该问题已经通过“统一拒绝 precompile 接收 native value”临时封堵，但它说明当前模式与官方模型存在结构性偏差。

### 3. 交易型 precompile 广泛使用 `EOA-only` 限制

当前大量 `tx.go` 里都有：

- `if evm.Origin != contract.Caller() { ... }`
- 或等价的 `only allow EOA can call this method`

这会导致：

- 合约不能转发调用 precompile
- 业务逻辑依赖 `tx.origin`
- caller 语义与 `cosmos/evm` 官方实现不一致

### 4. caller 语义混杂

当前系统里同时存在三套语义：

- `evm.Origin`
- `contract.Caller()`
- Cosmos `Msg` 中的 sender / operator / voter / delegator 等字段

这导致：

- 审计边界难以清晰定义
- 合约调用场景难以安全扩展
- 升级 `cosmos/evm` 时兼容成本高

## 本任务的目标状态

### 最终目标

预编译合约应改为 **Cosmos EVM 原生模式**，即：

- 允许合约直接调用 precompile
- 业务身份以 **直接调用者 `contract.Caller()`** 为准
- ABI 参数中的 sender / operator / voter 等字段，需要与 `contract.Caller()` 对齐
- 不再把 `tx.origin` 当作预编译权限主体

### 为什么最终目标不应停留在 `tx.origin` 模式

虽然短期可以做“允许 contract 调用，但仍按 `tx.origin` 作为业务主体”的兼容过渡方案，但它不是原生模式，原因有三点：

1. `tx.origin` 语义天然鼓励中间合约代用户执行敏感操作，边界不清
2. 与 `cosmos/evm` 官方 precompile 的 direct caller 模型不一致
3. 会继续保留当前兼容层语义，无法真正完成“完全切换到 cosmos/evm”

因此：

- **兼容过渡方案可以作为阶段性落地手段**
- **但本任务的完成标准应是 direct caller 原生模式**

## 推荐实施策略

采用两阶段推进。

### Phase 1：运行时和 StateDB 模型先对齐

目标：

- 不先大改所有业务方法签名
- 先统一运行时执行骨架
- 先把 precompile 的 `Run/Execute/BalanceHandler` 对齐到官方模式
- 同时保留“拒绝 native value”的硬约束

这一阶段应完成：

- 引入统一的 `moca` precompile base 层，薄封装 `cosmos/evm/common.Precompile`
- 每个 precompile 改成官方 `Run -> Execute` 模式
- 交易型方法改为接收 `stateDB vm.StateDB`
- query / tx 分发改为统一 ABI setup
- 对有 bank 余额变化副作用的 precompile 接入 `BalanceHandlerFactory`

### Phase 2：caller 语义切到 direct caller

目标：

- 去掉 `EOA-only`
- 去掉基于 `evm.Origin` 的权限判断
- 改为“参数里的业务地址 == `contract.Caller()`”
- 所有 Cosmos msg sender / operator / voter / delegator 统一从 direct caller 推导

这一阶段应完成：

- 审核每个交易型 precompile 的业务身份字段
- 删除 `ErrInvalidCaller` 这类“禁止合约调用”逻辑
- 重写测试，覆盖 EOA 直调与 contract 转调

## 任务范围

### 代码范围

主仓库：

- `moca/`

重点目录：

- `moca/app/app.go`
- `moca/x/evm/precompiles/`
- `moca/x/storage/keeper/evm.go`
- `moca/x/storage/types/expected_keepers.go`
- 相关测试目录

### 重点预编译模块

共有 11 个 static precompile：

- `bank`
- `authz`
- `gov`
- `payment`
- `permission`
- `staking`
- `distribution`
- `slashing`
- `storage`
- `storageprovider`
- `virtualgroup`

其中优先风险最高、最值得先改的为：

- `bank`
- `storage`
- `payment`
- `storageprovider`
- `gov`

原因：

- 这些模块与资金、权限、跨模块 msg sender 语义最强相关

## 关键设计决策

### 决策 0：先建立迁移前测试基线，再改 precompile 运行时

在开始任何 precompile 原生模式迁移前，必须先补一组 `characterization tests`，把当前行为固定下来，避免运行时重写时“看起来通过、实际语义漂移”。

这一步不是追求一次性把所有模块测试补完，而是先覆盖最容易在迁移中退化的高风险路径：

- static precompile dispatch 是否真的经过 `EvmKeeper`
- 交易型方法当前的 `EOA-only` 行为
- `RejectValue(contract)` 守卫
- `readonly` 写保护
- keeper / msg 执行失败时的回滚语义
- 关键余额变化路径的 Cosmos 状态与 `StateDB` 一致性

没有这组基线测试，不应直接进入 `Run()/Execute()/BalanceHandler` 重构。

### 决策 1：保留“precompile 不接受 native value”

无论是否切到原生模式，都必须继续保留：

- `RejectValue(contract)`

原因：

- 当前 `moca` 不是 ERC-20 / WERC20 官方实现路径
- 原生币 value 转移与 keeper 资金变更仍然存在双写风险
- 在没有充分证明“所有余额变化都能安全回写 StateDB”之前，禁止 native value 是必须的

### 决策 2：交易型 precompile 最终按 direct caller 鉴权

即：

- 不再允许 `tx.origin` 代表业务主体
- `contract.Caller()` 才是预编译执行主体

### 决策 3：过渡期可以保留一个兼容层开关，但不是最终目标

如果业务需要先快速放开“合约可调用 precompile”，可以临时提供：

- feature flag
- 或单独的兼容 helper

但文档与代码必须明确：

- 这是迁移过渡态
- 不是最终实现

## 建议拆分的实施任务

### Task 0：建立迁移前测试基线

目标：

- 在不改变现有实现语义的前提下，先把迁移风险最大的行为写成回归测试

建议优先覆盖：

- `bank`：value reject、EOA-only、至少 1 条经过 `EvmKeeper` 的真实 dispatch 路径、至少 1 条余额副作用校验
- `storageprovider`：保留现有 EVM apply 路径测试，并补 caller / revert 语义
- `storage`：至少选择 1 个代表性写方法，覆盖 EOA-only、dispatch、失败回滚

完成标准：

- 至少 `bank`、`storageprovider`、`storage` 三个模块具有迁移前基线测试
- 明确断言当前“contract 转调会失败”的历史行为，而不是只测成功路径
- 明确断言 nonzero native value 会失败
- 至少一组测试覆盖 keeper/msg 失败后的状态回滚

### Task 1：抽取 moca precompile 原生基类

目标：

- 为 `moca` 预编译建立统一运行时骨架

需要做的事：

- 在 `moca/x/evm/precompiles/` 下新增公共 base 包
- 封装：
  - ABI setup
  - `RunNativeAction`
  - `Execute`
  - tx/query method dispatch helper
  - value reject helper
  - event emit helper

完成标准：

- 至少一个 precompile 能完全跑通新基类

### Task 2：将一个代表性 precompile 迁移到原生模式

建议先选：

- `bank`

原因：

- 方法数量适中
- 读写混合
- 涉及余额变化，能验证 BalanceHandler 是否接对

完成标准：

- `bank` 不再使用手写 `Run()`
- `bank` 使用官方 balance handler 模型
- 原有 query / tx 都能通过测试

### Task 3：迁移 storage/payment/storageprovider

原因：

- 这些模块是 Moca 自定义业务最核心的 precompile
- 也是将来合约最可能调用的对象

完成标准：

- 统一接入原生执行模型
- 清理 EOA-only 分支
- 定义 direct caller 身份语义

### Task 4：迁移 gov/authz/staking/distribution/slashing/permission/virtualgroup

原因：

- 覆盖剩余所有 static precompile

完成标准：

- 所有 11 个 precompile 统一到同一模式

### Task 5：重构跨模块内部 EVM 调用的辅助层

涉及：

- `x/storage/keeper/evm.go`
- 相关 keeper mock / expected keeper interface

目标：

- 确保 keeper 内部 `CallEVM` / `CallEVMWithData` 仍兼容新的 precompile 执行模型
- 明确 `callFromPrecompile`、`commit`、`stateDB` 的传递边界

### Task 6：补齐测试矩阵

必须覆盖：

- 迁移前 characterization tests 持续保留为回归测试
- EOA 直接调用 precompile
- 合约调用 precompile
- query 方法调用
- tx 方法调用
- 带 native value 调用应失败
- 多层嵌套调用 / revert / out-of-gas
- 事件日志和余额同步

## 需要重点验证的问题

### 1. 合约调用后业务身份是否正确

需要逐个确认：

- `bank.send` 的 `FromAddress`
- `storage.createBucket` 的 `Creator`
- `gov.vote` 的 `Voter`
- `staking.delegate` 的 `DelegatorAddress`

在原生模式下都应与 `contract.Caller()` 一致。

### 2. BalanceHandler 是否足以覆盖 Moca 自定义预编译的余额侧效果

官方 `BalanceHandler` 是通过 Cosmos bank / precisebank 事件回写 `StateDB`。

需要确认：

- `payment`
- `storage`
- `storageprovider`

这些自定义逻辑里是否存在不会产出标准 bank 事件、但会改变余额的路径。

如果存在：

- 需要补自定义 balance sync 逻辑
- 或明确继续禁止相关 value / balance 路径

### 3. 内部 keeper 调 precompile 是否仍然安全

例如：

- `x/storage/keeper/evm.go`

要确认：

- keeper 内部发起的 EVM 调用是否会被新的 caller 语义误伤
- 是否需要把“内部系统调用”和“外部用户调用”区分开

### 4. 是否存在 ABI 参数与 direct caller 不一致的历史接口

官方模式通常要求：

- 参数里的 sender 与 `contract.Caller()` 一致

`moca` 当前很多方法是直接把 `contract.Caller()` 写进 msg，没有给 ABI 参数保留显式 sender 字段。

需要确认：

- 这是否已经足够
- 是否需要在 ABI 里补 sender 字段
- 或继续沿用“sender 由 precompile 自动注入”

## 建议的完成标准

本任务完成时，应满足：

1. 11 个 static precompile 都改为 `cosmos/evm` 原生执行模式
2. 不再使用大面积复制的手写 `Run()/cacheCtx/snapshot/commit` 模板
3. 不再依赖 `evm.Origin != contract.Caller()` 进行 EOA-only 限制
4. 合约可以直接调用 precompile
5. caller 语义、Cosmos msg sender 语义、事件语义均有明确文档和测试
6. `RejectValue(contract)` 仍然保留
7. 相关单测、集成测试、EVM 调用测试全部通过

## 不在本任务范围内

以下内容不应与本任务混做：

- 升级到 `cosmos/evm v0.7.x`
- 顺手重写所有 Solidity 接口
- 引入新的动态 precompile 体系
- 同时重构所有 keeper 内部 EVM 业务逻辑
- 改 ERC-20 / WERC20 路线

## 推荐执行顺序

1. 建立迁移前测试基线
2. 抽公共原生基类
3. 迁移 `bank`
4. 验证 balance handler 行为
5. 迁移 `storage` / `payment` / `storageprovider`
6. 迁移其余模块
7. 删除历史 EOA-only 兼容路径
8. 收口测试与文档

## 风险说明

### 高风险

- caller 语义变化可能影响现有业务侧预期
- balance sync 不完整可能再次引入资金不一致问题
- 内部 keeper 调用路径可能和外部用户路径语义冲突

### 中风险

- ABI 行为变化导致 SDK / CLI / 集成测试不兼容
- query / tx gas 计算与旧逻辑偏差

### 低风险

- precompile 注册表和 active list 本身已经存在，调整成本较低

## 建议补充文档

任务实施时，建议同步补齐：

- `moca` 内部 precompile 架构说明
- caller 语义说明
- “为什么继续禁止 native value” 的安全说明
- 从旧模式到原生模式的迁移说明

## Related
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
