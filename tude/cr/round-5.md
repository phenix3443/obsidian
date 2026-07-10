# CR Round 5 · Agent 稳定币支付通道

评审对象：[Agent 稳定币支付通道.md](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md)

## Findings

### 1. 合规结论在第 10 节已修正，但第 11 节仍残留旧口径

- 严重性：中高
- 位置：
  - [Agent 稳定币支付通道.md:287](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:287)
  - [Agent 稳定币支付通道.md:297](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:297)
- 问题：
  - 第 10 节已经把合规口径修正为：排除大陆是必要条件，但不是充分条件，是否真正落在较轻合规区间仍取决于律师确认、辖区选择、银行与合作方落地。
  - 但第 11 节待决策事项里，`服务对象（合规决定项）` 仍写成“此取舍即进入合规黄灯区”，这还是上一版的旧口径。
  - 这样会造成文内自相矛盾：总结更谨慎，待决策表却更武断。
- 建议：
  - 将第 11 节该处改成与第 10 节一致的说法，例如：
  - “排除大陆是进入可行路径的必要条件，但后续仍取决于具体架构、辖区与合作方落地。”

### 2. `制裁名单筛查` 与 `完整 KYT` 已在第 3.3 和第 13.C 拆开，但第 3.2 与第 12 节仍残留混写

- 严重性：中
- 位置：
  - [Agent 稳定币支付通道.md:95](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:95)
  - [Agent 稳定币支付通道.md:313](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:313)
  - [Agent 稳定币支付通道.md:322](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:322)
- 问题：
  - 你已经在第 3.3 节把 Phase 1 的 `制裁名单筛查` 和后续增强的 `完整 KYT` 分开，也在第 13.C 明确了两者成本和范围差异。
  - 但第 3.2 的对比表里仍写“入账关键路径的 OFAC/KYT 筛查”，第 12 节的盈利模式也还把“合规即服务（KYT/制裁筛查）”混成同一项。
  - 这会让读者重新把两类能力理解成一个打包项，削弱你前面刚建立起来的边界。
- 建议：
  - 第 3.2 场景表改成更精确的表述，例如：
  - “一期：制裁名单筛查；后续：完整 KYT”
  - 第 12 节也建议拆成两项，至少在文案上区分：
  - `制裁名单筛查（低成本、基础合规）`
  - `完整 KYT/风险情报（高成本、可收费增强项）`

## Summary

这版已经很接近收尾，剩下的是两处“局部没同步”的问题：

1. 第 10 节和第 11 节的合规口径还不一致。
2. `制裁名单筛查` 与 `完整 KYT` 的拆分还没有在全文完全同步。
