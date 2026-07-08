---
title: Validator Onboarding
aliases:
  - validator onboarding
  - mainnet validator onboarding
tags:
  - moca
  - core
  - validator
  - operations
type: guide
status: active
area: core
---

# Validator Onboarding

> [!summary]
> 第三方接入 Moca mainnet validator 的长期有效知识应沉淀在这里。当前组织、当前联系人、当前参数值或某次接入任务的具体执行记录，继续留在 `mocachain/tasks/mainnet/`。

## Scope

这里讨论的是第三方以独立 validator operator 身份接入 Moca mainnet 时，长期稳定的资料结构与流程模型。

不包含：

- 某次具体接入任务的现场沟通
- 某个组织当前的审批人、联系人或时间窗口
- 某台具体机器的部署命令

## What We Should Provide

长期来看，任何第三方 validator onboarding 都应至少提供以下六类资料。

### 1. Mainnet Network Parameter Pack

至少应包含：

- `chain_id`
- `genesis.json`
- 推荐 `config.toml`
- 推荐 `app.toml`
- RPC / gRPC / REST / EVM RPC 入口
- `seeds` 或 `persistent_peers`
- 如果支持快速追块，还应包含 state sync / snapshot 获取方式

原则是把这些内容打包成一份权威材料，而不是让对方自行从多个仓库拼装。

### 2. Official Software Artifacts

至少应包含：

- 推荐 `mocad` 版本
- 对应 release tag
- 二进制或镜像地址
- checksum / digest
- 升级策略
  - 是否要求 `cosmovisor`
  - 是否允许直接替换二进制

### 3. Validator Admission Process

应明确：

- validator 如何加入主网
- 是否需要治理提案
- 是否需要人工审批 / allowlist / 基金会确认
- 最小自抵押与 deposit 要求
- 推荐 gas / fee 策略
- 审核人与预计时间

### 4. Submission Template

应给第三方一份统一模板，至少覆盖：

- `moniker`
- `identity`
- `website`
- `security_contact`
- `details`
- operator / delegator / relayer / challenger 地址
- consensus pubkey
- 如协议要求，还包括 BLS 相关材料

### 5. Deployment And Operations Requirements

长期应固定写明：

- 最低硬件规格
- 推荐操作系统
- 必开端口
- 推荐目录结构
- 日志、监控、告警要求
- 备份、升级、回滚、迁移策略
- 双签 / 漏签 / 宕机风险边界

### 6. Go-Live Acceptance Checklist

上线标准应至少包括：

- 完成初始同步
- P2P 正常
- RPC / gRPC / REST 可用
- validator 可被链上查询
- validator 状态健康
- 自抵押到位
- 如需提案，则提案通过
- 稳定签块
- 监控与告警接入完成
- 密钥备份完成

## What The Partner Should Prepare

### 1. Infrastructure

- 生产运行环境
- 公网网络能力
- 足够带宽与 SSD
- 基础安全加固
- 如需要，sentry 架构

### 2. Operational Capability

- Linux 运维
- systemd 或容器编排
- 二进制 / Docker 部署
- `cosmovisor`
- Prometheus / Grafana / Alertmanager
- 紧急升级和故障切换

### 3. Funding

- 自抵押资金
- proposal deposit
- gas 预算
- 长期运维预算

### 4. Addresses And Keys

- validator operator key
- delegator key
- consensus key
- 如需要，relayer / challenger / BLS key

### 5. Security And Backup Plan

- `priv_validator_key.json` 保管方式
- `priv_validator_state.json` 迁移方式
- 是否使用 HSM / remote signer
- 如何避免双签
- 冷备与灾备方案

## Recommended Phases

长期建议的 onboarding 阶段可以固定为：

1. 资料对齐
2. 环境准备
3. validator 准入 / 注册
4. 上线验收
5. 持续运维

## What Stays In Tasks

以下内容不属于本页，应留在 `mocachain/tasks/mainnet/`：

- 某次第三方接入的现场沟通材料
- 当前审批人与联系人
- 当前主网参数的具体值
- 某次接入过程里的缺口、阻塞和现场记录

## Related

- [[Core Home]]
- [[Key Flows]]
- [[SP Lifecycle]]
- [[mocachain/areas/tasks/Mainnet Ops Index|Mainnet Ops Index]]
