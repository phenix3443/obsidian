# CR Round 2 · Agent 稳定币支付通道

评审对象：[Agent 稳定币支付通道.md](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md)

## Findings

### 1. 产品命题和一期范围仍未完全对齐

- 严重性：高
- 位置：
  - [Agent 稳定币支付通道.md:3](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:3)
  - [Agent 稳定币支付通道.md:35](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:35)
  - [Agent 稳定币支付通道.md:89](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:89)
  - [Agent 稳定币支付通道.md:93](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:93)
- 问题：
  - 文首和第 2 节仍将命题定义为“自主发起、自主接收、自主确认”三项完整能力。
  - 但第 3.3 节又把 `钱包 / agent 授权层` 放到“评估，可先集成现成方案，不自建”，并明确一期的“自主接收”只先做到“收款方确认到账”。
  - 这样会让读者不清楚：这三项能力是长期愿景，还是第一版就承诺交付。
- 建议：
  - 在文首直接拆成两层：
  - 长期命题：三项自主能力。
  - Phase 1 交付：`facilitator + 风控 + 对账 + 制裁筛查`。

### 2. 目标市场表述前后打架

- 严重性：高
- 位置：
  - [Agent 稳定币支付通道.md:50](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:50)
  - [Agent 稳定币支付通道.md:172](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:172)
- 问题：
  - 第 3 节说 API 中转站只是早期场景之一，不作为核心市场。
  - 第 7 节又把“专注 API 转售生态”写成两项关键差异化之一。
  - 这会让读者无法判断：产品到底是“通用 agent 经济支付层”，还是“先打 API 转售/聚合这个垂直场景”。
- 建议：
  - 二选一写清楚：
  - 要么 API 转售是主切口。
  - 要么 API 转售只是验证场景，不是核心定位。

### 3. 合规章节前后口径不一致

- 严重性：高
- 位置：
  - [Agent 稳定币支付通道.md:203](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:203)
  - [Agent 稳定币支付通道.md:316](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:316)
- 问题：
  - 第 9 节已经补上了“研究备忘录级判断”“很多结论须律师确认”的使用边界。
  - 但第 13.A 又直接写“满足以下全部条件，则不构成货币转移商、可豁免牌照”。
  - 这会让整篇文档出现两个不同的法律口径：一处谨慎，一处像已定论。
- 建议：
  - 把第 13.A 改成条件式表述，例如：
  - “可作为主张非货币转移商身份的有利事实”
  - 不要写成内部已确认的法律结论。

### 4. 角色划分更清楚了，但产品责任边界仍偏抽象

- 严重性：中
- 位置：
  - [Agent 稳定币支付通道.md:56](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:56)
  - [Agent 稳定币支付通道.md:63](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:63)
  - [Agent 稳定币支付通道.md:288](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20稳定币支付通道.md:288)
- 问题：
  - 新增的“谁付款、谁收款、谁集成、谁担责”比上一版清楚很多。
  - 但“合规责任主体”仍然比较抽象，没有进一步绑定到产品责任边界。
  - 例如：如果本产品提供 OFAC/KYT、风控、对账、回调，那么哪些只是“提供工具”，哪些会被外部理解为“实际承担运营责任”，文中仍未拆开。
- 建议：
  - 增加一张责任边界表：
  - 我方提供什么能力。
  - 集成方承担什么法定义务。
  - 收款方承担什么业务判断与退款责任。

## Summary

这版比上一轮明显更收敛，尤其第 3 节已经开始像真正的产品定义。剩下的主要问题不在于信息量，而在于还需要把以下四件事再对齐一次：

1. 长期命题 vs Phase 1 交付
2. 通用市场 vs 主切场景
3. 合规备忘录口径 vs 法律定论口径
4. 提供工具 vs 承担责任
