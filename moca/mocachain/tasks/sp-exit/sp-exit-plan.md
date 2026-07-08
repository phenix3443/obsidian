---
title: "Testnet 剩余 SP 退出计划"
aliases:
  - sp-exit-plan
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
source_path: "tasks/sp-exit/sp-exit-plan.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 SP Exit，并补齐索引与语言导航。

> [!info]
> 长期有效的 SP 生命周期知识已沉淀到 [[core/SP Lifecycle|SP Lifecycle]]。当前页保留本轮 testnet 退出范围、映射与执行计划。

## Navigation
- [[Tasks Index]]
- [[SP Exit Index]]
- [[Topic Index]]
- [[Language Index]]
- [[core/SP Lifecycle|SP Lifecycle]]

---

# Testnet 剩余 SP 退出计划

## 当前状态

根据当前 `moca-cmd sp ls` 结果，testnet 现在仍在 SP 列表中的节点只剩 5 台：

- `sp0`
- `sp1`
- `sp2`
- `sg-sp1`
- `us-sp1`

其中：

- `sp0`
- `sp1`
- `sp2`

是当前保留的 BP 自有 SP。

因此，原 6 台待退出的 SG / US SP 里，目前只剩以下 2 台尚未退出：

- `sg-sp1`
- `us-sp1`

## 当前退出范围

### 已退出
- `sg-sp0`
- `sg-sp2`
- `us-sp0`
- `us-sp2`

### 待退出
- `sg-sp1`
- `us-sp1`

### 保留节点
- `sp0`
- `sp1`
- `sp2`

## 已确认的运行信息
- `us-sp1` -> `test-sp4` -> `moca-sp4` -> `/app/config.toml`
- `sp0` -> `test-sp0` -> `moca-sp0` -> `/app/config.toml`
- `sp1` -> `test-sp1` -> `moca-sp1` -> `/app/config.toml`
- `sp2` -> `test-sp2` -> `moca-sp2` -> `/app/config.toml`
- `sg-sp1` 的运行时映射仍需在执行前现场确认。
  - 现有 `exit-single-sp.sh` 仍将其映射到 `test-sp1` / `moca-sp1`
  - 但当前链上 `sp ls` 同时存在 `sp1` 与 `sg-sp1`，说明旧脚本映射可能已经过期

## 当前目标

只处理剩余 2 台待退出 SP：

1. `sg-sp1`
2. `us-sp1`

完成标准：

- 发起 `spExit`
- 确认链上进入退出中状态
- 等待 family / GVG 迁移完成
- 执行 `completeSpExit`
- 验证链上 SP 列表已移除

## 可执行命令

### sg-sp1
```bash
bash /Users/liushangliang/github/phenix3443/zkme/mocachain/tasks/sp-exit/exit-single-sp.sh \
  --target sg-sp1 \
  --declare-cmd 'ssh test-sp1 "docker exec moca-sp1 moca-sp spExit --config /app/config.toml"' \
  --finalize-cmd 'ssh test-sp1 "docker exec moca-sp1 moca-sp completeSpExit --config /app/config.toml"'
```

### us-sp1
```bash
bash /Users/liushangliang/github/phenix3443/zkme/mocachain/tasks/sp-exit/exit-single-sp.sh \
  --target us-sp1 \
  --declare-cmd 'ssh test-sp4 "docker exec moca-sp4 moca-sp spExit --config /app/config.toml"' \
  --finalize-cmd 'ssh test-sp4 "docker exec moca-sp4 moca-sp completeSpExit --config /app/config.toml"'
```

## 操作注意事项

- 不要对 `sp0` / `sp1` / `sp2` 发起退出。
- 在执行 `sg-sp1` 退出前，先重新确认它实际对应的 SSH host / container，避免误操作到保留节点 `sp1`。
- 以当前链上 `sp ls` 结果为准，不再沿用旧的 6 台并行/分波次退出顺序。
- 如果现场发现 scheduler 没有自动推进迁移，再评估是否需要复用 `manual-complete-sp-exit.sh` 或手工 `swapIn/completeSwapIn` 收尾。

## 验证命令

```bash
./build/moca-cmd --home ./deployment/testnet sp ls
```

预期最终只剩：

- `sp0`
- `sp1`
- `sp2`

## 备注

- 当前文档已基于现状收敛为“剩余 2 台待退出”的收尾计划。
- 旧的 `sg-sp0` / `us-sp0` / `sg-sp2` / `us-sp2` 历史执行细节，继续保留在其他任务文档中，不再放在本文件重复维护。

## Related
- [[SP Exit Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
