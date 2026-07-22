# Agent Store Waffo 商户审核资料与上线审计

> 更新日期：2026-07-22
>
> 公开网站状态：**服务条款、隐私政策、全站法律链接和联系邮箱已部署**
>
> 收款状态：**Waffo 商户审核已通过并开放生产模式权限，但当前店铺仍启用测试模式，不会产生真实交易**；正式收费前仍须补齐公开法定主体资料、确认 MoR 责任、完成 production 配置与 Waffo test mode 生命周期验证

本文将 Waffo 后台填写内容与工程审计拆开。提交申请时只使用第 1 节；方括号内容必须由运营者确认后替换，不能原样提交。本文是工程事实核对，不构成法律意见。

## 1. Waffo 后台填写区

> 本节是唯一的复制填写区。其余章节是内部证据、风险和上线清单。

### 1.0 Waffo 业务详情 12 步填写总表

以下字段于 2026-07-22 从当前 Waffo 店铺的“设置 → 业务详情”页面逐步核对。`当前值` 是页面当时保存或显示的值；`建议填写` 以当前已验证事实为准。

| 步骤 | Waffo 字段 | 当前值 | 建议填写或选择 | 填写前提 |
| --- | --- | --- | --- | --- |
| 1 | 业务类型 | 个人 | **个人** | 当前没有可核验的注册公司主体。如果实际用公司签约、收款和报税，应改选企业并使用同一实体的文件。 |
| 2 | 税务居住地国家和地区 | 中国 | **中国** | 只在你实际居住并申报个人所得税的国家为中国时选择；不能按公司注册地、目标市场或税收优惠选择。 |
| 2 | 合规确认 | 3 项已勾选 | 阅读后勾选三项 | 包括禁止产品、账户审核清单，以及被拒后一周内不再审核的提示。 |
| 3 | 产品就绪状态 | 提交时选择“不，我仍在测试/开发中” | 审核已通过，无需重填 | 该选择如实反映提交时状态。生产模式权限已开放，但店铺仍启用测试模式；完成 production 配置和完整 test mode 生命周期验证前不要切换真实收费。 |
| 4 | 现有客户 | 没有，我刚刚起步 | **没有，我刚刚起步** | 仅在确实已有该产品的付费客户时选“有”；不能把免费用户或测试交易算作付费客户。 |
| 5 | 全名 | 已填写拉丁字母姓名 | 填写护照/身份证上的**完整法定姓名** | 必须使用拉丁字母，并与收款银行账户持有人完全一致；核对拼写、顺序和大小写。 |
| 6 | 商家名称 | `panghuli` | 建议使用 **Agent Store** | 该名称会显示在信用卡账单和邮件收据上。与网站品牌一致更便于买家识别、减少争议；若 `panghuli` 是正式对外总品牌，则应保证 checkout 和网站也能清楚解释二者关系。 |
| 7 | 联系邮箱 | `agent-store@panghuli.tech`，已验证 | **agent-store@panghuli.tech** | 用户已确认 Waffo 后台完成改名并验证，与网站、条款、隐私政策一致。 |
| 8 | 产品网站 URL | 已验证 | `https://agent-store.panghuli.tech/` | 必须保持与验证域名完全一致。 |
| 8 | 服务条款 URL | 已填写 | `https://agent-store.panghuli.tech/terms` | 已部署并通过公网回读。 |
| 8 | 隐私政策 URL | 已填写 | `https://agent-store.panghuli.tech/privacy` | 已部署并通过公网回读。 |
| 9 | 关于您或您的业务 | 已填写 | 使用第 1.1 节英文文本 | 内容包含领域、公开 GitHub、项目仓库、负责范围和创建原因，不虚构工作年限或公司经历。 |
| 10 | 产品和平台详情 | 审核前读取时为空；最终提交值在通过后不可回读 | 使用第 1.2 节英文文本作为留档 | 必须覆盖当前功能、定价模式、目标客户、交付方式，并把规划功能明确标为未上线。 |
| 11 | 产品合规性和透明度 | 审核已通过；向导值不可回读 | 保留核验记录 | 定价清晰和非高风险业务可由当前网站/产品核对；“不侵犯商标”仍需运营者保留商标检索与声明依据。 |
| 12 | 手续费与定价 | 审核已通过；向导值不可回读 | 记录已接受的页面费率 | 提交页面显示成功交易手续费为 **3.9% + USD 0.50/笔**，无月费、无接入费。 |

步骤 3 的“不，我仍在测试/开发中”没有阻止商户审核通过。审核通过只开放生产模式权限，不代表生产产品、webhook、密钥和完整支付生命周期已经就绪，也不等于当前会产生真实交易。

### 1.1 Step 9/12 — About you or your business

**页面标题：** 关于您或您的业务

**审核目的：** 让 Waffo 核验运营者的专业领域、可公开验证的背景、社交资料、项目经历和创建产品的原因。

**可直接填写：**

```text
I am the developer and maintainer of Agent Store, focused on developer tools and AI coding workflows. I am responsible for its web storefront, desktop client, command-line tools, package registry, local provider relay, billing integration, infrastructure, and customer support.

My public GitHub profile is:
https://github.com/phenix3443

The Agent Store source repository is:
https://github.com/awesome-agent-store/agent-store

I built Agent Store because users of tools such as Claude Code and Codex currently have to find, install, and manage skills, MCP servers, and model-provider configurations across separate sources and configuration formats. Agent Store brings these resources into one searchable catalog and provides local desktop and command-line tools for installation, configuration, usage tracking, and provider management.

Website: https://agent-store.panghuli.tech
Customer support: agent-store@panghuli.tech
```

**提交前可选补充：** 如果有可公开核验的 LinkedIn、Twitter/X、个人网站、以前的项目或公司经历，应在 GitHub 段落后增加对应链接和一句具体说明。没有证据时不要补写。

**不要填写：** 未公开的法定身份、虚构工作年限、无法核验的公司经历、用户数量、收入、夸张营销语或尚未上线的功能。

### 1.2 Step 10/12 — Product and platform details

**页面标题：** 产品和平台详情

**可直接填写：**

```text
Agent Store is downloadable software and an online catalog for developers who use AI coding tools such as Claude Code and Codex. It does not sell physical goods, financial products, model compute, or professional services.

Key functions:
1. Browse and install skills, MCP servers, and model-provider configurations from a public package registry.
2. Manage locally installed resources through a desktop client and command-line interface.
3. Run a local relay for provider failover and record usage and cost data locally.
4. Unlock currently available paid local features including budget alerts and advanced usage analysis and export. Multi-provider routing and multi-key rotation are planned and are not currently available.

Target customers are individual software developers and small technical teams that use AI coding agents and customer-selected model providers. Customers supply and pay for their own upstream AI/model-provider accounts and API usage. Agent Store does not provide or resell model compute.

The product is delivered digitally. There are no physical goods. The public website, Terms of Service, Privacy Policy, pricing, and customer-support channel are available on the Agent Store domain.

Current public pricing in USD, with tax included at checkout:
- Free: USD 0, no expiration.
- Pro Monthly: USD 9.99 per month, automatically renewing, with an optional 14-day trial for signed-in users.
- Pro Yearly: USD 99.00 per year, automatically renewing, with an optional 14-day trial for signed-in users.
- Pro Lifetime: USD 199.00 as a one-time purchase for the currently described local Pro features.

Pricing: https://agent-store.panghuli.tech/pricing
Terms: https://agent-store.panghuli.tech/terms
Privacy: https://agent-store.panghuli.tech/privacy
Customer support: agent-store@panghuli.tech
```

### 1.3 Delivery, cancellation, and refunds

```text
The Free product is available immediately. When production charging is enabled, paid entitlement will be delivered electronically after a verified payment webhook is processed by the Agent Store API. No physical delivery is involved.

Monthly and yearly subscriptions renew automatically. Customers can use the cancellation method provided at checkout or in the payment email. If that method is unavailable, they can contact agent-store@panghuli.tech. Cancellation normally preserves access through the end of the paid billing period. The lifetime product is a one-time software purchase and does not renew.

Refund requests are submitted to agent-store@panghuli.tech for identity and order verification. Eligibility depends on applicable law, the policy disclosed at checkout, and Waffo's processing rules. Agent Store does not currently promise a fixed refund window.

Waffo is the intended payment provider and Merchant of Record. The Waffo merchant review is complete and production-mode access is available, but the store remains in test mode and cannot create real transactions. Production charging remains disabled until production products, checkout, webhooks, credentials, and entitlement configuration are complete and the store is explicitly switched to production mode.
```

如果 Waffo 表单要求描述**当前已上线的正式收款**，必须明确写 `Production charging remains disabled`，不能把测试环境履约描述为生产事实。最终 MoR、退款、税务、发票、chargeback 和买家支持责任应以正式协议为准。

### 1.4 Public URLs

| Field | Value |
| --- | --- |
| Website | https://agent-store.panghuli.tech |
| Pricing | https://agent-store.panghuli.tech/pricing |
| Terms of Service | https://agent-store.panghuli.tech/terms |
| Privacy Policy | https://agent-store.panghuli.tech/privacy |
| Customer support | `agent-store@panghuli.tech` |
| Public developer profile | https://github.com/phenix3443 |
| Source repository | https://github.com/awesome-agent-store/agent-store |

## 2. 当前审核结论

| 范围 | 结论 | 说明 |
| --- | --- | --- |
| 服务条款内容 | 已修复并部署 | 中英文覆盖产品、价格、试用、续费、税、取消、退款联系路径和 Waffo 当前状态 |
| 隐私政策内容 | 已修复并部署 | 中英文披露实际数据字段、服务商、存储区域、保留、跨境与人工删除流程 |
| 法律页面可发现性 | 已修复并部署 | 首页、价格页及共享布局可见 `/terms`、`/privacy` 和联系邮箱 |
| 不实跨设备同步宣称 | 已移除并部署 | 首页、文档页、登录弹窗和隐私政策均按本地管理事实描述 |
| 客服邮件规则 | 已配置并回读 | `agent-store@panghuli.tech` 精确转发规则已启用；按用户要求未重新发送真实测试邮件 |
| Waffo 商户审核 | **已通过** | Waffo 业务详情显示“已通过”，生产模式权限已开放 |
| Waffo 申请文案 | 已留档 | 第 1 节保存 12 步字段和第 9、10 步英文文本 |
| Waffo 支付履约代码 | 已修复并部署 | 所有 paid checkout 强制登录；退款成功撤权；仪表盘提供 authenticated buyer 取消和退款申请流程 |
| Waffo 正式收费 | 未启用 | 当前店铺仍显示“测试模式已启用”；公开法定主体、MoR 责任、test mode 生命周期和 production 产品/webhook/secrets 仍未完成 |

## 3. 邮件别名

### 3.1 当前配置

| 检查项 | 结果 |
| --- | --- |
| 域名邮件提供方 | Cloudflare Email Routing |
| Email Routing | `enabled=true`，`status=ready` |
| 精确别名 | `agent-store@panghuli.tech` |
| 规则 ID | `d8ab0fdce4224826bbe52209f7dca8b2` |
| 规则状态 | `enabled=true`，literal exact match |
| 转发目标 | 已验证的运营者邮箱 |
| catch-all | 关闭 |
| MX / SPF / DKIM | Cloudflare Email Routing 记录已存在 |
| DMARC | 未配置 |
| 实际投递 | 本次改名后未重新发送；用户明确要求无需验证 |
| 能力边界 | 仅入站转发，未配置或证明可用该别名出站发件 |

2026-07-22 使用 Wrangler 4.107.0 创建并回读规则。旧的 `support@panghuli.tech` 规则被保留，未删除或改写。

只读复核：

```bash
pnpm exec wrangler email routing settings panghuli.tech
pnpm exec wrangler email routing rules list panghuli.tech
pnpm exec wrangler email routing rules get panghuli.tech d8ab0fdce4224826bbe52209f7dca8b2
pnpm exec wrangler email routing rules get panghuli.tech catch-all
pnpm exec wrangler email routing addresses list
```

如需用项目域名回复客户，须另行配置认证出站服务并对齐 SPF、DKIM、DMARC。入站转发本身不提供发件能力。

## 4. 服务条款修复结果

### 已解决

- 发布一致的中文和英文版本，一次只显示当前语言，并设置正确的正文 `lang`。
- 明确 Free、USD 9.99/月、USD 99/年、USD 199 终身买断和可选 14 天试用。
- 明确月付/年付自动续费、终身方案不续费、含税结账和取消后的通常权益期限。
- 提供可执行的取消与退款联系路径，邮箱为 `mailto:agent-store@panghuli.tech`。
- Waffo 仅以计划采用的支付服务商/Merchant of Record 描述，明确正式收费尚未启用。
- 补充账号责任、可接受使用、终止、服务可用性、免责声明、责任边界和更新通知。
- 首页、价格页和其他公共路由通过共享 footer 暴露条款链接，不再只依赖直接 URL。

### 仍需业务或法律确认

- 法定运营主体、经营地址、通知地址和申请账号主体一致性。
- 适用法律、司法管辖与争议处理条款。
- Waffo 正式协议中的退款时限、例外、处理责任、chargeback 和税务/发票边界。
- 当前条款如实说明“没有固定退款窗口”；确定最终政策后必须同步更新条款、checkout 和 Waffo 后台。

## 5. 隐私政策修复结果

### 已解决

- 删除未实现的跨设备资源同步陈述，并同步修正首页、公开文档和登录弹窗。
- 披露 Neon Auth、GitHub、Google、Neon、Cloudflare、Vercel 和 Waffo。
- 披露账号、发布/评价、订单、buyer identity、订阅、webhook、请求元数据和本地用量字段。
- 说明银行卡信息由 Waffo 处理，Agent Store 不保存完整卡号。
- 说明本地用量明细的 30 天清理规则、日汇总尚无固定自动删除期限。
- 说明 Neon 生产业务库位于美国 `us-east-1`，并披露跨境处理可能性。
- 如实说明当前无自助账号删除入口，访问、更正、导出和删除请求经联系邮箱人工核验处理。
- 提供中英文版本、正确的语言作用域和可点击联系邮箱。

### 仍需运营或法律确认

- 建立可审计的人工删除 SOP，明确 Neon Auth、业务表、支付/税务记录、日志和备份的处理范围。
- 为账号、评价、订阅、webhook、托管日志和日汇总确定具体保留期限或删除触发条件。
- 根据最终运营主体、用户地区和目标市场确认处理法律基础、跨境传输机制及司法辖区权利文本。
- 如未来实现跨设备同步，必须先完成数据流审计，再同步更新政策和产品文案。

## 6. 正式收费前阻塞项

### 仍然阻塞

1. **法定主体缺失**：必须提供法定个人/实体全名、国家/地区、经营地址和税务身份。
2. **生产仍未启用正式 Waffo 配置**：商户审核已经通过，但后台仍处于测试模式。须创建/发布 production 产品和 webhook，替换 production secrets，并在 Waffo test mode 复跑激活、续费、取消、past due、退款、重复和乱序事件后，才能显式切换模式。
3. **退款与 MoR 责任未定稿**：必须使正式协议、checkout、条款、Waffo 后台和 entitlement 行为一致。

### 已解除的工程阻塞

- **订单绑定**：`POST /api/billing/checkout` 对月付、年付和终身买断统一强制认证，只使用 Waffo authenticated checkout 和内部 `user.id`。
- **退款撤权**：`refund.succeeded` 映射为 `canceled`，复用现有 delivery 去重和事件时间保护，退款后的订阅或终身权益不再保持 Pro。
- **取消/退款产品流程**：生产仪表盘通过认证 API 查询当前用户绑定订单；取消使用 Waffo buyer session，退款只接收用户填写的原因，付款 ID、全额和币种均从服务端记录读取。
- **SDK 评估**：当前 `@waffo/pancake-ts 0.11.0` 已提供所需 authenticated checkout、buyer cancellation、refund ticket 和 webhook 字段，本次无需为解决这些问题升级。后续升级仍须阅读变更并复测。

未经另行授权，不创建真实 checkout、不执行真实收费，也不切换 Waffo production secrets。

## 7. 事实与证据

| 事实 | 当前状态 | 主要证据 |
| --- | --- | --- |
| 产品类型 | 软件、在线目录、桌面客户端和 CLI | 生产站、`apps/store`、`apps/client-core` |
| 定价 | USD 0、9.99/月、99/年、199/买断；可选 14 天试用 | 生产 `/pricing`、`packages/types/src/pricing.ts` |
| 支付数据 | 订单、买家、方案、状态、store、环境和事件元数据 | `apps/api/src/db/schema.ts` |
| 支付卡数据 | Waffo checkout 处理；应用不保存完整卡号 | checkout 实现与 schema |
| Webhook 安全 | 原始 body 验签、delivery ID 去重、事件时间保护 | `apps/api/src/app.ts`、subscription queries |
| 本地配置 | 已安装资源、Provider 配置和 API Key 保存在设备 | `apps/client-core/src/registry`、`config` |
| 本地用量 | provider、工具、模型、token、成本、状态码、延迟等；明细 30 天 | `apps/client-core/src/usage` |
| 云端数据 | catalog、publisher、review、subscription、webhook 记录存于 Neon | API schema、部署文档 |
| 身份认证 | Neon Auth；GitHub/Google OAuth | Web 与桌面认证代码 |
| 分析与性能 | Vercel Analytics、Speed Insights | `apps/store/app/layout.tsx` |
| 托管 | Web/API 为 Cloudflare Workers；数据库为 Neon | Wrangler 配置、部署文档 |
| 跨设备资源同步 | 未实现，公开宣称已移除 | 源码搜索、生产页面回读 |
| 账号删除 | 无自助入口，政策提供人工请求流程 | API/UI 审计、生产隐私政策 |

## 8. 部署与验证记录

- 生产 API Worker：`1ce2223e-c3a7-4bd5-9cf5-d0bb6b6f8795`。
- 生产 Store Worker：`63846d72-3e3e-4e53-a61c-dc2a3fd0fbeb`（100% 流量）。
- Waffo 商户审核已通过，业务详情页显示生产模式权限已开放；核验时店铺顶部仍显示“测试模式已启用 - 不会产生真实交易”。
- 生产构建：Next.js 15.5.20 与 OpenNext Cloudflare 1.20.1 构建通过。
- 自动化：API `60 pass / 2 skip / 0 fail`；SDK `23 pass / 0 fail`；Store `77 pass / 0 fail`；TypeScript 类型检查通过；lint 无 warning/error（仅 Next.js 16 迁移提示）。
- 公网回读：`/`、`/pricing`、`/terms`、`/privacy`、`/docs` 均返回当前内容。
- 首页和价格页均含精确链接 `/terms`、`/privacy`、`mailto:agent-store@panghuli.tech`。
- 条款公网正文包含全部价格、试用、自动续费、取消/退款路径和 Waffo 条件性描述。
- 隐私公网正文包含 Neon、Cloudflare、Vercel、GitHub、Google、Waffo、`us-east-1`、30 天明细规则和人工删除路径。
- 首页、文档页和已部署登录 bundle 不再包含未实现的跨设备同步宣称。
- Cloudflare Email Routing 规则 `d8ab0fdce4224826bbe52209f7dca8b2` 已通过 Wrangler 回读验证。
- 生产数据库迁移已应用，新增 buyer self-service 所需的 payment ID、付款金额、币种和 billing period 字段。
- 生产匿名 checkout 和账单管理接口均返回 `401`；价格页未登录点击升级显示登录要求，不创建 checkout。
- 桌面与移动端生产价格页已目视检查，移动端 `scrollWidth = clientWidth`，无横向溢出。
- 本次只读确认 Waffo 审核结果并关闭结果提示，未修改后台产品、webhook、secret 或测试/生产模式，未产生真实费用；初始化脚本已补充 `refund.succeeded` / `refund.failed`，待配置正式或 test webhook 时执行并回读。

## 9. 提交与上线清单

- [ ] 补齐法定主体、地址、国家/地区和税务身份。
- [ ] 由目标司法辖区专业顾问确认适用法律、争议、退款和隐私权利文本。
- [ ] 与 Waffo 确认 MoR、税、发票、退款、chargeback 和买家支持责任。
- [x] 部署中英文 Terms 与 Privacy。
- [x] 从公共首页和价格页提供法律与客服链接。
- [x] 配置 `agent-store@panghuli.tech` 精确入站别名。
- [x] 将 Waffo 联系邮箱改为并验证 `agent-store@panghuli.tech`。
- [ ] 如需要域名出站回复，配置发件服务及 SPF/DKIM/DMARC 对齐。
- [x] 修复匿名购买绑定和退款撤权。
- [x] 实现 authenticated buyer 的取消/退款产品流程。
- [ ] 在 Waffo test mode 复跑激活、续费、取消、past due、退款、重复 webhook 和乱序事件。
- [x] Waffo 商户审核通过并开放生产模式权限。
- [ ] 配置 production 产品、webhook 与 secrets，并在不真实收费的前提下完成生产配置核验；完成前保持测试模式。
