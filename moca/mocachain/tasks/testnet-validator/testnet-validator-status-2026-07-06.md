---
title: "Moca Testnet Validator 状态快照（2026-07-06）"
aliases:
  - testnet-validator-status-2026-07-06
tags:
  - mocachain
  - task
  - validator
  - testnet
  - zh
type: "task-note"
status: "active"
area: "tasks"
topic: "validator"
language: "zh-CN"
source_path: "tasks/testnet-validator/testnet-validator-status-2026-07-06.md"
---

> [!summary]
> 记录 2026-07-06 对 Moca testnet validator 集的即时查询结果，并附上任务内可复用查询脚本 `tasks/testnet-validator/scripts/query-testnet-validators.sh`。

## Navigation
- [[Tasks Index]]
- [[Testnet Validator Index]]
- [[Topic Index]]
- [[Language Index]]

---

# Moca Testnet Validator 状态快照（2026-07-06）

## 查询时间

- 本地查询时间：`2026-07-06T10:51:48+0800`
- 链上最新区块时间：`2026-07-06T02:42:33.557925108Z`

## 查询入口

- CometBFT RPC: `https://testnet-lcd.mocachain.org`
- 查询脚本: `tasks/testnet-validator/scripts/query-testnet-validators.sh`
- 依赖二进制: `/Users/liushangliang/github/mocachain/moca/build/mocad`

## 链信息

- `chain_id = moca_222888-1`
- `latest_block_height = 25019177`
- `max_validators = 100`
- `unbonding_time = 504h0m0s`
- `min_commission_rate = 0.050000000000000000`

## 当前共识 validator 集

当前共识层活跃 validator 共 6 个，另有 1 个 validator 处于 `jailed + unbonding`，不在当前共识集内。

| Moniker | Status | Voting Power | Share | Commission | Operator |
| --- | --- | ---: | ---: | ---: | --- |
| `validator0` | `BOND_STATUS_BONDED` | 10,000,020 | 19.9985% | 7% | `0x92972bFD54651aD54d7B48160d736e7F54eF7654` |
| `validator1` | `BOND_STATUS_BONDED` | 10,000,001 | 19.9984% | 7% | `0xf907768959c59428bdbEe07C51a70Ce7772B6754` |
| `validator2` | `BOND_STATUS_BONDED` | 10,000,000 | 19.9984% | 7% | `0x8b4eF40FD500dFa0Ad2381976C90D9Fad8a42814` |
| `validator3` | `BOND_STATUS_BONDED` | 10,000,000 | 19.9984% | 7% | `0x96E21ceDEf755C42505110CFC87AdbeF2Ae78bA3` |
| `pellar-validator-1` | `BOND_STATUS_BONDED` | 10,000,000 | 19.9984% | 7% | `0xA6edDD2079c26492770d73AD8369c958658c4399` |
| `quicknode-internal` | `BOND_STATUS_BONDED` | 3,871 | 0.0077% | 7% | `0x02a03517fc370cfab06b44d850a6df9f5f9c28c9` |

对应共识地址：

| Moniker | Consensus Address |
| --- | --- |
| `validator0` | `75C9202B19E4006AB23D56DAE72F4A3B0F7E5D10` |
| `validator1` | `49A9B36F49D565ACAEA17E89A807FB3DB8E079B7` |
| `validator2` | `07CAD0D2D58283407764EA786D587A0960D1CE92` |
| `validator3` | `2A9AD25421C250DA0C328018839EFD6C85704B86` |
| `pellar-validator-1` | `B230FAD25C3B7A8D4C3B497D771B85C603AEF2E7` |
| `quicknode-internal` | `88BB53C5563BBD35CE8463A56102B937B581AEF4` |

## 非活跃 validator

| Moniker | Status | Jailed | Tokens | Operator | Unbonding Time |
| --- | --- | --- | ---: | --- | --- |
| `nansen-validator` | `BOND_STATUS_UNBONDING` | `true` | `990000000000000000` | `0x576135d17f4D487BB7c79EED29a66BE703AF2012` | `2026-07-08T10:49:30.206283356Z` |

## 额外观察

- 当前活跃 validator 的 commission rate 都是 `0.070000000000000000`。
- `quicknode-internal` 的 `missed_blocks_counter = 1`，其当前投票权重远低于其他 5 个活跃 validator。
- 当前公开入口 `https://testnet-lcd.mocachain.org` 同时暴露了 CometBFT RPC 风格接口，例如 `/status`、`/validators`、`/net_info`。

## 复现命令

输出 JSON 摘要：

```bash
./tasks/testnet-validator/scripts/query-testnet-validators.sh | jq
```

输出 Markdown 摘要：

```bash
./tasks/testnet-validator/scripts/query-testnet-validators.sh --format markdown
```

## 本次查询使用的数据来源

- `GET https://testnet-lcd.mocachain.org/status`
- `GET https://testnet-lcd.mocachain.org/validators?page=1&per_page=100`
- `mocad query staking validators --node https://testnet-lcd.mocachain.org --output json`
- `mocad query slashing signing-infos --node https://testnet-lcd.mocachain.org --output json`
- `mocad query staking params --node https://testnet-lcd.mocachain.org --output json`
