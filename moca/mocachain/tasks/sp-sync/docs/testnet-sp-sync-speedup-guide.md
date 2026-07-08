---
title: "Testnet SP 同步加速指南"
aliases:
  - testnet-sp-sync-speedup-guide
tags:
  - mocachain
  - task
  - sp-sync
  - zh
  - sp-sync
  - storage-provider
type: "task-note"
status: "archived"
area: "tasks"
topic: "sp-sync"
language: "zh-CN"
source_path: "tasks/sp-sync/docs/testnet-sp-sync-speedup-guide.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 SP Sync，并补齐索引与语言导航。

> [!info]
> 长期有效的 SP 生命周期知识已沉淀到 [[core/SP Lifecycle|SP Lifecycle]]。当前页保留本次 testnet 同步加速的现场结论与参数建议。

## Navigation
- [[Tasks Index]]
- [[SP Sync Index]]
- [[Topic Index]]
- [[Language Index]]
- [[core/SP Lifecycle|SP Lifecycle]]

---

# Testnet SP 同步加速指南

## 目标

本文档总结如何加快 `moca-storage-provider` 在 testnet 上的同步速度，原则是优先通过配置和部署方式提速，只有当配置手段已经做到位仍不满足要求时，才把代码修改作为进一步的备选方案。

适用范围：

- `test-sp0`
- `test-sp1`
- `test-sp2`
- `test-sp3`
- `test-sp4`
- `test-sp5`

## 先看结论

如果目标是尽快把 SP 从落后很多的高度追上来，优先级建议如下：

1. 先确保链访问入口稳定可达，否则任何配置调优都没有意义。
2. 如果节点已经严重落后，优先用数据库快照或已有高位数据预热，而不是纯靠从低高度慢慢追。
3. 在链访问稳定后，优先通过配置逐步提高 block sync 并发和写库批量。
4. 优先通过配置关闭或减少非必要落库，降低额外 RPC 和 DB 压力。
5. 只有当以上配置手段都已经做到位，仍然无法满足目标时，再考虑代码修改。

## 这次现场确认的首要瓶颈

本次 testnet 上最明显的同步瓶颈不是 CPU，也不是 `moca-sp` 进程内存泄漏，而是链访问质量。

现场现象：

- `test-sp0` 到 `test-sp4` 之前访问公开 `testnet-rpc.mocachain.org` / `testnet-lcd.mocachain.org` 会遇到 `403 Forbidden`
- 保留 `https://...:443` 时还会遇到证书链校验问题
- 改成不带端口的 `http://域名` 后，程序内部还会报 `missing port in address`

因此本次已验证可用的稳定基线是：

- `/etc/hosts`
  - `54.38.38.12 testnet-rpc.mocachain.org`
  - `54.38.38.12 testnet-lcd.mocachain.org`
- `config.toml`
  - `ChainAddress = ['http://testnet-lcd.mocachain.org:80']`
  - `RpcAddress = ['http://testnet-rpc.mocachain.org:80']`

结论：

- 如果 RPC/LCD 不稳定，SP 会频繁卡在重试、报错和空转上
- 这种情况下即使把并发调高，也只是更快地失败，不会真正加速同步

## 基于当前各 SP 状态的执行方案

这篇文档不应该只停留在通用建议，而应该基于当前 6 台 SP 的实际状态来制定方案。

当前已知状态：

- `test-sp0` 到 `test-sp4`
  - `epoch.block_height` 大致在 `2.17M` 到 `2.20M`
  - 当前容器均为 `running / healthy`
  - 链访问入口已经统一修复为稳定配置
- `test-sp5`
  - `epoch.block_height` 约 `1.99M`
  - 明显落后于 `sp0-sp4`
  - `bucket_migrate_gc_progress = 20504`，迁移进度存在异常值
  - 当前容器虽然也是 `running / healthy`，但不适合作为并发调优的优先试点

这意味着当前最合适的方案不是“6 台一起调”，而是按两组处理：

### 方案 A：`sp0-sp4` 作为主调优组

这 5 台机器目前处于同一个状态层级：

- 链入口问题已经修复
- 容器健康
- 主同步高度接近
- 没有像 `sp5` 那样明显的迁移异常值

因此建议：

1. 从 `sp0-sp4` 中选 1 台做配置调优金丝雀
2. 验证有效后，再复制到其余 4 台

当前更推荐把 `test-sp3` 或 `test-sp0` 作为金丝雀：

- `test-sp3`：当前高度在这组里最高，更适合观察增速变化
- `test-sp0`：排障过程中验证最充分，运维路径更熟

### 方案 B：`sp5` 单独处理

`test-sp5` 不建议现在就直接跟着 `sp0-sp4` 一起上调并发。

原因：

- 它当前明显更落后
- 迁移进度里有异常值
- 这种情况下，即使调高并发，也更容易放大历史 backlog 和数据一致性风险

因此对 `sp5` 的建议顺序是：

1. 继续保持当前稳定链入口不回退
2. 优先考虑从 `sp0-sp4` 中选择一个更高高度的源做 `BsDB` 快照预热
3. 让 `sp5` 先追到和 `sp0-sp4` 接近的高度段
4. 再决定是否应用与 `sp0-sp4` 相同的并发调优参数

## 配置优先的提速原则

先明确一个原则：

- 对当前 testnet SP，同步慢的首选处理方式应是改配置，而不是先改代码
- 因为本次现场已证明，最大瓶颈首先出现在链访问入口、历史 backlog 和数据库写入路径
- 这些问题通过配置和运维手段就能显著改善，而且风险远低于改代码重发版

因此建议顺序是：

1. 先修稳定链入口
2. 再做数据预热和配置调优
3. 最后才考虑代码级优化

## 优先通过配置调整的提速手段

### 1. 稳定链访问入口

这是收益最高的一步，也是所有后续调优的前提。

建议基线：

- `/etc/hosts`
  - `54.38.38.12 testnet-rpc.mocachain.org`
  - `54.38.38.12 testnet-lcd.mocachain.org`
- `config.toml`
  - `ChainAddress = ['http://testnet-lcd.mocachain.org:80']`
  - `RpcAddress = ['http://testnet-rpc.mocachain.org:80']`

验证方式：

- `mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh check-chain-access --since 30m`
- `mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh verify --since 30m`

验收标准：

- 没有 `403 Forbidden`
- 没有 `certificate signed by unknown authority`
- 没有 `missing port in address`

### 2. 对严重落后节点先做数据预热

如果某个 SP 比链上落后数千万高度，纯靠在线追块会非常慢，此时应优先通过数据预热提速。

建议动作：

1. 选择一个高度更高、数据更完整的 SP 作为源
2. 导出其 `BsDB` 快照
3. 在落后节点恢复快照后，再继续在线追块

这一步本质上也是“配置和运维优先”的一部分，因为它直接减少了需要从 RPC 回放的历史高度。

### 3. 优先通过配置调并发和批量

在链访问和数据库都健康后，再考虑逐步调高这些配置参数。

## 可通过配置直接调优的关键参数

### 1. `BlockSyncer.Workers`

代码位置：

- `modular/blocksyncer/blocksyncer_options.go`

作用：

- `cfg.BlockSyncer.Workers` 会映射到 Juno parser 的 `Parser.Workers`
- `quickFetchBlockData()` 也会直接用这个值决定每一轮预抓取的区间大小

影响：

- 值越大，同时预抓取和处理的区块越多
- RPC 请求数、内存占用、数据库写入压力也会一起上升

建议：

- 在链访问已经稳定后再调
- 不要一次拉很大，建议小步上调并观察：
  - RPC 延迟
  - MySQL CPU / IOPS
  - `moca-sp` 健康状态
  - `epoch.block_height` 增长速度

### 2. `BlockSyncer.CommitNumber`

代码位置：

- `modular/blocksyncer/blocksyncer_options.go`
- `modular/blocksyncer/blocksyncer_indexer.go`

作用：

- `CommitNumber` 控制一次事务里拼接并提交多少组 SQL
- 代码会按 `CommitNumber` 将区块内生成的 SQL 分批提交

影响：

- 值太小：事务提交过于频繁，写库开销大
- 值太大：单次事务过重，可能增加锁等待、回滚成本和长事务风险

建议：

- 这是一个适合逐步上调的参数
- 调整时优先观察 MySQL 的提交延迟和锁等待，不要只看 `moca-sp` CPU

### 3. `parser.ConcurrentSync`

代码位置：

- `modular/blocksyncer/blocksyncer_options.go`

作用：

- worker 启动时会使用 `config.Cfg.Parser.ConcurrentSync`
- 这会影响 parser 处理区块时的内部并发行为

建议：

- 如果当前配置链路已经稳定、数据库还有余量，可以与 `Workers` 一起小步上调
- 如果数据库已经是瓶颈，不建议继续提高

### 4. `BlockSyncer.ChainDataStorage.EnableStorage`

代码位置：

- `modular/blocksyncer/blocksyncer_options.go`
- `modular/blocksyncer/blocksyncer_indexer.go`

作用：

- 开启后，block result 会额外保存到数据库
- 这会增加额外的 DB 写入和一定的 RPC 处理成本

建议：

- 如果当前目标只是尽快追平同步高度，而不是保留全部 block result 查询能力，可以评估关闭
- 如果后续业务确实依赖这部分数据，再单独补采或重新打开

### 5. `BlockSyncer.BsDBWriteAddress`

代码位置：

- `modular/blocksyncer/blocksyncer_options.go`

作用：

- 如果设置，会覆盖默认 `BsDB.Address`
- 这意味着 block sync 的写库地址可以单独指定

建议：

- 如果当前写库走远端、跨地域或高延迟链路，优先改成低延迟写入路径
- 如果本地 MySQL 已经够用，不建议为了“架构好看”把写库拆远，通常只会更慢

## 推荐的配置提速顺序

### 优先级 1：先修链访问

这是收益最高的一步。

建议动作：

1. 固定 `testnet-rpc.mocachain.org` / `testnet-lcd.mocachain.org` 到稳定入口
2. 统一使用显式 `:80` 的 `http://` 地址
3. 用 `mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh check-chain-access` 和 `verify` 验证近期日志里没有：
   - `403 Forbidden`
   - `certificate signed by unknown authority`
   - `missing port in address`

如果这一步没做好，后面的调优都应暂缓。

### 优先级 2：对严重落后节点做数据预热

如果 SP 已经比链上落后数千万高度，纯靠在线追块会很慢。

建议动作：

1. 选择一个高度更高、数据更完整的 SP 作为源
2. 导出其 `BsDB` 快照
3. 在落后节点恢复快照后，再继续在线追块

这样做的意义：

- 直接减少需要从 RPC 重放的历史高度
- 比单纯提高 `Workers` 更有效
- 还能降低对公共 RPC 的持续压力

适用场景：

- 新节点冷启动
- 老节点长时间停机后重新追平
- 某个 SP 比其他 SP 落后明显

### 优先级 3：提高并发和批量

在链访问和数据库都健康后，再考虑以下调优：

1. 提高 `BlockSyncer.Workers`
2. 提高 `BlockSyncer.CommitNumber`
3. 如果当前配置支持，再提高 `parser.ConcurrentSync`

建议方式：

- 一次只调 1 到 2 个参数
- 每次调完至少观察一段时间
- 关注的是“实际追平速度”，不是单看 CPU 忙不忙

推荐观察指标：

- `epoch.block_height` 每分钟增长多少
- `moca-sp` 日志里是否出现更多 RPC 错误
- MySQL 是否出现明显延迟、慢查询、锁等待
- 容器是否从 `healthy` 变成频繁重启

### 优先级 4：减少非必要写入

如果当前的首要目标是追平高度，可以评估临时关闭一些非必要的额外数据存储。

优先考虑：

- `ChainDataStorage.EnableStorage`

原因：

- block result 存储会增加额外写库量
- 对历史大 backlog 节点，这类附加写入会拉低追块吞吐

### 优先级 5：把数据库和磁盘 I/O 保持在健康区间

现场经验表明，日志堆积和无效文件虽然不是主因，但会放大 I/O 压力。

已验证有效的基础动作：

- 清理历史 `moca-sp.log.*` / `logs.*`
- 保持 Docker `json-file` 日志限额
- 安装每日清理遗留文件日志的保留脚本

这类动作本身不一定直接带来巨大提速，但能避免磁盘、page cache 和 I/O 干扰同步。

## 代码修改只作为进一步备选方案

如果下面这些动作都已经做了：

- 链访问入口已经稳定
- 快照预热已经完成
- `Workers` / `CommitNumber` / `ConcurrentSync` 已经过小步调优
- 非必要落库已经关闭或收敛
- MySQL、磁盘和网络都没有明显瓶颈

但同步速度还是达不到目标，这时才建议把代码修改作为进一步备选方案。

适合再考虑代码方案的场景：

- 当前并发模型无法充分利用机器资源
- RPC 请求模式本身还有明显冗余
- SQL 拼装/提交批次的策略不够高效
- 某些模块的事件处理耗时明显偏高

代码方案的优先方向可以是：

1. 优化 `quickFetchBlockData()` 和实时追块之间的衔接逻辑
2. 优化 block/result 拉取与处理的并发模型
3. 优化 SQL 分批提交策略
4. 评估是否能进一步降低非关键数据写入成本

但需要注意：

- 代码修改会引入新的发布、回归和兼容性风险
- 对 testnet 线上 SP 来说，风险通常明显高于配置调优
- 因此应该始终把代码修改放在配置方案之后

## 当前集群的推荐执行顺序

基于当前实际状态，更推荐下面这个顺序，而不是把 6 台机器视为同质节点统一处理。

### 第 1 步：保持 `sp0-sp5` 当前稳定链入口配置不回退

当前链入口已经统一修复为：

- `/etc/hosts` 固定到 `54.38.38.12`
- `ChainAddress = ['http://testnet-lcd.mocachain.org:80']`
- `RpcAddress = ['http://testnet-rpc.mocachain.org:80']`

这一步现在不是新的优化动作，而是整个提速方案的前提条件。

### 第 2 步：先在 `sp0-sp4` 里选 1 台做配置金丝雀

建议优先：

1. `test-sp3`
2. `test-sp0`

先只在这 1 台机器上小步调整：

- `BlockSyncer.Workers`
- `BlockSyncer.CommitNumber`
- `parser.ConcurrentSync`

观察指标：

- `epoch.block_height` 增速是否明显提升
- 容器是否持续保持 `healthy`
- 日志中是否重新出现 RPC 错误
- MySQL 是否出现明显慢查询或提交延迟

### 第 3 步：如果金丝雀有效，再复制到 `sp0-sp4` 其余节点

只有当金丝雀观察期结论明确后，才建议推广到：

- `test-sp0`
- `test-sp1`
- `test-sp2`
- `test-sp4`

原因：

- 这 5 台的当前高度区间接近
- 统一复制配置更容易比较效果
- 避免把 `sp5` 这种不同状态的节点混进同一轮调优

### 第 4 步：`sp5` 优先做快照预热，而不是先调并发

`test-sp5` 当前不是最佳的配置调优目标，而是更像“需要先补课”的节点。

建议顺序：

1. 从 `sp0-sp4` 中选一个高度更高、状态更稳的源节点
2. 导出 `BsDB` 快照
3. 在 `sp5` 恢复该快照
4. 让 `sp5` 先追到与 `sp0-sp4` 接近的高度段
5. 再决定是否复制 `sp0-sp4` 的配置调优参数

### 第 5 步：最后再评估是否关闭非必要落库

如果链入口已稳定、并发参数已经调优，但数据库写入仍然明显吃紧，再评估：

- 是否关闭 `ChainDataStorage.EnableStorage`

这一步建议放在并发调优之后，因为它会影响数据保留策略，属于收益和副作用都更大的动作。

## 不推荐的做法

- 在公开 RPC 还不稳定时就一味提高 `Workers`
- 不验证日志错误，直接认为“容器 healthy 就说明同步正常”
- 节点已经严重落后时还坚持从 0 或很低高度纯在线追
- 在未确认 DB 余量前，把 `CommitNumber` 拉到很大
- 把写库地址改到更远的机器，希望“分担压力”，结果引入网络延迟

## 推荐检查命令

### 用总控脚本做检查

```bash
# 检查链访问质量
mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh check-chain-access --since 30m

# 检查资源使用和历史日志体量
mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh check-resources

# 做收尾验证
mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh verify --since 30m
```

### 用数据库确认同步推进

```sql
SELECT block_height
FROM epoch
ORDER BY block_height DESC
LIMIT 1;
```

如果持续多次查询该值都不增长，就说明当前节点不是“同步慢”，而是“同步卡住”。

## 建议落地顺序

如果现在要在 testnet 上真正提速，建议按这个顺序做：

1. 保持 `sp0-sp5` 当前稳定链入口配置不回退
2. 从 `sp0-sp4` 中选 1 台金丝雀，优先 `test-sp3` 或 `test-sp0`
3. 在这台金丝雀上小步上调 `Workers` / `CommitNumber` / `ConcurrentSync`
4. 验证有效后，再推广到 `sp0-sp4` 其余节点
5. 对 `sp5` 优先做 `BsDB` 快照预热，而不是直接调高并发
6. 等 `sp5` 追到与 `sp0-sp4` 接近的高度段后，再决定是否复制同样的调优参数
7. 只有配置手段已经用尽仍不够时，再立项做代码优化

## 总结

对当前 testnet SP 来说，影响同步速度的因素里，优先级最高的不是算力，而是链访问质量、历史 backlog 大小，以及不同节点当前所处的状态层级。

最有效的加速路径是：

1. 先保持当前稳定链入口不回退
2. 先把 `sp0-sp4` 作为一组做配置金丝雀调优
3. 把 `sp5` 单独作为快照预热对象处理
4. 再根据分组结果推广配置
5. 代码修改只作为进一步的备选方案

这样做比“6 台一起调”或直接改代码更稳，也更符合当前各节点已经明显分层的真实状态。

## Related
- [[SP Upgrade Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
