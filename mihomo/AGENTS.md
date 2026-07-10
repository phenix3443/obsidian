# Agent Rules

## 通用规则

### 任务规划

- 仅当任务本身是补充或调整 `AGENTS.md` 工作流程时，不要求额外创建方案文件。

## Workspace 相关规则

### Workspace 目录结构

- 当前目录 `mihomo/`：存放 workspace 级文档和 `mihomo.code-workspace` 配置。
- 这套 workspace 的仓库范围以 `mihomo.code-workspace` 为准，当前固定挂载 4 个目录：
- `obsidian`：当前知识库与 workspace 容器目录，处理文档、计划、路由规则和 workspace 配置本身。
- `clash`：私有主仓库，路径 `../../../womenlia/clash`，处理真实配置、私有脚本、实例运行逻辑和敏感数据。
- `clash-rules`：规则仓库，路径 `../../clash-rules`，处理域名分流、代理命中、直连/代理策略。
- `mihctl`：CLI 与工具仓库，路径 `../../mihctl`，处理通用命令行能力、模板、规则生成和发布相关逻辑。
- 用户提到“当前 workspace”“各仓库”“这个 workspace 里的 repo”时，默认就是上面这 4 个目录，不要为了确认范围重新扫描周边目录或递归查找 `.git`。
- 但凡是面向业务仓库的仓库级操作，默认只作用于 `clash`、`clash-rules`、`mihctl`，不把 `obsidian` 所在仓库纳入目标范围，除非用户明确点名要操作 `obsidian`。
- 只有在以下情况才重新检查 workspace 拓扑：用户明确要求；`mihomo.code-workspace` 被修改；任务明确依赖最新挂载结果。

### 命令执行上下文

- 当前 workspace 容器目录是 `mihomo/`，不是任何业务仓库的代码根目录，也不承载 `mihctl`、`Makefile`、`go.mod`、`package.json` 等仓库级执行入口。
- 不得仅因当前目录在 `obsidian/` 下，就假设所有命令都应在当前仓库执行；必须先结合 `mihomo.code-workspace` 判断目标仓库。
- 在运行 `./mihctl`、`make`、`go test`、脚本或其他仓库级命令前，必须先切换到对应挂载仓库，不能先在 workspace 根目录试探性执行再根据报错回退。
- 如果用户给出的命令缺少仓库前缀，默认先按代码归属判断目标仓库：私有实例运行命令进 `clash`，规则更新相关命令优先进 `clash-rules`，CLI / 模板 / 规则生成 / 发布相关命令优先进 `mihctl`，文档和 workspace 规则调整进 `obsidian/mihomo`。
- 涉及仓库级别边界的操作时，例如 `commit`、`push`、删除本地/远程分支、批量 git 状态检查，默认跳过 `obsidian` 所在仓库；只有用户明确要求操作 `obsidian` 时才纳入。

### 测试执行约束

- 进行测试时，默认优先使用 Docker 或其他隔离容器环境执行，避免直接影响宿主机器的网络环境。
- 尤其是会修改路由、TUN、iptables、防火墙、网络命名空间、代理端口或系统服务状态的测试，禁止直接在宿主机网络环境中执行；若确需在宿主机验证，必须先得到用户明确确认。
