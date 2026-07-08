---
title: "Moca Mainnet Validator 第三方接入资料清单"
aliases:
  - validator-mainnet-third-party-onboarding
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
source_path: "tasks/mainnet/validator-mainnet-third-party-onboarding.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 Mainnet Ops，并补齐索引与语言导航。

> [!info]
> 长期有效的 validator onboarding 知识已沉淀到 [[core/Validator Onboarding|Validator Onboarding]]。当前页保留具体任务背景、资料缺口和现场组织方式。

## Navigation
- [[Tasks Index]]
- [[Mainnet Ops Index]]
- [[Topic Index]]
- [[Language Index]]
- [[validator-mainnet-third-party-onboarding-en|validator-mainnet-third-party-onboarding-en]]
- [[core/Validator Onboarding|Validator Onboarding]]

---

# Moca Mainnet Validator 第三方接入资料清单

## 目标

本文用于整理第三方接入 Moca mainnet validator 时：

- 我们需要向对方提供什么材料
- 对方需要提前准备什么
- 双方建议按什么顺序推进
- 当前 workspace 中已识别出的资料风险点有哪些

本文只讨论 `validator` 接入，不包含 `storage provider (SP)`。

## 适用范围

- 第三方希望以独立机构身份接入 Moca mainnet
- 接入对象是 validator 节点
- 需要完成节点部署、validator 注册、上线验收与后续运维

## 一、我们需要向对方提供什么

### 1. 主网权威网络参数包

至少包含以下内容：

- `chain_id`
- `genesis.json`
- 推荐使用的 `config.toml`
- 推荐使用的 `app.toml`
- 官方 RPC 入口
- 官方 gRPC 入口
- 官方 REST/LCD 入口
- 官方 EVM RPC 入口
- bootstrap 节点信息
  - `seeds` 或
  - `persistent_peers`
- 如支持快速追块，还应提供：
  - state sync RPC servers
  - trust height / trust hash 获取方式
  - snapshot 获取方式

建议这些内容统一打包成一个 `network-pack/` 目录，而不是让对方自己从多个仓库文件里拼。

### 2. 官方软件发行物

至少提供：

- 推荐的 `mocad` 版本
- 对应 release tag
- 二进制下载地址或 Docker 镜像地址
- checksum / digest
- 升级策略说明
  - 是否要求使用 `cosmovisor`
  - 是否允许直接替换二进制

### 3. validator 准入流程说明

需要明确告诉对方：

- validator 是如何加入主网的
- 是否需要治理提案
- 是否需要人工审批 / 白名单 / 基金会确认
- 最小自抵押要求
- 提案最小 deposit 要求
- 建议 gas / fee 配置
- 从材料提交到正式上线的预计时间
- 谁负责审核和最终确认

如果流程包含治理提案，建议同时提供：

- proposal 模板
- 必填字段说明
- 示例命令
- 常见失败原因

### 4. validator 身份材料模板

建议给对方一份标准模板，要求其填写：

- `moniker`
- `identity`
- `website`
- `security_contact`
- `details`
- validator operator address
- delegator address
- relayer address
- challenger address
- consensus pubkey
- BLS public key
- BLS proof

如果主网实际上不需要其中某些字段，也应该在模板里标为：

- required
- optional
- not-used-on-mainnet

### 5. 节点部署与运维要求

建议明确写给第三方：

- 最低机器规格
  - CPU
  - memory
  - disk type / size
  - network bandwidth
- 推荐操作系统版本
- 必开端口
- 推荐目录结构
- 日志采集建议
- 监控与告警建议
- 备份要求
- 升级流程
- 回滚策略
- 节点迁移注意事项
- 双签 / 宕机 / 漏签风险说明

如果团队推荐 sentry 架构，也应明确写出来，而不是默认对方会自己推断。

### 6. 上线验收 checklist

建议把验收标准写清楚，避免双方口径不一致。

至少包括：

- 节点已完成初始同步
- P2P 正常连接
- RPC / gRPC / REST 正常
- validator on-chain 可查询
- validator 状态正常
- 自抵押已到账
- proposal 已通过
- 开始稳定签块
- 监控 / 告警已接入
- 密钥备份已完成

## 二、对方需要提前准备什么

### 1. 机器与网络环境

对方至少需要准备：

- 正式运行环境
- 推荐为多机部署，而非单机裸跑
- 公网 IP
- 域名或可公开识别的节点入口
- 足够的带宽和 SSD 存储
- 基础安全加固
  - SSH 管控
  - 防火墙
  - 最小权限
  - 审计日志

如果要求 sentry 架构，对方应至少准备：

- 1 个 validator signer / core 节点
- 若干 sentry / edge 节点

### 2. 运维能力

对方应具备以下能力：

- Linux 运维
- systemd 或容器编排能力
- 二进制 / Docker 部署能力
- cosmovisor 使用能力
- Prometheus / Grafana / Alertmanager 基础运维能力
- 紧急升级和故障切换能力

### 3. 资金准备

对方应准备：

- 自抵押所需资金
- 提案 deposit 所需资金
- 日常 gas 费用
- 长期运维预算

建议我们在正式沟通中把以下数值写死，不要仅写“按链上参数为准”：

- 最小自抵押
- 建议自抵押
- 最小 deposit
- 建议 gas price

### 4. 地址与密钥材料

对方需要提前生成并妥善保管：

- validator operator key
- delegator key
- consensus key
- 如协议需要：
  - relayer key
  - challenger key
  - BLS key

同时需要准备：

- 对应地址清单
- pubkey 清单
- 提案中使用的元数据

### 5. 安全与备份方案

对方应在上线前明确：

- `priv_validator_key.json` 如何保管
- `priv_validator_state.json` 如何迁移
- 是否使用 HSM / remote signer
- 如何避免双签
- 如何做冷备
- 如何做灾备切换

## 三、建议的对外接入流程

### 阶段 1：资料确认

我们提供：

- 主网参数包
- 版本与发行物
- validator 准入流程
- 材料模板

对方提交：

- 机构信息
- 运维联系人
- moniker 与公开资料
- 各类地址与公钥

### 阶段 2：环境准备

对方完成：

- 机器准备
- 基础安全加固
- 节点部署
- 同步追块
- 监控与告警

我们协助：

- 核对配置是否符合主网要求
- 核对链参数和版本
- 协助定位同步和连通性问题

### 阶段 3：validator 注册 / 准入

如流程需要治理提案：

- 对方提交 proposal 材料
- 我们核对 proposal 字段和金额配置
- 提交 proposal
- 跟踪投票与执行结果

如流程不需要治理提案：

- 按主网准入规则直接完成 validator 创建

### 阶段 4：上线验收

双方共同确认：

- on-chain 查询正常
- validator 状态正常
- 开始签块
- 指标正常
- 无异常告警

### 阶段 5：持续运维

建议建立：

- 升级通知机制
- 值班联系人
- 事故响应群
- 版本升级窗口
- 定期健康巡检

## 四、建议的资料包目录

建议我们后续对外输出时使用如下结构：

```text
validator-onboarding-pack/
├── 01-network-pack/
│   ├── genesis.json
│   ├── client.toml
│   ├── config.toml
│   ├── app.toml
│   └── README.md
├── 02-release/
│   ├── version.md
│   ├── binaries.md
│   └── checksums.txt
├── 03-validator-admission/
│   ├── process.md
│   ├── proposal-template.json
│   ├── proposal-fields.md
│   └── checklist.md
├── 04-ops-runbook/
│   ├── deploy.md
│   ├── upgrade.md
│   ├── monitoring.md
│   ├── backup-restore.md
│   └── incident-response.md
└── 05-acceptance/
    ├── acceptance-checklist.md
    └── handover.md
```

## 五、基于当前 workspace 识别出的风险点

### 1. 主网 chain ID 存在不一致

当前 workspace 中存在冲突：

- `moca/asset/configs/mainnet_config/genesis.json` 使用 `moca_5151-1`
- `moca/asset/configs/mainnet_config/client.toml` 使用 `moca_5151-1`
- `moca-devcontainer/networks/mainnet/network.env` 使用 `moca_5151-1`
- `moca-e2e/config/mainnet.yaml` 使用 `moca_2288-1`

在正式给第三方发资料前，必须先确定唯一权威值，并同步修正文档或配置。

### 2. mainnet config 中的 peer 信息看起来不是可直接对外使用的 bootstrap 配置

当前 `moca/asset/configs/mainnet_config/config.toml` 中：

- `seeds = ""`
- `persistent_peers` 仍是本地地址样式

这意味着当前仓库中的 mainnet config 更像发布模板，而不是可直接给第三方接入的最终参数。

因此还需要补齐：

- 真实 seeds
- 真实 persistent peers
- 或 state sync 参数

### 3. validator 准入流程在 workspace 中没有主网版单一权威文档

当前能找到：

- testnet proposal 生成脚本
- 本地 `create-validator` 自动化脚本

但缺少一份清晰的“mainnet 第三方 validator 准入 SOP”。

对外前建议单独补一份正式文档。

## 六、最小对外口径建议

如果现在就要先和第三方沟通，至少应先给出以下最小口径：

- 当前推荐使用的主网版本
- 唯一正确的主网 `chain_id`
- 官方 genesis 文件
- 官方 RPC / gRPC / REST / EVM RPC
- validator 准入方式
- 需要准备的地址和公钥清单
- 最低资金要求
- 最低机器规格
- 联系窗口与审核流程

在上述内容未统一前，不建议直接让第三方自行按仓库内容接入主网。

## 七、后续建议

建议把后续工作拆成三个交付物：

1. 统一主网权威参数
2. 输出正式的 validator onboarding pack
3. 输出给 BD / 生态合作方使用的一页式接入清单

这样可以把工程资料、运维资料和商务沟通资料拆开，减少误传。

## Related
- [[Mainnet Ops Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
- [[validator-mainnet-third-party-onboarding-en|validator-mainnet-third-party-onboarding-en]]
