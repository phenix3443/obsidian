---
title: "Moca Mainnet RPC / AppHash 问题本地复现计划"
aliases:
  - moca-mainnet-rpc-apphash-repro-plan
tags:
  - mocachain
  - task
  - mainnet-ops
  - zh
  - mainnet
type: "task-note"
status: "archived"
area: "tasks"
topic: "mainnet-ops"
language: "zh-CN"
source_path: "tasks/mainnet/moca-mainnet-rpc-apphash-repro-plan.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 Mainnet Ops，并补齐索引与语言导航。

## Navigation
- [[Tasks Index]]
- [[Mainnet Ops Index]]
- [[Topic Index]]
- [[Language Index]]

---

# Moca Mainnet RPC / AppHash 问题本地复现计划

## 背景

同事反馈：

- mainnet 出现过 RPC down
- 现象与此前 devnet 上的 apphash 错误相似
- 怀疑 archive 节点保留的是正确状态
- 怀疑开启频繁 pruning 的节点错误删除了 IAVL merkle tree 下的节点，导致不同节点计算出不同 app hash

当前已知补充信息：

- 线上主链版本：`1.2.1`
- 怀疑触发条件之一：`authz` 消息 + `gov vote`
- 同事口径里提到：
  - archival 节点会产生一个 hash
  - `pruning = 1000/10` 一类配置的节点会产生另一个 hash
  - 两边都能被同类交易序列触发

这类问题的风险很高，因为一旦不同节点对同一高度计算出不同 app hash，轻则 RPC 异常或节点停机，重则直接形成共识分叉。

## 当前目标

本轮工作目标不是先修复代码，而是先把问题最小化、可重复化：

1. 明确问题是否能在本地 `v1.2.1` 代码上重现
2. 明确最小触发条件是否真的是 `authz + gov vote`
3. 明确差异是否与 pruning 策略有关，而不是其他环境因素
4. 产出一条可复用的复现路径，方便后续定位到 `moca-iavl` / `moca-cosmos-sdk` / `moca` 哪一层

## 当前判断

基于现有仓库线索，当前最值得优先验证的假设是：

`v1.2.1` 在执行特定交易序列时，会让 archive 节点与 pruned 节点对同一状态树产生不同结果；差异大概率发生在 IAVL pruning 与 orphan/root 重写逻辑交界处。

支撑这一判断的本地证据：

- `moca` 仓库自带 [`deployment/localup/join.js`](/private/tmp/moca-repro-v121/deployment/localup/join.js:1) 一条接近现成的触发路径
- 这条路径正好在做：
  - `authz grant`
  - `gov submitProposal`
  - `gov vote`
  - proposal 执行后的 validator join
- `moca-iavl` 当前 pruning 删除逻辑里，`deleteVersion`、`traverseOrphans`、root key 重写分支都比较复杂，符合“archive 正常、pruned 分叉”的故障形态

## 非目标

当前这轮不做下面几件事：

- 不直接修改 main 分支源码
- 不先下结论说 root cause 一定在 `moca-iavl`
- 不先做 mainnet 恢复方案
- 不把本地构建环境问题误判成业务 bug

## 复现策略

### Phase 1：固定代码与运行环境

目标：

- 使用 `moca v1.2.1`
- 避免污染本地 `main`
- 固定 Go toolchain，避免把编译器兼容性问题混进业务问题

执行方式：

1. 从 `moca` 主仓库为 `v1.2.1` 建独立 worktree
2. 强制使用 `GOTOOLCHAIN=go1.23.11`
3. 单独构建 `mocad`
4. 验证二进制版本输出，确保确实在 `v1.2.1`

说明：

- 已观察到 `v1.2.1` 在本机默认 `go1.26.3` 下会卡在 `bytedance/sonic` 兼容性问题
- 这属于环境差异，不应当作为业务复现结论的一部分

### Phase 2：最小本地链启动

目标：

- 用最小节点数先复现“同交易序列，不同 pruning 策略”
- 不先把变量扩展到完整多 validator 网络

优先方案：

1. 先用相同 genesis 启动两套本地链：
   - 一套 `pruning = nothing`
   - 一套 `pruning = custom / keep-recent=1000 / interval=10`
2. 对两套链发送完全相同的交易序列
3. 在关键高度比较：
   - block hash
   - app hash
   - proposal 执行结果
   - RPC 是否出现 panic / unavailable / stuck

如果单节点对照不足以触发，再升级为：

1. 两节点或多节点本地网络
2. 至少 1 个 archive 节点 + 1 个 pruned 节点
3. 复用 `deployment/localup` 现有初始化逻辑，但手工覆盖 pruning 配置

### Phase 3：交易触发序列

初始触发序列按同事口径与仓库脚本优先走下面组合：

1. `authz grant`
2. `gov submitProposal`
3. `gov vote`
4. 等待 proposal 执行
5. 比较 archive 与 pruned 节点的状态结果

首选复用资产：

- `deployment/localup/join.js`
- `deployment/localup/localup.sh`

如果 `join.js` 不能直接复用，则退回 CLI 交易序列，避免被 EVM wrapper 干扰。

### Phase 4：采证

每次复现都必须留下面向 root cause 的证据，而不只是“成功/失败”：

- 节点启动参数
- pruning 配置
- 发送的交易内容与 tx hash
- 触发前后区块高度
- 每个节点的 app hash
- RPC 错误、panic、stack trace
- proposal 状态
- 是否出现节点停机、卡高度、无法查询

## 完成标准

本轮“复现完成”的标准不是修好，而是满足下面任一条：

1. 成功在本地稳定打出 archive / pruned 节点 app hash 不一致
2. 成功在本地稳定打出 RPC down / panic，并能与 `authz + gov vote` 序列关联
3. 成功排除当前假设，并拿到反证说明问题不在 pruning 差异，而在别的层

## 当前阻塞与注意事项

### 已知环境注意项

- `moca v1.2.1` 需要 `GOTOOLCHAIN=go1.23.11`
- 本机 `main` 分支不应直接用于复现 `1.2.1` 事故
- 复现期间不要改动用户刚清理好的 `moca` 主工作区

### 当前主要技术风险

- `deployment/localup` 默认把 validator 统一改成 `pruning = "nothing"`，这与线上问题场景相反，需要手工覆盖
- `join.js` 当前默认目标是“validator join 提案”，可能不是唯一触发器，但它是现成的最短路径
- 如果问题依赖多节点同步与异步 pruning 时序，单节点链可能只能做第一轮筛查

## 下一步执行顺序

1. 在独立 worktree 里产出可运行的 `v1.2.1` `mocad`
2. 用 `localup` 起最小网络，并拆出 archive / pruned 配置差异
3. 跑 `authz + gov vote` 交易序列
4. 记录 app hash / RPC 行为
5. 根据结果决定是继续缩小到 IAVL，还是回头扩展到多节点时序问题

## 状态

- 文档状态：`updated with local findings`
- 代码复现状态：`trigger sequence executed, apphash divergence not reproduced`
- 修复状态：`not started`

## 本地复现结果

执行环境：

- 复现 worktree：`/Users/liushangliang/github/mocachain/moca/.worktrees/repro-v121`
- 目标版本：`v1.2.1`
- commit：`b2108770af48f4749b10aba0f43555b43518db0b`
- 构建入口：`GOTOOLCHAIN=go1.23.11 make -B build`

已确认的链状态结果：

- 成功执行 `authz grant`、`gov submitProposal`、`gov vote` 触发序列
- 未复现 archive / pruned 节点 app hash 分叉
- 触发后两节点可达到同高同 app hash
- 示例：height `1726` 时 validator0 / validator1 app hash 均为 `7C3D5263C75C2B7F377EB158831E282223C6451E27C474BAB84DBF47F569AA6D`

仍未排除：

- mainnet 上同事反馈的真实事故仍可能是 pruning / IAVL 相关问题
- 当前本地 `authz + gov vote` 序列没有复现 apphash 分叉，只能说明这条最小路径在当前本机设置下不足以触发
- 如果继续追主链事故，需要拿到线上异常高度、tx hash、节点 pruning 配置和对应日志，再按同高度状态差异继续缩小

## IAVL Export Silent Truncation 复现确认

同事提供的复现分支：

- `https://github.com/puneet2019/iavl/compare/master...puneet2019:iavl:repro/export-silent-truncation`
- 本地 fetch 后分支：`puneet-repro-export-silent-truncation`
- 复现测试：`TestExportSilentlyTruncatesOnUnreadableNode`

在本地旧 `moca-iavl/main` 上确认：

- 本地提交：`63af211`
- 测试 worktree：`/Users/liushangliang/github/mocachain/moca-iavl/.worktrees/repro-export-silent-truncation`
- 命令：`GOTOOLCHAIN=go1.23.11 go test . -run TestExportSilentlyTruncatesOnUnreadableNode -count=1 -v`
- 结果：复现成立
- 证据：完整 export 基线为 `15` 个节点；删除部分底层 node DB key 后，`Export()` 只导出 `0/3/7/10` 个节点，但 drain 到 `ErrorExportDone`，未返回真实读取错误
- 统计：`14/24` 个 DB key 删除场景触发 silent truncation

在 `moca-iavl origin/main` 上确认：

- 测试提交：`6d5db37`
- 测试 worktree：`/Users/liushangliang/github/mocachain/moca-iavl/.worktrees/repro-export-silent-truncation-origin`
- 同一个复现测试不再观察到 silent truncation
- 删除底层 node DB key 后，`Exporter.Next()` 返回类似 `Value missing for key ... corresponding to nodeKey ...` 的明确错误
- 因为复现测试原本期待“至少一次 silent truncation”，所以在 `origin/main` 上以失败形式证明该 bug 已被修复

相关修复提交：

- `5430a18 fix(node): propagate GetNode errors out of traverseInRange`
- `e142097 fix(node): keep IterateRange/IterateRangeInclusive signatures stable`
- `d7e8c12 Merge pull request #31 from puneet2019/fix/traverseInRange-propagate-errors`

当前判断：

- 同事提供的 repro 确实能证明旧 IAVL 存在 `Export()` silent truncation
- `origin/main` 的 patch series 对这个具体 repro 有效
- 这个 repro 证明的是“底层 node 缺失后 export 可以静默截断”，但还没有证明“底层 node 为什么会缺失”
- 真正的 origin 仍需继续追 pruning / orphan / root key 删除路径，尤其是能否从正常链运行中制造出同类缺失 node

## Related
- [[Mainnet Ops Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
