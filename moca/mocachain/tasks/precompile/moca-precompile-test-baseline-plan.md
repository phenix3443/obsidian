---
title: "Moca 预编译迁移前测试基线实施计划"
aliases:
  - precompile-test-baseline-plan
  - moca-precompile-characterization-tests-plan
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
source_path: "tasks/precompile/moca-precompile-test-baseline-plan.md"
---

> [!summary]
> 在重写 `moca` precompile 运行时之前，先建立一组迁移前 `characterization tests`，固定当前 `EOA-only`、`RejectValue`、static precompile dispatch、回滚语义和关键状态副作用。

## Navigation
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[Moca 预编译合约切换到 Cosmos EVM 原生模式计划]]
- [[Moca 预编译合约切换到 Cosmos EVM 原生模式子任务拆分]]

---

# Moca Precompile Test Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development`（推荐）或 `executing-plans` 按任务执行。所有步骤使用 checkbox 跟踪。

**Goal:** 在不修改 precompile 业务实现的前提下，为 `bank`、`storageprovider`、`storage` 建立迁移前测试基线，作为后续切换到 `cosmos/evm` 原生模式的回归锚点。

**Architecture:** 复用 `moca` 现有 `app.EthSetup`、`statedb.New`、`EvmKeeper.CallEVMWithData` 测试入口，不新增新的运行时抽象。测试分成两层：一层用真实 `EvmKeeper` 验证 static precompile dispatch 和状态副作用，另一层用直接构造 `vm.Contract` 的轻量测试固定 `EOA-only` / `readonly` 等守卫行为。

**Tech Stack:** Go, `testing`, `testify/suite`, `cosmos/evm/x/vm/statedb`, `app.EthSetup`, `EvmKeeper.CallEVMWithData`

## Global Constraints

- 不修改 `moca/x/evm/precompiles/*` 生产代码。
- 不提前去掉 `evm.Origin != contract.Caller()` 守卫。
- 不放开 native `value`；`RejectValue(contract)` 仍然必须失败。
- 优先复用现有测试 harness，避免在基线阶段引入共享测试框架。
- 至少一组测试必须真实经过 `EvmKeeper` 和 `Params.ActiveStaticPrecompiles`。
- 每个模块先覆盖一条最具代表性的写路径，不追求一次性铺满全部 11 个 precompile。

## Current Progress

三个模块的迁移前基线已全部落地，各自开 PR 合入集成分支 `precompile-integration`，等待同事审核：

- `bank`：`precompile/bank-baseline`，**PR #333**。基线 commit `2ec1079d` 曾从主干丢失，已重建 `tx_test.go` + `run_value_test.go`，并修掉当前 lint gate 报的两处问题。
- `storageprovider`：`precompile/storageprovider-baseline`，**PR #334**。保留 `TestUpdateSPPrice_EVMApply` 成功路径，新增 EOA-only 与失败不污染状态断言。
- `storage`：`precompile/storage-baseline`，**PR #335**。改用 `createGroup`（而非 `createBucket`，见 Method Selection 更新）建立成功/EOA-only/失败三类基线。

### 实际执行的覆盖矩阵

```text
bank (PR #333):
- RejectValue（nonzero native value 拒绝）        TestRun_RejectsNonzeroValue
- EOA-only 拒绝 contract 转调                     TestBankSend_RejectsContractForwarding
- 真实 EvmKeeper dispatch 成功 + 余额变化          TestBankSend_EVMDispatchSuccess
- 失败路径 sender/receiver 余额不变                TestBankSend_FailureDoesNotChangeBalances

storageprovider (PR #334):
- 真实 EVM dispatch 成功（保留）                   TestUpdateSPPrice_EVMApply
- EOA-only 拒绝 contract 转调                     TestUpdateSPPrice_RejectsContractForwarding
- 失败路径不污染 SP price 状态                     TestUpdateSPPrice_FailureDoesNotMutateState

storage (PR #335, 方法=createGroup):
- 真实 EVM dispatch 成功（group 创建，owner==caller） TestCreateGroup_EVMDispatchSuccess
- EOA-only 拒绝 contract 转调                     TestCreateGroup_RejectsContractForwarding
- 失败路径（重复 group 名）干净回滚，原 group 不变   TestCreateGroup_FailureDoesNotMutateState
```

验证：在本地把三条基线分支八爪合并后，`go test ./x/evm/precompiles/bank ./x/evm/precompiles/storageprovider ./x/evm/precompiles/storage -count=1` 与 `go test ./x/evm/precompiles/... -count=1` 全绿，无跨包破坏、无合并冲突。官方的合并后 sweep 需在三 PR 合并进 `precompile-integration` 后再跑一次。

## File Structure

- Modify: `moca/x/evm/precompiles/bank/run_value_test.go`
  责任：保留并补充 `RejectValue` 基础守卫的断言说明，避免后续迁移时误删前置 value guard。
- Create: `moca/x/evm/precompiles/bank/tx_test.go`
  责任：新增 `bank.send` 的 EVM dispatch、EOA-only、失败不改余额三类基线测试。
- Modify: `moca/x/evm/precompiles/storageprovider/tx_test.go`
  责任：在现有 `updateSPPrice` 成功路径基础上，补充 caller 语义、readonly / revert 类行为测试。
- Create: `moca/x/evm/precompiles/storage/tx_evm_apply_test.go`
  责任：为 `storage.createBucket` 新增真实 EVM dispatch、EOA-only、失败回滚基线测试。
- No production code changes

## Harness Choices

- 统一复用 `moca/app/ethtest_helper.go` 中的 `app.EthSetup(...)`。
- 所有真实 dispatch 测试都显式设置：
  - `evmParams.EvmDenom = utils.BaseDenom`
  - `evmParams.ActiveStaticPrecompiles = app.MocaActiveStaticPrecompiles()`
- 真实 EVM 调用统一走：
  - `stateDB := statedb.New(ctx, app.EvmKeeper, statedb.NewEmptyTxConfig())`
  - `app.EvmKeeper.CallEVMWithData(...)`
- `contract 转调失败` 的历史行为，不要求在本阶段引入真实 forwarding contract；使用 `evm.Origin != contract.Caller()` 的直接单元测试固定现有语义即可。

## Method Selection

- `bank`: `send`
  原因：最小但真实地覆盖余额变化、日志、副作用与失败不改余额。
- `storageprovider`: `updateSPPrice`
  原因：已有 EVM dispatch 成功样板，可最小增量补齐 caller / readonly / revert 语义。
- `storage`: `createGroup`（原计划为 `createBucket`，实施时按 Open Risk 替换）
  原因：`createBucket` 成功路径 fixture 过重（需注册 primary SP、global virtual group family、payment 前置、以及有效的 SP approval 签名）；`createGroup` 是确定性交易型写路径，仅需 funded creator，且同样覆盖 `Creator = contract.Caller()`、事件与创建副作用。EOA-only 守卫与 `Run` 快照/回滚是所有 storage tx 方法共用的。
  注意：`createGroup` 内部会向 group ERC721（`0x3002`）发 mint，其 sender 为 control-hub 账户 `0x…dead`；EthSetup 精简 genesis 未建该账户，测试在 SetupTest 里注册它作为 fixture。

---

### Task 1: Build Bank Characterization Tests

**Files:**
- Modify: `moca/x/evm/precompiles/bank/run_value_test.go`
- Create: `moca/x/evm/precompiles/bank/tx_test.go`
- Test: `moca/x/evm/precompiles/bank/tx_test.go`

**Interfaces:**
- Consumes:
  - `app.EthSetup(isCheckTx bool, patchGenesis func(*app.Moca, simapp.GenesisState) simapp.GenesisState) *app.Moca`
  - `app.MocaActiveStaticPrecompiles() []string`
  - `(*keeper.Keeper).CallEVMWithData(...)`
  - `bank.GetAddress() common.Address`
  - `bank.GetAbiMethod(bank.SendMethodName) abi.Method`
- Produces:
  - `TestBankSend_EVMDispatchSuccess`
  - `TestBankSend_RejectsContractForwarding`
  - `TestBankSend_FailureDoesNotChangeBalances`

- [ ] **Step 1: Write the failing tests**

```go
func TestBankSend_EVMDispatchSuccess(t *testing.T) {
	// build EthSetup app + context
	// fund caller with base denom
	// enable ActiveStaticPrecompiles
	// pack bank.send(to, amount) calldata
	// call through EvmKeeper.CallEVMWithData
	// assert receiver balance increases and sender balance decreases
}

func TestBankSend_RejectsContractForwarding(t *testing.T) {
	// construct vm.Contract with Origin != Caller()
	// invoke c.Send(..., readonly=false)
	// assert error contains "only allow EOA can call this method"
}

func TestBankSend_FailureDoesNotChangeBalances(t *testing.T) {
	// build EthSetup app + context
	// fund caller with a small balance
	// attempt send amount > balance through EvmKeeper.CallEVMWithData
	// assert call fails and both sender/receiver balances stay unchanged
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `go test ./x/evm/precompiles/bank -run 'TestBankSend_' -count=1`
Expected: FAIL because the new tests do not exist yet

- [ ] **Step 3: Implement the minimal tests**

```go
func mustEnableStaticPrecompiles(t *testing.T, ctx sdk.Context, app *app.Moca) {
	evmParams := app.EvmKeeper.GetParams(ctx)
	evmParams.EvmDenom = utils.BaseDenom
	evmParams.ActiveStaticPrecompiles = app.MocaActiveStaticPrecompiles()
	require.NoError(t, app.EvmKeeper.SetParams(ctx, evmParams))
}

func mustPackBankSendInput(t *testing.T, to common.Address, amount *big.Int) []byte {
	method := GetAbiMethod(SendMethodName)
	packedArgs, err := method.Inputs.Pack(to, []types.Coin{{Denom: utils.BaseDenom, Amount: amount}})
	require.NoError(t, err)
	return append(append([]byte{}, method.ID...), packedArgs...)
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `go test ./x/evm/precompiles/bank -run 'TestRun_RejectsNonzeroValue|TestBankSend_' -count=1`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add x/evm/precompiles/bank/run_value_test.go x/evm/precompiles/bank/tx_test.go
git commit -m "test(evm): add bank precompile baseline tests"
```

---

### Task 2: Extend StorageProvider Baseline Tests

**Files:**
- Modify: `moca/x/evm/precompiles/storageprovider/tx_test.go`
- Test: `moca/x/evm/precompiles/storageprovider/tx_test.go`

**Interfaces:**
- Consumes:
  - existing `PrecompileTestSuite` in `storageprovider/tx_test.go`
  - `storageprovider.GetAbiMethod(storageprovider.UpdateSPPriceMethodName)`
  - `storageprovider.GetAddress() common.Address`
- Produces:
  - `TestUpdateSPPrice_EVMApply`
  - `TestUpdateSPPrice_RejectsContractForwarding`
  - `TestUpdateSPPrice_FailureDoesNotMutateState`

- [ ] **Step 1: Write the failing tests**

```go
func (s *PrecompileTestSuite) TestUpdateSPPrice_RejectsContractForwarding() {
	// direct-call Contract.UpdateSPPrice with Origin != Caller()
	// assert "only allow EOA can call this method"
}

func (s *PrecompileTestSuite) TestUpdateSPPrice_FailureDoesNotMutateState() {
	// omit SP registration or set invalid precondition
	// execute through EvmKeeper.CallEVMWithData
	// assert call fails and no SP price record is written
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `go test ./x/evm/precompiles/storageprovider -run 'TestPrecompileTestSuite/TestUpdateSPPrice_' -count=1`
Expected: FAIL because the new suite methods do not exist yet

- [ ] **Step 3: Implement the minimal tests**

```go
func (s *PrecompileTestSuite) mustEnableStaticPrecompiles() {
	evmParams := s.app.EvmKeeper.GetParams(s.ctx)
	evmParams.EvmDenom = utils.BaseDenom
	evmParams.ActiveStaticPrecompiles = app.MocaActiveStaticPrecompiles()
	s.Require().NoError(s.app.EvmKeeper.SetParams(s.ctx, evmParams))
}

func (s *PrecompileTestSuite) mustPackUpdateSPPriceInput(
	readPrice *big.Int,
	freeReadQuota uint64,
	storePrice *big.Int,
) []byte {
	method := storageprovider.GetAbiMethod(storageprovider.UpdateSPPriceMethodName)
	packedArgs, err := method.Inputs.Pack(readPrice, freeReadQuota, storePrice)
	s.Require().NoError(err)
	return append(append([]byte{}, method.ID...), packedArgs...)
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `go test ./x/evm/precompiles/storageprovider -run 'TestPrecompileTestSuite/TestUpdateSPPrice_' -count=1`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add x/evm/precompiles/storageprovider/tx_test.go
git commit -m "test(evm): extend storageprovider precompile baseline"
```

---

### Task 3: Add Storage CreateBucket Baseline Tests

**Files:**
- Create: `moca/x/evm/precompiles/storage/tx_evm_apply_test.go`
- Test: `moca/x/evm/precompiles/storage/tx_evm_apply_test.go`

**Interfaces:**
- Consumes:
  - `app.EthSetup(...)`
  - `storage.GetAbiMethod(storage.CreateBucketMethodName)`
  - `storage.GetAddress() common.Address`
  - `storagetypes.MsgCreateBucket` preconditions
- Produces:
  - `TestCreateBucket_EVMDispatchSuccess`
  - `TestCreateBucket_RejectsContractForwarding`
  - `TestCreateBucket_FailureDoesNotCreateBucket`

- [ ] **Step 1: Write the failing tests**

```go
func TestCreateBucket_EVMDispatchSuccess(t *testing.T) {
	// build EthSetup app + context
	// prepare caller, payment address, primary SP, and bucket prerequisites
	// execute createBucket through EvmKeeper.CallEVMWithData
	// assert bucket exists and owner/creator == caller
}

func TestCreateBucket_RejectsContractForwarding(t *testing.T) {
	// direct-call Contract.CreateBucket with Origin != Caller()
	// assert "only allow EOA can call this method"
}

func TestCreateBucket_FailureDoesNotCreateBucket(t *testing.T) {
	// execute a createBucket call with deterministic invalid precondition
	// assert call fails and bucket lookup returns not found
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `go test ./x/evm/precompiles/storage -run 'TestCreateBucket_' -count=1`
Expected: FAIL because the new tests do not exist yet

- [ ] **Step 3: Implement the minimal tests**

```go
func mustPackCreateBucketInput(t *testing.T, args CreateBucketArgs) []byte {
	method := GetAbiMethod(CreateBucketMethodName)
	packedArgs, err := method.Inputs.Pack(
		args.BucketName,
		args.Visibility,
		args.PaymentAddress,
		args.PrimarySpAddress,
		args.PrimarySpApproval,
		args.ChargedReadQuota,
	)
	require.NoError(t, err)
	return append(append([]byte{}, method.ID...), packedArgs...)
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `go test ./x/evm/precompiles/storage -run 'TestCancelUpdateObjectContent_ABI_And_Args|TestCreateBucket_' -count=1`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add x/evm/precompiles/storage/tx_evm_apply_test.go
git commit -m "test(evm): add storage precompile baseline"
```

---

### Task 4: Verify the Baseline Matrix and Sync Planning Docs

**Files:**
- Modify: `tasks/precompile/moca-precompile-cosmos-evm-native-mode-plan.md`
- Modify: `tasks/precompile/moca-precompile-cosmos-evm-native-mode-issues.md`
- Modify: `tasks/precompile/moca-precompile-test-baseline-plan.md`

**Interfaces:**
- Consumes:
  - new test names from Tasks 1-3
- Produces:
  - updated acceptance checklist for subtask 0
  - recorded verification commands and outcomes

- [ ] **Step 1: Record the executed matrix**

```text
bank:
- RejectValue
- EOA-only rejection
- EVM dispatch success
- failure does not change balances

storageprovider:
- EVM dispatch success
- EOA-only rejection
- failure does not mutate SP price state

storage:
- EVM dispatch success
- EOA-only rejection
- failure does not create bucket
```

- [ ] **Step 2: Run the targeted package tests**

Run: `go test ./x/evm/precompiles/bank ./x/evm/precompiles/storageprovider ./x/evm/precompiles/storage -count=1`
Expected: PASS

- [ ] **Step 3: Run the wider precompile package sweep**

Run: `go test ./x/evm/precompiles/... -count=1`
Expected: PASS

- [ ] **Step 4: Sync the parent plan docs**

```text
- Mark subtask 0 progress in the issues doc.
- If any test had to narrow scope because of fixture complexity, record the exact reason.
- Do not mark subtask 0 complete unless all three packages pass targeted tests.
```

- [ ] **Step 5: Commit**

```bash
git add tasks/precompile/moca-precompile-cosmos-evm-native-mode-plan.md tasks/precompile/moca-precompile-cosmos-evm-native-mode-issues.md tasks/precompile/moca-precompile-test-baseline-plan.md
git commit -m "docs(precompile): record baseline test execution plan"
```

## Non-Goals

- 不在这个计划里迁移 `gov`、`staking`、`distribution` 等其余 precompile。
- 不在这个计划里实现“合约转调成功”。
- 不在这个计划里引入 `cosmos/evm` 原生 `Precompile` 基座。
- 不在这个计划里修改 `x/storage/keeper/evm.go`。

## Exit Criteria

- `bank`、`storageprovider`、`storage` 三个模块都有迁移前基线测试。
- 至少三条测试真实经过 `EvmKeeper.CallEVMWithData`。
- 至少三条测试固定现有 `EOA-only` 历史行为。
- 至少两条测试断言失败路径不会产生状态污染。
- `go test ./x/evm/precompiles/... -count=1` 可通过。

## Open Risks

- `storage.createBucket` 的 fixture 可能比 `storageprovider.updateSPPrice` 更重，如果准备 SP / approval 前置条件成本过高，可以改选另一个确定性更强的 storage 写方法，但必须仍然属于交易型路径。
- `bank.send` 的 EVM dispatch 测试要同时断言 Cosmos bank 状态；如果未来还需要比对 `StateDB` 内存余额，应把那部分放到下一阶段 `bank` 原生运行时迁移任务里，不在本计划强行扩大范围。
- 若 `PrecompileTestSuite` 命名或结构阻碍测试聚焦，可以在执行时顺手重命名测试 suite，但不要顺手抽公共 test framework。

## Related

- [[Moca 预编译合约切换到 Cosmos EVM 原生模式计划]]
- [[Moca 预编译合约切换到 Cosmos EVM 原生模式子任务拆分]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
