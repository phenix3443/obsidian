# Agent Rules

> [!summary]
> `agent-store/` 是 Obsidian 知识库里的 **workspace 容器目录**：存放 workspace 级文档和 `agent-store.code-workspace` 配置，本身不是任何代码仓库的根目录。通用协作规则见全局 `~/.claude/CLAUDE.md`（Git 工作流、代码原则、完成定义、Fix-to-Code、TDD 等），本文件只写 **agent-store workspace 专属** 的拓扑与路由规则。

## Workspace 相关规则

### Workspace 目录结构

这套 workspace 的仓库范围以 `agent-store.code-workspace` 为准，当前固定挂载 3 个目录：

- `obsidian`：当前知识库与 workspace 容器目录，路径 `.`（git root `/Users/liushangliang/github/phenix3443/obsidian`）。处理文档、计划、路由规则和 workspace 配置本身。
- `agent-store`：主代码仓，路径 `../../../awesome-agent-store/agent-store`（绝对路径 `/Users/liushangliang/github/awesome-agent-store/agent-store`，远端 `github.com/awesome-agent-store/agent-store`）。pnpm + turbo monorepo，是 Agent Store 产品本体。
- `registry`：包注册表仓，路径 `../../../awesome-agent-store/registry`（绝对路径 `/Users/liushangliang/github/awesome-agent-store/registry`，远端 `github.com/awesome-agent-store/registry`）。JSON manifest 形式的 provider / skill / MCP 包注册表。

用户提到“当前 workspace”“各仓库”“这个 workspace 里的 repo”时，默认就是上面这 3 个目录，不要为了确认范围重新扫描周边目录或递归查找 `.git`。

只有在以下情况才重新检查 workspace 拓扑：用户明确要求；`agent-store.code-workspace` 被修改；任务明确依赖最新挂载结果。

### 两个代码仓的职责边界

- `agent-store`（主仓）—— 产品代码，pnpm workspace 分 `apps/*` 与 `packages/*`：
  - `apps/api`（`@as/api`）：Cloudflare Workers + Hono 后端
  - `apps/store`（`@as/store`）：Web Store 前端
  - `apps/cli`（`@as/cli`）：命令行客户端
  - `apps/cli-gui`（`@as/cli-gui`）：Tauri 桌面客户端
  - `apps/client-core`（`@as/client-core`）：客户端共享核心
  - `packages/sdk`（`@as/sdk`）、`packages/types`（`@as/types`）：共享 SDK 与类型
  - 常用入口：`pnpm dev` / `pnpm build` / `pnpm lint` / `pnpm type-check` / `pnpm test`（turbo 驱动）；`make setup` / `make seed` / `make dev-api` / `make dev-store` / `make dev-gui` / `make e2e`。
  - UI 设计真源仍在主仓 `docs/ui/Agent Store.dc.html`。
- `registry`（注册表仓）—— 每个包是单个 JSON manifest，放在 `mcp/<slug>.json`、`skill/<slug>.json`、`provider/<slug>.json`，schema 见 `schema/package.schema.json`。本地校验：`bun scripts/validate.ts`（离线只校验结构用 `CHECK_URLS=0`）。改动通过 PR 合并后同步上线。

### 本 workspace 内的参考文档

从主仓迁入、沉淀在本 vault 的知识/运维文档（`agent-store/docs/` 与容器根）：

- `docs/standard-stack.md`：标准后端栈选型与约定（所有独立产品复用）。
- `docs/独立开发者快速部署最佳实践-2026.md`：部署方法论。
- `docs/DEPLOY.md`：agent-store 部署步骤。
- `docs/LAUNCH.md`、`docs/LAUNCH-COPY.md`、`docs/DEMO-SCRIPT.md`：发布计划、文案、演示脚本。
- `docs/codex-claude-shared-guidance-design.md`：Codex/Claude 共享 guidance 与 skill 布局设计（AGENTS.md 为真源、CLAUDE.md 软链的由来）。
- `todo.md`：需人工操作的清单（代码签名、Waffo 收款、桌面登录验证等）。

### 主仓已有的专属规则以主仓 AGENTS.md 为准

`agent-store` 主仓根目录有自己的 `AGENTS.md`，其中的规则是权威来源，本文件不重复、只指路。进入主仓做事前先读它，重点包括：

- **Provider 切换 / 本地代理**：设计前先看参考实现 `code-switch-R`、`cc-switch`，优先复用其成熟方案。
- **UI 以设计文件为准**：`docs/ui/Agent Store.dc.html` 是 UI 结构/布局/行为的唯一真源，直接读它的模板源码，别信 `docs/ui/README.md` 或 `screens/*.png`（已知会过时）。
- **UI 交付签收**：任何 UI 改动必须实际跑起来目视验证（Web 用 `pnpm dev`，桌面用 `make dev-gui` 并对原生窗口截图），不能只靠单测或 diff review。

### 命令执行上下文

- 当前 workspace 容器目录是 `obsidian/agent-store/`，不是代码根目录，不承载 `package.json`、`Makefile`、`turbo.json` 等仓库级执行入口。
- 不得仅因当前目录在 `obsidian/` 下，就假设所有命令都应在当前仓库执行；必须先结合 `agent-store.code-workspace` 判断目标仓库。
- 运行 `pnpm`、`make`、`turbo`、`bun scripts/validate.ts` 等仓库级命令前，必须先切换到对应挂载仓库（产品命令进 `agent-store`，注册表校验进 `registry`），不能先在容器目录试探性执行再根据报错回退。
- 如果用户给出的命令缺少仓库前缀，默认按代码归属判断：产品构建/开发/测试进 `agent-store`；包 manifest 增删改与校验进 `registry`；文档、计划、路由规则调整进 `obsidian/agent-store`。

### Git 边界

- 面向业务仓库的仓库级操作（`commit`、`push`、建/删分支、批量 git 状态检查），默认只作用于 `agent-store` 与 `registry`，不把 `obsidian` 所在仓库纳入目标范围，除非用户明确点名要操作 `obsidian`。
- `obsidian` 仓与两个代码仓是独立仓库，各自提交，不要跨仓混在一个 commit 里。

## 任务规划

- 复杂任务总是先制定方案再执行（Codex 默认进 plan 模式）。方案明确前不动实际代码。

## 文档沉淀规则

- 当用户要求“记住某件事”时，先判断它是否属于长期有效的 workspace / 仓库协作规则：若属于本 workspace 的拓扑或路由，写入本文件；若属于某个代码仓内部规则，写进对应仓的 `AGENTS.md`；若只是当前任务的临时上下文或一次性偏好，则不写入。
- 面向对外内容（issue / PR 标题、正文、评论）禁止出现本地绝对路径；引用方案或文档只能用仓库相对路径、GitHub 链接或直接概述。
