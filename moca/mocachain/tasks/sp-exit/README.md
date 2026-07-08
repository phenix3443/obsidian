---
title: "SP Exit 文档索引与脚本证据整理"
aliases:
  - README
  - `tasks/sp-exit` 文档索引与脚本证据整理
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
source_path: "tasks/sp-exit/README.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 SP Exit，并补齐索引与语言导航。

> [!info]
> 长期有效的 SP 生命周期知识已沉淀到 [[core/SP Lifecycle|SP Lifecycle]]。当前页保留具体脚本证据、历史案例和查证路径。

## Navigation
- [[Tasks Index]]
- [[SP Exit Index]]
- [[Topic Index]]
- [[Language Index]]
- [[core/SP Lifecycle|SP Lifecycle]]


# SP Exit 文档索引与脚本证据整理

---

# `tasks/sp-exit` 文档索引与脚本证据整理

## 目的

本目录同时承载了三类内容：

- SP 退出执行脚本
- 历史问题分析与现场收尾记录
- 当前剩余待退出节点的执行计划

这份索引用来回答两个问题：

1. `tasks/sp-exit` 下面每份文档分别在讲什么
2. 之前其他 SP 的退出，是否有证据表明是通过 `manual-complete-sp-exit.sh` 执行的

## 目录说明

### 脚本

- `exit-single-sp.sh`
  - 2026-04-20 引入的通用单节点退出脚本
  - 目标是把 `spExit -> 等待迁移 -> completeSpExit -> 验证移除` 串成统一流程
  - 更偏“标准流程入口”

- `manual-complete-sp-exit.sh`
  - 2026-04-23 新增的手工收尾脚本
  - 目标是处理“链上已经进入 graceful exit，但本地 scheduler 没能恢复/重建退出计划”的场景
  - 核心动作是按链上状态手工执行：
    - primary family `swapIn -> recover-vgf -> completeSwapIn`
    - secondary GVG `swapIn -> completeSwapIn`
    - 最后执行 `sp.complete.exit`

### 文档

- `sp-exit-plan.md`
  - 当前收尾计划
  - 已经更新为“只剩 `sg-sp1` / `us-sp1` 待退出”

- `moca-empty-family-exit-bug.md`
- `moca-empty-family-exit-bug-zh.md`
  - `sg-sp0` 历史退出阻塞问题的根因分析
  - 重点结论是：真正阻塞 `completeSpExit` 的是 secondary GVG 没被纳入退出计划，而不是 empty family 本身

- `sp0-family-4-swapin-request.md`
- `sp0-family-4-swapin-request-zh.md`
  - `sg-sp0` 收尾阶段的协作文档
  - 内容是请求 `sp0` 接手 empty family `4`，之后再在 `sg-sp0` 上执行最终 `sp.complete.exit`

## 时间线

### 2026-04-20

提交：`9cf7318 feat: add storage provider operation and sync documentation`

新增：

- `exit-single-sp.sh`
- `sp-exit-plan.md`

这说明最早的退出执行入口是通用的单节点脚本，而不是 `manual-complete-sp-exit.sh`。

### 2026-04-23 18:02

提交：`a402922 update`

新增：

- `moca-empty-family-exit-bug.md`
- `moca-empty-family-exit-bug-zh.md`
- `sp0-family-4-swapin-request.md`
- `sp0-family-4-swapin-request-zh.md`

这批文档记录了 `sg-sp0` 卡住后的现场分析与后续收尾方案。

### 2026-04-23 18:47

提交：`7bcc2ac update`

新增：

- `manual-complete-sp-exit.sh`

这是第一次把“手工迁移 family / GVG 并最终执行 `sp.complete.exit`”固化成脚本。

## 关于 `manual-complete-sp-exit.sh` 的证据

## 强证据

### 证据 1：脚本头部直接声明默认参数对应一次真实操作

`manual-complete-sp-exit.sh` 自带说明：

- `Defaults match the 2026-04-23 us-sp0 -> sg-sp1 operation`

并且默认参数直接写死为：

- target SP：`us-sp0`
- `TARGET_SP_ID="4"`
- `TARGET_SSH_HOST="test-sp3"`
- `TARGET_CONTAINER="moca-sp3"`
- successor SP：`sg-sp1`
- `SUCCESSOR_SP_ID="2"`
- `SUCCESSOR_SSH_HOST="test-sp1"`
- `SUCCESSOR_CONTAINER="moca-sp1"`

这不是抽象示例，而是一次具体现场操作被固化进脚本的直接证据。

## 中强证据

### 证据 2：`us-sp0` 的现场记录与脚本逻辑完全一致

在 `tasks/sp-upgrade-v1.20-rc6/testnet-sp-storage-provider-image-upgrade-and-sp-exit-validation-plan.md` 的 `13.9 us-sp0 退出计划未自动生成的现场发现` 中，明确记录：

- `us-sp0` 已进入 `STATUS_GRACEFUL_EXITING`
- 但 `query.sp.exit` 只返回 `{"self_sp_id":4}`
- 本地 scheduler 没有恢复出退出迁移计划
- 短期操作结论是：
  - 不能等待自动退出计划自然推进
  - 需要按链上 family / GVG 状态手动执行 `swapIn` / `recover-vgf` / `completeSwapIn`
  - 等 `primary_count=0` 和 `secondary_count=0` 后，再执行 `sp.complete.exit`

这和 `manual-complete-sp-exit.sh` 的完整逻辑一一对应，说明这个脚本就是把 `us-sp0` 这次手工收尾流程沉淀成源码。

## 反证 / 限定证据

### 证据 3：`us-sp2` 不是“靠这个脚本成功退出”的例子

同一份验证计划在 `13.10 us-sp2 退出执行记录` 中明确写到：

- 原计划尝试复用 `tasks/sp-exit/manual-complete-sp-exit.sh`
- 但因为当前只有 `sg-sp1` / `us-sp1` 可操作，找不到合法 successor
- 所以无法继续完成手工迁移和 `completeSpExit`

这说明：

- `manual-complete-sp-exit.sh` 确实被拿来作为既有操作模板复用
- 但 `us-sp2` 不是通过这个脚本成功退出的

### 证据 4：`sg-sp0` 的收尾证据指向另一条人工路径

`sg-sp0` 相关文档显示的收尾方式是：

1. 先请求 `sp0` 接手 empty family `4`
2. 在 `sp0` 上执行：
   - `swapIn --vgf 4 --gvgId 0 --targetSP 1`
   - `completeSwapIn --vgf 4 --gvgId 0`
3. 再回到 `sg-sp0` 上执行：
   - `moca-sp --config /app/config.toml sp.complete.exit --operatorAddress ...`

这条证据链说明 `sg-sp0` 的最终收尾是单独的手工协作流程，不是仓库里明确记录成“通过 `manual-complete-sp-exit.sh` 完成”的案例。

## 当前能下的结论

### 可以确认的

- `manual-complete-sp-exit.sh` 不是最早的退出脚本；最早是 `exit-single-sp.sh`
- `manual-complete-sp-exit.sh` 是 2026-04-23 为一次真实 `us-sp0 -> sg-sp1` 手工收尾操作沉淀出来的
- `us-sp0` 是当前仓库里与该脚本绑定最强、最直接的案例
- `us-sp2` 现场明确尝试过复用这个脚本，但没有完成
- `sg-sp0` 现有证据更像是走了另一条“请求 `sp0` 接手 empty family 后再 finalize”的人工路径

### 目前还不能确认的

- `sg-sp2` 是否曾通过 `manual-complete-sp-exit.sh` 成功退出
- `us-sp0` 当天是否直接执行了脚本文件本身，还是先手工执行后再把步骤回写成脚本
- 其他已经退出的 SP 是否也使用过该脚本，但没有在仓库文档里留下持久化记录

## 证据强弱排序

1. 最强：
   - 脚本头部直接声明 `Defaults match the 2026-04-23 us-sp0 -> sg-sp1 operation`
2. 很强：
   - `13.9 us-sp0` 的现场记录与脚本逻辑完全同构
3. 中等：
   - `13.10 us-sp2` 明确写了“尝试复用该脚本，但未完成”
4. 负向证据：
   - `sg-sp0` 的收尾文档指向另一套手工流程，而不是直接指向该脚本

## 当前缺口

仓库内还缺“脚本实际执行输出”这一层硬证据，例如：

- `manual-complete-sp-exit.sh` 的终端完整输出
- 由脚本发出的每笔 `swapIn` / `completeSwapIn` / `sp.complete.exit` 交易哈希集合
- 远端主机 shell history
- 远端容器日志中能直接对应到脚本执行时间窗的操作记录

因此，如果要把“脚本确实执行过”从高概率提升到完全坐实，后续仍需要去查：

- `test-sp3` / `test-sp1` / `test-sp5` 等远端主机历史
- 容器日志
- 对应时间窗口内的链上 tx

## 建议的查证顺序

1. 先查 `us-sp0`
   - 这是与 `manual-complete-sp-exit.sh` 证据最强绑定的案例
2. 再查 `us-sp2`
   - 这里能验证“脚本是否真的被复用尝试过”
3. 最后查 `sg-sp0` / `sg-sp2`
   - 重点判断是否存在仓库外的操作痕迹

## 一句话结论

如果问题是“仓库里有没有证据表明以前其他 SP 的退出和 `manual-complete-sp-exit.sh` 有关”，答案是：

- 有，而且最强证据指向 `us-sp0 -> sg-sp1`

如果问题是“仓库里能不能直接证明多个已退出 SP 都是通过这个脚本成功退出的”，答案是：

- 目前不能
- 当前仓库证据只能强力支持 `us-sp0`，明确反证 `us-sp2` 未完成，且 `sg-sp0` 更像走了另一条人工收尾路径

## Related
- [[SP Exit Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
