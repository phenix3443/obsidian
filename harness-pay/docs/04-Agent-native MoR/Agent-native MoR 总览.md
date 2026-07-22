# Agent-native MoR 总览

> 这是 Harness.pay 的中长期产品方向，不代表当前已具备生产能力。

## 核心判断

Agent 不是独立法律人格，而是经过验证的 Principal 的受限执行者。Agent-native MoR 要解决的不是“给 Agent 一个钱包”，而是把 Agent 行动转换为可计税、可开票、可退款、可分账、可追责的法律销售。

## 核心链路

```text
Principal -> Agent Identity -> Mandate -> Quote -> Task
-> Usage / Evidence -> Acceptance -> Payment -> Tax / Invoice
-> Ledger -> Refund / Dispute -> Settlement
```

## 黄金路径

```text
Discover -> Quote -> Authorize -> Reserve -> Execute -> Meter
-> Evidence -> Finalize -> Settle
```

关键原则：先授权后调用、先预留再执行、交付证据后结算、失败可释放或退款。自然语言或模型输出不能直接形成不可逆支付，确定性策略引擎必须校验授权、预算、风险和幂等性。

详见：[[核心对象]]。
