---
title: "`sg-sp0` 无法完成退出的真实根因：secondary GVG 未被退出计划纳入"
aliases:
  - moca-empty-family-exit-bug-zh
tags:
  - mocachain
  - task
  - sp-exit
  - zh
  - storage-provider
type: "task-note"
status: "archived"
area: "tasks"
topic: "sp-exit"
language: "zh-CN"
source_path: "tasks/sp-exit/moca-empty-family-exit-bug-zh.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 SP Exit，并补齐索引与语言导航。

## Navigation
- [[Tasks Index]]
- [[SP Exit Index]]
- [[Topic Index]]
- [[Language Index]]
- [[moca-empty-family-exit-bug|moca-empty-family-exit-bug]]

---

# `sg-sp0` 无法完成退出的真实根因：secondary GVG 未被退出计划纳入

## 1. 结论先行

`sg-sp0` 当前无法完成 `completeSpExit`，已经确认不是因为：

- `spExitScheduler` 没启动
- empty family 直接阻塞了链上退出
- `PrimaryCount` 没清零

真正的直接阻塞原因是：

- 链上 `GVGStatisticsWithinSP` 显示 `SecondaryCount = 7`
- `StorageProviderExitable` 因为 `SecondaryCount != 0` 拒绝退出

而更深一层的根因是：

- `moca-storage-provider` 生成 SP exit 计划时，primary family 来自链上查询
- 但 secondary GVG 列表来自本地 metadata DB 查询
- `sg-sp0` 本地 metadata DB 没有把这 7 个 secondary GVG 查出来
- 导致退出调度根本没有为这 7 个 secondary GVG 生成 swap-out 计划

因此，当前问题的正确定性应是：

- **`moca-storage-provider` 的 secondary GVG 发现/退出计划生成问题**

而不是：

- **`moca` 链上把 empty family 当作 primary 阻塞条件**

---

## 2. 已确认事实

### 2.1 `completeSpExit` 已经真实执行过

2026-04-22 在 `sg-sp0` 上实际执行了：

```bash
docker exec moca-sp0 moca-sp completeSpExit --config /app/config.toml
```

返回结果说明：

- 交易已经发出
- tx hash:
  - `0x080a0cb9ec9115f4c5e56c10aff4e440c279434fa86e7abba54147b75716d315`
- receipt `Status = 0`

这意味着：

- 不是“根本没执行 finalize”
- 而是“执行了，但链上拒绝了”

### 2.2 `sg-sp0` 当前链上统计值

通过 gRPC 查询：

- `moca.virtualgroup.Query/GVGStatistics`
- `sp_id = 1`

返回：

- `PrimaryCount = 0`
- `SecondaryCount = 7`

这说明：

- `sg-sp0` 已经没有 primary GVG
- 但仍然保留 7 个 secondary GVG 关系

### 2.3 empty family 仍然存在，但不是直接阻塞条件

链上仍能查到：

- `family_id = 4`
- `primary_sp_id = 1`
- `global_virtual_groups = []`

这说明：

- `sg-sp0` 还挂着一个 empty family

但它不是当前 `completeSpExit` 失败的直接原因，因为：

- 当前 `PrimaryCount = 0`
- 真正直接阻塞退出的是 `SecondaryCount = 7`

---

## 3. 当前到底是哪一种情况

下面三种可能现在已经可以明确判断：

1. `completeSpExit` 还没被真正执行
   结论：排除

2. `completeSpExit` 执行了，但因为统计值没清零被拒绝
   结论：确认

3. `completeSpExit` 执行了，但被别的前置条件拦住
   结论：当前证据不支持作为主因

更精确地说：

- 被拒绝的统计项不是 `PrimaryCount`
- 而是 `SecondaryCount`

---

## 4. 这 7 个 secondary GVG 是哪些

通过链上全量查询，`secondary_sp_ids` 中包含 `1` 的 GVG 一共 7 个，分别是：

- `gvg_id = 18`, `family_id = 18`, `primary_sp_id = 2`, `secondary_sp_ids = [1, 3]`
- `gvg_id = 19`, `family_id = 19`, `primary_sp_id = 2`, `secondary_sp_ids = [1, 3]`
- `gvg_id = 20`, `family_id = 20`, `primary_sp_id = 2`, `secondary_sp_ids = [1, 3]`
- `gvg_id = 21`, `family_id = 21`, `primary_sp_id = 2`, `secondary_sp_ids = [1, 3]`
- `gvg_id = 22`, `family_id = 22`, `primary_sp_id = 2`, `secondary_sp_ids = [1, 3]`
- `gvg_id = 23`, `family_id = 23`, `primary_sp_id = 2`, `secondary_sp_ids = [1, 3]`
- `gvg_id = 24`, `family_id = 24`, `primary_sp_id = 2`, `secondary_sp_ids = [1, 3]`

这和链上统计完全一致：

- `SecondaryCount = 7`

---

## 5. 为什么退出调度没有处理这 7 个 secondary GVG

关键问题在 `moca-storage-provider` 的退出计划生成逻辑。

### 5.1 primary family 的来源

`produceSwapOutPlan` 先通过链上共识查询本 SP 持有的 family：

- [sp_exit_scheduler.go](/Users/liushangliang/github/mocachain/moca-storage-provider/modular/manager/sp_exit_scheduler.go#L428)

这里调用的是：

- `Consensus().ListVirtualGroupFamilies(...)`

也就是说：

- primary family 走的是链上真实数据

### 5.2 secondary GVG 的来源

同一个 `produceSwapOutPlan` 之后会查询当前 SP 作为 secondary 参与的 GVG：

- [sp_exit_scheduler.go](/Users/liushangliang/github/mocachain/moca-storage-provider/modular/manager/sp_exit_scheduler.go#L446)

这里调用的是：

- `GfSpClient().ListGlobalVirtualGroupsBySecondarySP(...)`

但这个接口并不是查链上，而是查本地 metadata：

- [metadata_sp_exit_service.go](/Users/liushangliang/github/mocachain/moca-storage-provider/modular/metadata/metadata_sp_exit_service.go#L389)

继续往下看，它最终访问的是本地 BsDB：

- [global_virtual_group.go](/Users/liushangliang/github/mocachain/moca-storage-provider/store/bsdb/global_virtual_group.go#L69)

SQL 是：

- `select * from global_virtual_groups where FIND_IN_SET('<sp_id>', secondary_sp_ids) > 0 and removed = false`

### 5.3 `sg-sp0` 本地 metadata DB 的实际结果

我们已经实查了 `sg-sp0` 本地 metadata DB：

- `query-gvg-by-sp --targetSP 1` 返回 `null`
- 直接查 `sp_0.global_virtual_groups` 表，`secondary_sp_ids` 包含 `1` 的记录也是空

这说明：

- `sg-sp0` 本地 metadata DB 没有把链上这 7 个 secondary GVG 索引出来

于是 `produceSwapOutPlan` 在 secondary 这一段看到的是：

- `secondaryGVGList = []`

进一步导致：

- 不会为这 7 个 GVG 生成 secondary swap-out tx
- 不会把它们纳入退出计划
- 最终 `completeSpExit` 时仍然保留 `SecondaryCount = 7`

---

## 6. 为什么 empty family 看起来像问题，但其实不是主因

`family 4` 仍然残留，确实是一个异常现象，但它和当前 finalize 失败不是同一层问题。

当前真实状态是：

- `family 4` 为空
- `PrimaryCount = 0`
- `SecondaryCount = 7`

所以：

- empty family 只是退出流程没有完全收敛的副现象
- 当前真正把 `completeSpExit` 拦住的是 secondary GVG 没清掉

如果只盯着 family 4，会把修复方向带偏。

---

## 7. 为什么这是 `moca-storage-provider` 的问题

链上退出校验本身没有异常：

- 只要 `SecondaryCount != 0`
- `StorageProviderExitable` 就应该拒绝退出

相关代码：

- [keeper.go](/Users/liushangliang/github/mocachain/moca/x/virtualgroup/keeper/keeper.go#L468)
- [msg_server.go](/Users/liushangliang/github/mocachain/moca/x/virtualgroup/keeper/msg_server.go#L464)

当前链上行为是正确反映真实状态的：

- `sg-sp0` 还有 7 个 secondary GVG
- 所以不能退出

真正出问题的是：

- `moca-storage-provider` 没有把这 7 个 secondary GVG 纳入退出计划

因此当前主问题不应继续定性为：

- `moca` 链上退出语义问题

而应定性为：

- `moca-storage-provider` secondary GVG 发现逻辑不可靠，导致 SP exit 计划不完整

---

## 8. 推荐修复方向

推荐优先修 `moca-storage-provider`。

### 方案 A：退出计划生成时不依赖本地 metadata DB 查询 secondary GVG

这是当前最推荐的方向。

思路是：

- 退出计划生成时，secondary GVG 列表不应以本地 BsDB 为唯一数据源
- 应改为使用链上可验证的数据源来发现“当前 SP 仍然作为 secondary 参与的 GVG”

优点：

- 和退出的最终判定口径一致
- 不会因为本地索引缺失而漏掉 secondary GVG

### 方案 B：保留本地 metadata 路径，但必须保证 secondary GVG 能完整同步

这条路也能修，但可靠性更差。

因为当前已经看到：

- 链上统计是对的
- 本地 metadata 是空的

只要本地索引链路还可能滞后或漏数据，退出计划就仍然可能漏掉 secondary GVG。

因此从退出安全性角度，不建议继续把本地 BsDB 作为 secondary 退出计划的唯一事实来源。

---

## 9. 建议修改位置

重点看这里：

- [sp_exit_scheduler.go](/Users/liushangliang/github/mocachain/moca-storage-provider/modular/manager/sp_exit_scheduler.go#L446)
- [metadata_sp_exit_service.go](/Users/liushangliang/github/mocachain/moca-storage-provider/modular/metadata/metadata_sp_exit_service.go#L389)
- [global_virtual_group.go](/Users/liushangliang/github/mocachain/moca-storage-provider/store/bsdb/global_virtual_group.go#L69)

尤其是：

- `produceSwapOutPlan`
- `GfSpListGlobalVirtualGroupsBySecondarySP`
- `ListGvgBySecondarySpID`

---

## 10. 修复后验证方式

至少要验证下面几条：

1. 对一个 exiting SP，如果链上仍有 secondary GVG，退出计划能把它们全部列出来
2. secondary swap-out 会被真实发起，而不是只处理 primary family
3. 当所有 secondary GVG 清空后，链上 `SecondaryCount` 变为 `0`
4. 此后再执行 `completeSpExit`，交易成功

对 `sg-sp0` 当前案例，修复后应看到：

- `query.sp.exit` 中出现 secondary 相关 swap-out 计划
- 或至少对应的 secondary swap-out tx 被真实发起
- `GVGStatisticsWithinSP` 从 `SecondaryCount = 7` 下降到 `0`
- `completeSpExit` 成功

---

## 11. `moca-e2e` 需要补的场景

当前 `mocachain/moca-e2e#25` 没测到这个问题，是因为它验证的是：

- scheduler 是否成功启动
- `query.sp.exit` 是否不再报 `spExitScheduler not exit`

它没有验证：

- secondary GVG 是否被完整纳入退出计划
- `completeSpExit` 是否真正成功
- 链上 `SecondaryCount` 是否归零

因此 `moca-e2e` 需要补一条新场景：

- 构造一个 SP 作为 secondary 挂在若干 GVG 上
- 对该 SP 发起 graceful exit
- 验证退出计划中包含这些 secondary GVG
- 最终验证 `SecondaryCount` 清零且 `completeSpExit` 成功

---

## 12. 最终结论

`sg-sp0` 当前无法最终退出，已经可以明确归因到这条链路：

1. `completeSpExit` 已实际执行
2. 链上拒绝退出
3. 链上 `PrimaryCount = 0`，`SecondaryCount = 7`
4. 这 7 个 secondary GVG 是链上真实存在的 `gvg_id 18..24`
5. `moca-storage-provider` 退出计划生成 secondary GVG 时依赖本地 metadata DB
6. `sg-sp0` 本地 metadata DB 没有这些 secondary GVG
7. 所以 secondary swap-out 根本没被纳入退出计划
8. 最终 `SecondaryCount` 无法清零，`completeSpExit` 被链上拒绝

因此当前正确修复方向是：

- **修 `moca-storage-provider` 的 secondary GVG 退出计划生成逻辑**

而不是：

- **继续围绕 empty family 做链上语义修复**

## Related
- [[SP Exit Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
- [[moca-empty-family-exit-bug|moca-empty-family-exit-bug]]
