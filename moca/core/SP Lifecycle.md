---
title: SP Lifecycle
aliases:
  - storage provider lifecycle
  - sp lifecycle
tags:
  - moca
  - core
  - storage-provider
  - operations
type: guide
status: active
area: core
---

# SP Lifecycle

> [!summary]
> Storage Provider 的生命周期是 Moca 项目的长期知识。这里记录稳定有效的阶段模型、常见边界和操作原则；具体主机映射、某次升级、某次退出或某次同步现场记录，留在 `mocachain/tasks/sp-*`。

## Scope

这里覆盖的是 Storage Provider 在项目层面的长期阶段模型：

- 正常运行
- 同步与追块
- 镜像升级
- graceful exit
- 手工收尾

## Lifecycle Stages

### 1. Normal Serving

SP 正常提供对象存储、网关与链上协同能力。

这一阶段长期关注：

- 节点健康
- 链访问质量
- 数据库状态
- 后台任务稳定性

### 2. Sync And Catch-Up

当 SP 明显落后于链高度时，长期原则是：

- 先修链访问入口
- 再看是否需要快照 / 数据预热
- 再逐步调并发和写入批量
- 最后才考虑代码级优化

这条顺序属于长期有效的运维边界，不依赖某次现场排障。

### 3. Image Upgrade

SP 升级长期应关注：

- 镜像版本与发布来源
- 运行用户与数据卷权限
- compose / systemd 配置兼容性
- 健康检查
- 滚动升级顺序
- 升级后功能与链上状态验证

### 4. Graceful Exit

SP 退出不是简单停服务，而是链上与数据侧共同完成的一个生命周期阶段。

长期应关注：

- 声明退出
- 进入 graceful exiting 状态
- family / GVG 迁移
- 最终 `completeSpExit`
- 验证链上 SP 列表移除

### 5. Manual Completion

当 scheduler 未自动恢复迁移计划，或链上状态与本地计划不同步时，可能需要手工收尾。

这类场景的长期知识不是某条命令本身，而是：

- 需要先确认链上状态
- 需要识别 primary / secondary 的迁移责任
- 需要在满足条件后再执行最终 complete exit

## Stable Operational Principles

### Chain Access First

如果 RPC / LCD 不稳定，调高并发不会真正提速，只会更快失败。

### Prefer Config And Data Warmup Before Code Changes

对于同步慢、追块慢、落后很多高度的 SP，长期优先级应是：

1. 修正链访问
2. 快照或高位数据预热
3. 配置调优
4. 代码修改

### Distinguish Task Script From Stable Model

像 `exit-single-sp.sh`、`manual-complete-sp-exit.sh`、某次 `upgrade-sp-image.sh` 这样的脚本，是任务执行工具，不是项目本体知识。

长期知识应该记录：

- 什么阶段存在
- 为什么会卡住
- 什么边界需要验证

而不是把某次现场命令直接当成系统模型。

## What Stays In Tasks

以下内容继续留在 `mocachain/tasks/`：

- 某次 testnet / mainnet 的具体主机映射
- 某个版本号的升级计划
- 某个 SP 的退出现场记录
- 某次同步异常的具体数值、日志和证据

## Related

- [[Core Home]]
- [[Key Flows]]
- [[Validator Onboarding]]
- [[mocachain/areas/tasks/SP Exit Index|SP Exit Index]]
- [[mocachain/areas/tasks/SP Upgrade Index|SP Upgrade Index]]
