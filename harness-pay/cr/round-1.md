# CR · Agent 稳定币支付通道

评审对象：[Agent 稳定币支付通道。md](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20 稳定币支付通道。md)

## Findings

### 1. 合规结论下得过重，但证据链不足以支撑决策级表述

- 严重性：高
- 位置：
  - [Agent 稳定币支付通道。md:155](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20 稳定币支付通道。md:155)
  - [Agent 稳定币支付通道。md:347](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20 稳定币支付通道。md:347)
- 问题：
  - 文档把中国、美国、欧盟、香港直接分成红黄绿灯，并据此给出“明确非法”“可行但有约束”等判断。
  - 但来源区多数是机构首页、汇总链接或二手分析，缺少足以支撑这些强结论的条文级引用、关键定义摘录和推理链。
  - 这会让文档更像“研究备忘录”，还不够格当“产品立项依据”。
- 建议补充：
  - 具体法规标题、发布日期、适用辖区、关键条文摘录。
  - 每条合规结论对应的推理链。
  - 哪些结论必须等待跨境律师意见，不能在内部文档中先拍板。

### 2. “agent 是核心用户”与“谁采购/集成产品”混在一起，GTM 对象不清

- 严重性：高
- 位置：
  - [Agent 稳定币支付通道。md:47](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20 稳定币支付通道。md:47)
- 问题：
  - 文档把“agent 本身”写成核心用户，但真正签约、集成、承担风控和回调处理的，通常会是 API 平台、agent 平台、开发团队或商户。
  - 这会直接影响产品设计：控制台给谁用、退款由谁发起、KYC/KYT 义务由谁承担、销售卖给谁。
- 建议补充：
  - 明确区分 `payer agent`、`service provider`、`integrator/platform`、`legal customer of record` 四类角色。
  - 单独增加一节“谁是用户，谁是客户，谁是操作者”。

### 3. 需求证据证明了“稳定币支付存在”，但还没充分证明“agent 原生支付通道”必须单独做

- 严重性：中高
- 位置：
  - [Agent 稳定币支付通道。md:145](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20 稳定币支付通道。md:145)
  - [Agent 稳定币支付通道。md:149](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20 稳定币支付通道。md:149)
- 问题：
  - 这些证据更多证明“AI 服务市场存在”“链上支付存在”“有人在用稳定币买 AI 服务”。
  - 但还没有把关键一跳讲透：为什么现有 `Stripe/Coinbase/x402 + 自建业务逻辑` 不够，必须单独出现一个“agent 支付通道”产品。
- 建议补充：
  - 用 3 到 5 个具体场景说明现有方案卡在哪里。
  - 把“缺的是收款能力”还是“缺的是安全、风控、对账、非托管组合”说清楚。

### 4. 产品范围仍然发散，像方向地图，不像收敛的一期定义

- 严重性：中高
- 位置：
  - [Agent 稳定币支付通道。md:35](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20 稳定币支付通道。md:35)
  - [Agent 稳定币支付通道。md:120](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20 稳定币支付通道。md:120)
  - [Agent 稳定币支付通道。md:232](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20 稳定币支付通道。md:232)
- 问题：
  - 当前命题同时覆盖了支付通道、钱包/授权、风控中间件、对账 SaaS、法币出入金。
  - 这更像战略地图，不像一个能执行的一期产品定义。
- 建议补充：
  - 增加 `Phase 1 in scope / out of scope` 表。
  - 明确第一版卖的是：
    - 纯 facilitator
    - facilitator + 风控
    - facilitator + 对账
    - 还是 facilitator + 钱包授权层

### 5. 定位语言还不够锋利，容易被一句“这不就是 Stripe/Coinbase 的子集吗”打回去

- 严重性：中
- 位置：
  - [Agent 稳定币支付通道。md:43](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20 稳定币支付通道。md:43)
  - [Agent 稳定币支付通道。md:90](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20 稳定币支付通道。md:90)
  - [Agent 稳定币支付通道。md:128](/Users/liushangliang/github/phenix3443/obsidian/tude/Agent%20 稳定币支付通道。md:128)
- 问题：
  - 文档先借用“面向 agent 的 Stripe”帮助理解，但后文又承认 Stripe 已经部分占位。
  - 真正差异化是在“非托管 + 高频程序对程序支付 + 安全/风控/对账层”，但这一句没有在前面直接落下去。
- 建议补充：
  - 直接改成更窄的定位句，例如：
  - “不是给所有商户收款，而是给程序对程序的高频付费场景提供非托管结算与风控层。”

## Open Questions

1. 第一批真正付费并集成的客户是谁：API 聚合器、模型平台、agent framework，还是单个开发者？
2. 一期是否真的要覆盖“自主接收”，还是先做“agent 发起支付 + 商户确认到账”即可？
3. “非托管”到底是产品原则，还是主要为规避牌照做的合规约束？

## 建议补充的结构

建议下一版至少补三块：

1. 一页角色图：谁付款、谁收款、谁集成、谁承担合规责任。
2. 一页范围图：Phase 1 做什么，不做什么。
3. 一页竞争图：为什么 `x402/Stripe/Coinbase` 现成组合不能直接满足目标客户。
