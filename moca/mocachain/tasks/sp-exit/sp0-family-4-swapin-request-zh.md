---
title: "请求 `sp0` 接手 empty family `4`，以完成 `sg-sp0` 的最终退出"
aliases:
  - sp0-family-4-swapin-request-zh
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
source_path: "tasks/sp-exit/sp0-family-4-swapin-request-zh.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 SP Exit，并补齐索引与语言导航。

## Navigation
- [[Tasks Index]]
- [[SP Exit Index]]
- [[Topic Index]]
- [[Language Index]]
- [[sp0-family-4-swapin-request|sp0-family-4-swapin-request]]

---

# 请求 `sp0` 接手 empty family `4`，以完成 `sg-sp0` 的最终退出

## 背景

当前 testnet 上正在完成以下 Storage Provider 的 graceful exit：

- SP moniker: `sg-sp0`
- SP ID: `1`
- SP operator: `0x3801382abca4d7a4886d106efC402F041ca40631`

`moca-storage-provider` 的 SP Exit scheduler 问题和 secondary GVG 漏处理问题已经修复并验证完成，但 `sg-sp0` 仍无法执行最终的 `completeSpExit`。

当前剩余阻塞点已经收敛为：

- 链上仍有一个 empty family 归属 `sg-sp0`
- family ID: `4`
- `primary_sp_id = 1`
- `global_virtual_group_ids = []`

也就是说：

- 这个 family 已经没有任何 GVG
- 但 ownership 还挂在 `sg-sp0` 上
- 导致 `sg-sp0` 不能完成最终退出

## 目标

请让 `sp0` 接手这个 empty family `4`。

本次建议的 successor SP 为：

- successor SP moniker: `sp0`
- successor SP ID: `7`

完成后，family `4` 的 ownership 应从：

- `sg-sp0` (`sp_id = 1`)

迁移到：

- `sp0` (`sp_id = 7`)

之后我们会继续在 `sg-sp0` 上执行最终的 `completeSpExit`。

## 前提说明

`sp0` 不在 Docker 容器内运行，因此以下命令按“直接在主机上执行 `moca-sp` 二进制”的方式给出。

请将下面命令中的：

- `<moca-sp-binary>`
- `<sp0-config-path>`

替换为你机器上的实际值。

常见形式例如：

```bash
/usr/local/bin/moca-sp
/path/to/config.toml
```

## 操作步骤

### Step 1. 由 `sp0` 发起 reserve swap-in

在 `sp0` 所在机器执行：

```bash
<moca-sp-binary> swapIn --config <sp0-config-path> --vgf 4 --gvgId 0 --targetSP 1
```

参数含义：

- `--targetSP 1`：表示被接管的原 owner 是 `sg-sp0`
- `--vgf 4`：表示接管的目标 family 是 `4`
- `--gvgId 0`：表示这是 family 级别的 swap-in，而不是单个 GVG 的 swap-in

预期结果：

- 命令成功返回
- 输出中包含一笔交易 hash

### Step 2. 由 `sp0` 完成 complete swap-in

由于 `family 4` 是 empty family，没有实际对象恢复工作需要等待，因此可直接继续执行：

```bash
<moca-sp-binary> completeSwapIn --config <sp0-config-path> --vgf 4 --gvgId 0
```

预期结果：

- 命令成功返回
- 输出中包含一笔交易 hash

## 执行完成后请回传

请把以下内容发回：

1. `swapIn` 命令的完整输出
2. `completeSwapIn` 命令的完整输出
3. 两笔交易的 tx hash
4. 如果失败，请提供完整报错信息

## 我们这边后续动作

在你完成上述两步之后，我们会继续执行以下检查和收尾：

1. 验证 `family 4` 已不再归属 `sg-sp0`
2. 验证 `sg-sp0` 已不再持有该 empty family
3. 在 `sg-sp0` 上执行：

```bash
moca-sp --config /app/config.toml sp.complete.exit --operatorAddress 0x3801382abca4d7a4886d106efC402F041ca40631
```

4. 验证 `sg-sp0` 已完全退出，并从 SP 列表中消失

## 可直接转发的命令模板

如果 `sp0` 主机上的可执行文件路径和配置文件路径已经明确，可以直接转发下面两条命令：

```bash
<moca-sp-binary> swapIn --config <sp0-config-path> --vgf 4 --gvgId 0 --targetSP 1
<moca-sp-binary> completeSwapIn --config <sp0-config-path> --vgf 4 --gvgId 0
```

## 备注

这不是重新发起 `spExit`。

`sg-sp0` 当前已经处于：

- `STATUS_GRACEFUL_EXITING`

本次操作的唯一目的，是把剩余的 empty family `4` 从 `sg-sp0` 迁走，以便最终 `completeSpExit` 可以成功。

## Related
- [[SP Exit Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
- [[sp0-family-4-swapin-request|sp0-family-4-swapin-request]]
