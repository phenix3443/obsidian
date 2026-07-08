---
title: "Testnet Moca Storage Provider 同步高度分析"
aliases:
  - testnet-sp-sync-height-analysis
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
source_path: "tasks/sp-sync/docs/testnet-sp-sync-height-analysis.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 SP Sync，并补齐索引与语言导航。

## Navigation
- [[Tasks Index]]
- [[SP Sync Index]]
- [[Topic Index]]
- [[Language Index]]

---

# Testnet Moca Storage Provider 同步高度分析

## 分析范围
本文记录两类信息：

- 从 `moca-storage-provider` 代码出发，应该查询数据库中的哪个表、哪个字段来判断 SP 的主同步高度
- 当前 testnet 各个 SP 线上数据库中实际记录到的高度是多少

查询时间：
- 链上 RPC 查询时间：`2026-04-13T03:54:02.117100816Z`

检查目标：
- `test-sp0`
- `test-sp1`
- `test-sp2`
- `test-sp3`
- `test-sp4`
- `test-sp5`

链信息：
- `chain_id = moca_222888-1`

## 代码结论
根据 `moca-storage-provider` 代码实现，SP 主同步高度落在 MySQL 的 `epoch` 表中，字段为 `block_height`。

关键代码位置：
- `store/bsdb/const.go`
  - `EpochTableName = "epoch"`
- `store/bsdb/epoch_schema.go`
  - `Epoch.BlockHeight`
- `store/bsdb/block.go`
  - `GetLatestBlockNumber()`
- `store/bsdb/epoch.go`
  - `GetEpoch()`
- `modular/blocksyncer/blocksyncer_options.go`
  - 启动恢复同步时通过 `GetEpoch()` 读取 `epoch.BlockHeight`
- `modular/blocksyncer/blocksyncer_indexer.go`
  - 已处理高度基于 `ep.BlockHeight`

字段含义：
- `epoch.block_height`
  - SP block syncer 已经写入数据库的最新主同步高度
- `migrate_subscribe_progress.last_subscribed_block_height`
  - 迁移相关事件订阅进度，不是 SP 主同步高度

## 应该查询的 SQL
主同步高度：

```sql
SELECT block_height
FROM epoch
ORDER BY block_height DESC
LIMIT 1;
```

迁移订阅进度：

```sql
SELECT event_name, last_subscribed_block_height
FROM migrate_subscribe_progress
ORDER BY event_name;
```

链上最新高度用于对比时，需要从 RPC 查询，本次查询结果如下：

```text
chain_id=moca_222888-1
latest_block_height=18507603
latest_block_time=2026-04-13T03:54:02.117100816Z
```

注意：
- SP 数据库中没有一个单独、权威的“链上当前最新高度”字段
- 如果要比较“moca chain 最新高度”和“SP 已同步最新高度”，应使用：
  - 链上最新高度：从 RPC 获取
  - SP 已同步最新高度：从 `epoch.block_height` 获取

## 线上数据库查询结果
链上最新高度：
- `18507603`

各 SP 数据库与容器当前记录如下：

| Host | Database | `epoch.block_height` | `migrate_subscribe_progress` | 容器状态 | 与链上差值 |
|---|---:|---:|---|---|---:|
| `test-sp0` | `sp_0` | `2203186` | `bucket_migrate_gc_progress: 2203186`, `bucket_migrate_progress: 2203186` | `running / healthy` | `16304417` |
| `test-sp1` | `sp_1` | `2201696` | `bucket_migrate_gc_progress: 2201696`, `bucket_migrate_progress: 2201696` | `running / healthy` | `16305907` |
| `test-sp2` | `sp_2` | `2198317` | `bucket_migrate_gc_progress: 2198317`, `bucket_migrate_progress: 2198317` | `running / healthy` | `16309286` |
| `test-sp3` | `sp_3` | `2205347` | `bucket_migrate_gc_progress: 2205347`, `bucket_migrate_progress: 2205347` | `running / healthy` | `16302256` |
| `test-sp4` | `sp_4` | `2178026` | `bucket_migrate_gc_progress: 2178026`, `bucket_migrate_progress: 2178026` | `running / healthy` | `16329577` |
| `test-sp5` | `sp_5` | `1986996` | `bucket_migrate_gc_progress: 20504`, `bucket_migrate_progress: 1986968` | `running / healthy` | `16520607` |

## 现象说明
- `test-sp0` 到 `test-sp4` 的主同步高度都在 `2.17M` 到 `2.20M` 左右
- `test-sp5` 更落后，当前在 `1.99M` 左右
- `test-sp5` 的迁移订阅进度里仍存在明显异常值：
  - `bucket_migrate_gc_progress = 20504`
- 当前 6 台 SP 的 `moca-sp` 容器都已经处于 `running / healthy`

## 运行状态补充
### 全量链访问修复（`test-sp0` - `test-sp5`）

- 2026-04-13 复查发现，`test-sp0` 到 `test-sp4` 访问公开 `testnet-rpc.mocachain.org` / `testnet-lcd.mocachain.org` 时仍会遇到 `403 Forbidden`
- 直接保留 `https://...:443` 还有一层证书链校验问题；改成不带端口的 `http://域名` 后，程序内部又会报 `missing port in address`
- 最终统一修复方式如下：
  - 在 6 台 SP 的 `/etc/hosts` 中固定解析：
    - `54.38.38.12 testnet-rpc.mocachain.org`
    - `54.38.38.12 testnet-lcd.mocachain.org`
  - 将 6 台 SP 的 `/data/moca/spX/config.toml` 统一改为显式 `:80`：
    - `ChainAddress = ['http://testnet-lcd.mocachain.org:80']`
    - `RpcAddress = ['http://testnet-rpc.mocachain.org:80']`
- 修复后已逐台验证：
  - `sp0-sp5` 容器均为 `running / healthy`
  - 新日志中已不再出现 `403 Forbidden`
  - 新日志中已不再出现 `certificate signed by unknown authority`
  - 新日志中已不再出现 `missing port in address`

### `test-sp4`

- `test-sp4` 之前的主要问题不是磁盘满，而是 SSH 登录过程中的 session 管理异常
- 已定位到 `pam_systemd` / `systemd-logind` session 卡住，表现为 SSH 认证成功但连接收尾要等待约 120 秒
- 已在主机上重启 `systemd-logind` 并清理失败 session
- 修复后 SSH 耗时已恢复到秒级，数据库与容器状态也已可正常查询

### `test-sp5`

- `test-sp5` 的 `moca-sp5` 之前处于 `Exited (0)`，并且 Docker 日志显示该容器曾被标记为 `hasBeenManuallyStopped=true`
- 重新拉起后，容器启动阶段又遇到 `testnet-rpc.mocachain.org` / `testnet-lcd.mocachain.org` 返回 `403 Forbidden`
- 最终修复方式：
  - 先通过 `/etc/hosts` 固定解析将域名指向 `test-rpc-eu` 主机 `54.38.38.12`
  - 后续再与其他 SP 一并统一切换到显式 `http://...:80` 配置
- 修复后 `moca-sp5` 已恢复为 `running / healthy`

## 内存与日志结论
- `sp0` 和 `sp4` 监控图上表现为“高内存”，但根因都不是 `moca-sp` 进程内存泄漏
- 现场对比结果：
  - `test-sp0`
    - `moca-sp0` RSS 约 `337 MiB`
    - `Cached` 约 `5.8 GiB`
    - `/data/moca/sp0` 原始体量约 `37G`
    - `moca-sp.log*` 历史文件总量约 `36G`
  - `test-sp4`
    - `moca-sp4` RSS 约 `336.7 MiB`
    - `Cached` 约 `13.0 GiB`
    - `/data/moca/sp4` 原始体量约 `104G`
    - `moca-sp.log*` 历史文件总量约 `100G`
- 结论：
  - 两台机器的真实常驻进程内存都不高
  - 监控中显著偏高的部分主要是 Linux page cache
  - `sp4` 比 `sp0` 更高，主要是因为本地历史日志和数据文件明显更多

## 历史日志清理结果
- 2026-04-13 已对存在历史大日志的节点做一次性清理，仅保留当前运行所需文件，不影响容器健康状态

| Host | 清理前日志总量 | 清理后目录体量 | 结果 |
|---|---:|---:|---|
| `test-sp0` | `35.99G` | `680M` | `running / healthy` |
| `test-sp1` | `35.55G` | `6.3G` | `running / healthy` |
| `test-sp2` | `35.49G` | `6.7G` | `running / healthy` |
| `test-sp3` | `0` | `7.2G` | 无需清理 |
| `test-sp4` | `99.74G` | `3.6G` | `running / healthy` |
| `test-sp5` | `35.26G` | `6.9G` | `running / healthy` |

## 统一日志保留策略
- 当前 `sp` 服务已经使用 Docker `json-file` 日志驱动，并设置：
  - `max-size = 500m`
  - `max-file = 3`
- 因此容器 stdout/stderr 日志本身不会无限增长
- 真正的风险点是升级前遗留的文件日志，例如：
  - `moca-sp.log.*`
  - `logs.*`
- 已为 6 台 SP 统一补充每日清理策略：
  - 脚本路径：`/etc/cron.daily/moca-sp-log-retention`
  - 每日执行，删除超过 3 天的 `moca-sp.log.*` 与 `logs.*`
  - 这样既能避免再次积累到几十 GB 甚至上百 GB，也保留了短期排障窗口

## 一键运维脚本
- 本次排障流程已经整理为本地总控脚本：
  - `mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh`
- 该脚本在本机执行，通过 SSH 批量连接 `test-sp0` 到 `test-sp5`
- 默认安全策略：
  - `check-*` 子命令始终只读
  - `fix-*` / `cleanup-*` / `install-*` 默认只预演
  - 只有显式加 `--apply` 才会修改远端
  - `cleanup-legacy-logs` 会按 `--retention-days` 筛选匹配文件，默认只处理超过 3 天的 `moca-sp.log.*` / `logs.*`

常用命令示例：

```bash
# 1) 查看 6 台 SP 的容器健康状态
mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh check-health

# 2) 查看链访问配置、hosts 映射和最近报错
mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh check-chain-access --since 30m

# 3) 查看各个 SP 当前数据库同步到的高度
mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh check-db-sync

# 4) 预演链入口修复，不真正修改
mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh fix-chain-access --hosts test-sp0,test-sp4

# 5) 对单台主机真正执行链入口修复
mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh fix-chain-access --hosts test-sp0 --apply

# 6) 预演历史文件日志清理
mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh cleanup-legacy-logs --hosts test-sp0,test-sp4

# 7) 安装统一日志保留策略
mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh install-log-retention --apply

# 8) 批量做收尾验证
mocachain/tasks/sp-sync/scripts/testnet-sp-ops.sh verify --since 30m
```

## 线上查询方法
每台 SP 的查询步骤如下：

1. 读取 `/data/moca/spX/config.toml`
2. 提取 `BsDB` 配置
3. 连接 `BsDB` 指向的本地 MySQL
4. 查询 `epoch.block_height`

实际用到的配置字段：
- `BsDB.User`
- `BsDB.Passwd`
- `BsDB.Address`
- `BsDB.Database`

## 结论摘要
- 从代码角度，应以 `epoch.block_height` 作为 `moca-storage-provider` 的主同步高度
- `migrate_subscribe_progress.last_subscribed_block_height` 只是迁移事件订阅进度，不能替代主同步高度
- 本次从 RPC 获取到的 testnet 链上最新高度为 `18507603`
- 当前 6 台 SP 的 `moca-sp` 容器均已恢复为 `running / healthy`
- 当前 6 台 SP 的链访问入口已统一修复为 `http://testnet-lcd.mocachain.org:80` / `http://testnet-rpc.mocachain.org:80`，并通过 `/etc/hosts` 固定解析到 `54.38.38.12`
- `sp0` 与 `sp4` 的“高内存”本质是文件缓存偏高，不是进程内存泄漏
- `sp0 / sp1 / sp2 / sp4 / sp5` 的历史大日志已完成清理，统一日志保留策略也已补齐
- 线上各 SP 数据库当前记录值见上表

## Related
- [[SP Upgrade Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
