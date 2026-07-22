# CR Round 4 · Agent 稳定币支付通道

评审对象：[Agent 稳定币支付通道.md](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md)

## Findings

### 1. 综合结论对合规路径表述过于顺滑，弱化了前文列出的未决条件

- 严重性：中高
- 位置：
  - [Agent 稳定币支付通道.md:228](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:228)
  - [Agent 稳定币支付通道.md:267](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:267)
  - [Agent 稳定币支付通道.md:281](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:281)
- 问题：
  - 第 9 节和第 13 节已经明确列出多个未决前提：美国/欧盟是否落在较轻监管区间仍需律师确认，离岸辖区最终选型未定，银行/出入金合作方与中国背景创始人的实际开户可行性也未验证。
  - 但第 10 节综合判断里写成“合规上只需一个明确取舍——从定位上排除大陆客群、专注海外，即可进入可行的黄灯区”。
  - 这会让读者误以为“排除大陆”几乎就解决了主要合规问题。
- 建议：
  - 改成：排除大陆是必要条件，但不是充分条件。
  - 同时明确后续仍取决于具体架构、辖区选择、银行与合作方落地。

### 2. `OFAC 制裁筛查` 和 `KYT` 仍被混成一件事，会低估 Phase 1 的复杂度和成本

- 严重性：中高
- 位置：
  - [Agent 稳定币支付通道.md:75](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:75)
  - [Agent 稳定币支付通道.md:110](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:110)
  - [Agent 稳定币支付通道.md:366](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:366)
- 问题：
  - 第 3.3 节把一期能力写成 `OFAC/KYT 制裁筛查接入`，责任边界表也把 `制裁筛查 / KYT` 放在同一行。
  - 但第 13.C 给出的低成本起步方案，本质更接近“地址是否命中制裁名单”的筛查，而不是更广义的 KYT 风险评分、资金来源分析和行为监测。
  - 这样会让读者误以为完整 KYT 也能像 OFAC 地址筛查一样低成本进入一期。
- 建议：
  - 把 `sanctions screening` 和 `KYT` 拆成两个能力。
  - 明确写：Phase 1 至少做制裁名单筛查；完整 KYT 是更高成本、更宽范围的后续增强项，或需单独评估。

### 3. `单集成方 + 多收款方` 已拍板，但局部措辞仍会让人误解为一期要做资金分发

- 严重性：中
- 位置：
  - [Agent 稳定币支付通道.md:69](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:69)
  - [Agent 稳定币支付通道.md:108](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:108)
  - [Agent 稳定币支付通道.md:115](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:115)
- 问题：
  - 第 3.1 节写“一期就需支持‘单集成方 + 多收款方’的对账与分发”。
  - 但第 3.3 节又明确 Phase 1 不做平台内资金路由、归集、代收再分发。
  - 这里的“分发”如果不是资金分发，而是“回调归属/收款归属分配”，当前用词会误导读者。
- 建议：
  - 把“分发”统一改成更准确的词，例如“归属分配”“回调归属”“收款归属映射”。
  - 避免与被排除的一期资金拆分能力混淆。

## Summary

这版已经接近可分享状态，剩余问题主要是避免误读：

1. 合规章节前文很谨慎，但综合结论仍然说得太轻。
2. `OFAC 制裁筛查` 与 `KYT` 的能力边界还不够清楚。
3. `多收款方` 场景里“分发”一词仍有歧义。
