---
title: Storage And Access Model
aliases:
  - storage model
  - access model
  - moca storage model
tags:
  - moca
  - core
  - storage
  - domain
type: guide
status: active
area: core
---

# Storage And Access Model

> [!summary]
> Moca 的存储领域不是单一对象，而是一组彼此关联的链上与服务侧概念：`bucket` 管组织边界，`object` 管具体数据，`group` 和 `policy` 管授权，`payment account` 管资源结算，`virtual group` 管 SP 放置与迁移语义。

## Core Objects

- `bucket`
  - 对象存储的逻辑容器，很多权限、配额、上传和迁移流程都从这里开始
- `object`
  - 真实被上传、下载、查询和迁移的数据对象
- `group`
  - 一组身份或资源的逻辑集合，常作为权限分配与共享边界
- `policy`
  - 描述谁可以对哪些资源做什么操作的规则对象
- `payment account`
  - 与支付、计费、资源消耗绑定的账户关系
- `virtual group`
  - 与 SP 放置、家族关系、迁移和退出流程强相关的资源编排对象

## Relationship Sketch

- `bucket` 是对象组织和很多访问控制的起点
- `object` 通常挂在某个 `bucket` 之下
- `group` 和 `policy` 用来描述资源共享与访问授权
- `payment account` 负责把资源使用和支付关系绑定起来
- `virtual group` 不等于普通权限 `group`
  - 它更接近底层存储编排与 SP 生命周期对象
  - 在 SP 退出、swap、recover 等流程里会频繁出现

## Where To Look In Code

- 看链上资源模型、query/tx、模块状态
  - 先看 `moca`
- 看对象存储服务端、SP 网关、后台任务、迁移调度
  - 先看 `moca-storage-provider`
- 看操作者怎样发起 bucket/object/group/policy/payment/SP 操作
  - 先看 `moca-cmd`
- 看 `virtual group` 与 SP 退出、family、迁移
  - 先看 `moca`
  - 再看 `moca-storage-provider`
  - 结合 [[SP Lifecycle]]

## Practical Distinctions

- 看到“对象有没有被创建、删除、迁移”
  - 优先判断是 `bucket/object` 语义，还是 SP 调度问题
- 看到“为什么某人能读/写/共享”
  - 优先判断是 `group/policy` 语义
- 看到“为什么扣费、计费、支付关系不对”
  - 优先判断是 `payment account` 语义
- 看到“为什么 SP 无法退出、family/GVG 不一致、swap 没完成”
  - 优先判断是 `virtual group` 与 SP 生命周期语义

## Boundary Notes

- 当前页只定义稳定领域关系，不记录某次故障的脚本步骤。
- 某轮测试网或主网排障过程，继续留在 `mocachain/tasks/`。
- 如果问题已经进入 precompile 语义，继续看 [[Precompile Architecture]]。

## Related

- [[Core Home]]
- [[Domain Concepts]]
- [[Key Flows]]
- [[SP Lifecycle]]
- [[Precompile Architecture]]
