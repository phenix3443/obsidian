---
title: "Testnet SP RC7 升级与 sg-sp0 退出修复验证计划"
aliases:
  - testnet-sp-storage-provider-image-upgrade-and-sp-exit-validation-plan
  - Testnet SP 升级到 `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` 并验证 `sg-sp0` 退出问题修复计划
tags:
  - mocachain
  - task
  - sp-upgrade
  - zh
  - sp-upgrade-v1.20-rc6
  - storage-provider
type: "task-note"
status: "archived"
area: "tasks"
topic: "sp-upgrade"
language: "zh-CN"
source_path: "tasks/sp-upgrade-v1.20-rc6/testnet-sp-storage-provider-image-upgrade-and-sp-exit-validation-plan.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 SP Upgrade，并补齐索引与语言导航。

> [!info]
> 长期有效的 SP 生命周期知识已沉淀到 [[core/SP Lifecycle|SP Lifecycle]]。当前页保留这次 `rc7` 升级与退出验证的任务计划、版本证据和执行步骤。

## Navigation
- [[Tasks Index]]
- [[SP Upgrade Index]]
- [[Topic Index]]
- [[Language Index]]
- [[testnet-sp-storage-provider-image-upgrade-and-sp-exit-validation-plan-en|testnet-sp-storage-provider-image-upgrade-and-sp-exit-validation-plan-en]]
- [[core/SP Lifecycle|SP Lifecycle]]


# Testnet SP RC7 升级与 sg-sp0 退出修复验证计划

---

# Testnet SP 升级到 `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` 并验证 `sg-sp0` 退出问题修复计划

本文档用于规划以下工作：

1. 基于 `moca-storage-provider` `main` 分支最新代码构建并发布 `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7`
2. 参考 `tasks/sp-upgrade-v1.20-rc5/testnet-sp-storage-provider-image-upgrade-plan.md` 将 testnet 全部 6 台 SP 从 `rc6` 升级到 `rc7`
3. 复测 `tasks/sp-exit/sp-exit-plan.md` 中 `sg-sp0` 无法顺利退出的问题，验证 PR #24 / PR #27 相关修复是否生效

---

## 1. 当前已确认事实

### 1.1 代码基线

- 本地仓库：`/Users/liushangliang/github/mocachain/moca-storage-provider`
- 当前 `main` 分支 HEAD：`5fcf09fc958c08ea69762edc444de83f294b3d53`
- 当前 `main` 分支最近关键提交：
  - `5fcf09f` `fix(manager): derive SP exit secondary GVGs from chain (#27)`
  - `f17aa93` `chore: remove dead code and stabilize CI baseline (#26)`
  - `3ebe4ed` `Merge pull request #24 from mocachain/fix/sp-exit-scheduler-startup`
  - `e4284bd` `v1.2.0-rc5`

### 1.2 与本次验证相关的修复点

PR #24 合入的核心变更位于：

- `modular/manager/manager.go`
- `modular/manager/manager_test.go`

修复内容：

- `ManageModular.delayStartMigrateScheduler()` 不再只启动 `bucketMigrateScheduler`
- manager 启动时会同时拉起 `spExitScheduler`
- 补充测试覆盖 delayed startup 后 `QuerySpExit()` 可正常返回

PR #27 合入的核心变更位于：

- `modular/manager/sp_exit_scheduler.go`
- `modular/manager/sp_exit_scheduler_test.go`

修复内容：

- `SPExitScheduler.produceSwapOutPlan()` 不再依赖本地 metadata DB 推导 secondary GVG
- 退出计划会从链上恢复 secondary GVG，再生成 swap-out 计划
- 对应 `moca-e2e` PR #30 已补充 secondary GVG 场景并验证最终 complete exit

这与 `sp-exit-plan.md` 里 `sg-sp0` 已进入 `STATUS_GRACEFUL_EXITING` 但无法继续完成退出的现象直接相关，属于本次验证重点。

### 1.3 当前 testnet SP 基线

参考现有 `rc6` 升级记录，testnet 6 台 SP 当前基线为：

- `test-sp0` -> `moca-sp0` -> `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- `test-sp1` -> `moca-sp1` -> `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- `test-sp2` -> `moca-sp2` -> `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- `test-sp3` -> `moca-sp3` -> `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- `test-sp4` -> `moca-sp4` -> `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- `test-sp5` -> `moca-sp5` -> `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`

SSH 别名沿用现有计划：

- `test-sp0` `172.237.72.112`
- `test-sp1` `172.237.72.132`
- `test-sp2` `172.237.72.135`
- `test-sp3` `173.255.228.82`
- `test-sp4` `173.255.228.112`
- `test-sp5` `173.255.228.122`

---

## 2. 目标与完成标准

### 2.1 目标

- 产出可拉取的镜像 `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7`
- testnet 全部 6 台 SP 从 `1.2.0-rc6` 升级到 `1.2.0-rc7`
- 重新验证 `sg-sp0` 的退出流程是否能够推进到可 `completeSpExit`
- 记录升级与验证证据，确认问题是否已被 PR #24 / PR #27 修复

### 2.2 完成定义

必须同时满足：

1. `moca-storage-provider` 本地基线确认在 `main` HEAD，并完成相关校验
2. `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` 可 `docker pull`
3. 6 台 testnet SP 容器均运行 `1.2.0-rc7` 且 `healthy`
4. `sg-sp0` 退出流程完成一轮有效验证，并沉淀结论：
   - 若问题已解决，记录从声明退出到最终完成退出的证据
   - 若问题仍存在，记录新的阻塞点、日志与链上状态
5. 若执行中修改了升级脚本或文档，变更同步回仓库

---

## 3. 执行范围

### 3.1 包含

- `moca-storage-provider` 镜像构建与发布
- testnet 6 台 SP 滚动升级
- `sg-sp0` 退出问题复测
- 必要的日志、链上状态、容器状态留档

### 3.2 不包含

- 非 testnet 环境升级
- 未在本次问题链路内的额外重构
- 非必要的 compose 大范围改造

---

## 4. 执行阶段

## Phase 1. 发布 `1.2.0-rc7` 镜像

### 4.1 预检查

- 在 `/Users/liushangliang/github/mocachain/moca-storage-provider` 执行：
  - `git fetch origin`
  - `git checkout main`
  - `git pull --ff-only origin main`
  - `git rev-parse HEAD`
- 确认 HEAD 仍为预期提交；如果 `main` 继续前进，以最新 HEAD 为准，并把实际 commit 写回执行记录
- 确认本地工作区无会污染发布的未提交改动

### 4.2 本地校验

建议至少执行：

- `make test`
- `make lint`
- 如发布链路依赖可选项，再补：
  - `make release-dry-run`

说明：

- `Makefile` 已提供 `release` / `release-dry-run`
- `.goreleaser.yml` 已定义 `ghcr.io/mocachain/moca-storage-provider:{{ .Version }}` 多架构发布
- `Dockerfile.release` 当前仍以非 root 用户 `sp` 运行，需延续 `rc5` 已确认过的 compose 兼容修改

### 4.3 发布动作

计划使用现有 release 流程发布：

- 准备 `.release-env`
- 执行正式发布，版本号指定为 `1.2.0-rc7`
- 发布后验证：
  - `docker pull ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7`
  - 如需，分别验证 `-amd64` / `-arm64`

### 4.4 发布证据

至少记录：

- 实际发布 commit SHA
- GHCR 包链接或 `docker pull` 成功结果
- 镜像 digest

本次执行结果：

- 实际发布 commit SHA：`5fcf09fc958c08ea69762edc444de83f294b3d53`
- GitHub Release：`https://github.com/mocachain/moca-storage-provider/releases/tag/v1.2.0-rc7`
- `docker pull ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` 已成功
- 镜像 digest：
  - `ghcr.io/mocachain/moca-storage-provider@sha256:9fdfe758674e441d099765dd07dfcc413d92f1ae0867de599e08a7f0a5ea680c`

---

## Phase 2. 升级脚本与操作模板准备

### 5.1 复用 `rc5` 经验

沿用 `tasks/sp-upgrade-v1.20-rc5/testnet-sp-storage-provider-image-upgrade-plan.md` 中已验证有效的兼容处理：

- 数据卷 `chown -R 1000:1000`
- compose `command` 去掉 `moca-sp` 前缀并保留 `--log.std`
- healthcheck 用 `bash /dev/tcp`
- 仅滚动重启 `sp` 服务

### 5.2 本次需要调整的内容

建议复制现有脚本生成 `rc6` 专用版本，例如：

- `tasks/sp-upgrade-v1.20-rc6/upgrade-sp-image.sh`

仅做最小改动：

- `OLD_IMAGE` 从 `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- `NEW_IMAGE` 改为 `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7`

如现场核验发现 compose 已经是兼容后的写法，则脚本应保留幂等特性，避免重复破坏配置。

### 5.3 升级前检查清单

每台机器执行前确认：

- `docker ps` 中当前运行镜像确为 `1.2.0-rc6`
- `/data/moca/compose-sp.yaml` 存在
- `docker compose -f /data/moca/compose-sp.yaml config --services` 中包含 `sp`
- `df -h` 剩余空间足够
- 若历史日志过大，按需清理 `moca-sp.log.*`

---

## Phase 3. Testnet 滚动升级到 `rc7`

### 6.1 建议顺序

1. `test-sp0`
2. `test-sp1`
3. `test-sp2`
4. `test-sp3`
5. `test-sp4`
6. `test-sp5`

原因：

- `test-sp0` 对应 `sg-sp0`，既是本次问题节点，也是最关键金丝雀
- 先验证问题节点上的 `rc6` 行为，再推广到其他节点

### 6.2 单机步骤

每台机器统一执行：

1. 备份 `/data/moca/compose-sp.yaml`
2. 将镜像从 `1.2.0-rc6` 改为 `1.2.0-rc7`
3. 核对 `command` 与 `healthcheck` 仍保持 `rc5` 已验证过的兼容写法
4. `docker compose pull sp`
5. `docker compose up -d sp`
6. 等待健康检查
7. 查看日志确认无持续 panic / 配置错误 / DB 连接错误

### 6.3 单机验收

每台机器至少确认：

- `docker inspect <container>` 返回镜像为 `1.2.0-rc7`
- 容器状态 `healthy`
- 最近 100 行日志无持续报错
- 管理接口和基础探活恢复

### 6.4 批次控制

- `test-sp0` 通过后再推进 `test-sp1` ~ `test-sp5`
- 若 `test-sp0` 升级后出现启动异常、scheduler 初始化异常或 secondary GVG 迁移计划仍异常，则暂停全量升级

---

## Phase 4. 验证 `sg-sp0` 退出问题

### 7.1 验证目标

验证 PR #24 / PR #27 修复后，`sg-sp0` 在 `rc7` 上是否能够正常推进 SP Exit 调度逻辑，重点关注：

- `spExitScheduler` 是否正常初始化
- `QuerySpExit` 是否能正常返回退出/迁移计划
- secondary GVG 是否能从链上被正确恢复并纳入退出计划
- `sg-sp0` 是否仍停留在 `STATUS_GRACEFUL_EXITING` 且长期无法清空 family
- 是否能够达到 `completeSpExit` 前置条件

### 7.2 验证前状态采集

在 `test-sp0` 升级完成后，先采集：

- `docker logs --tail=200 moca-sp0`
- `docker exec moca-sp0 moca-sp query.sp.exit --config /app/config.toml`
- 当前链上 `sg-sp0` 状态
- 当前 family / gvg 迁移状态

若 `sp-exit-plan.md` 中旧的 `sg-sp0` 退出上下文仍在链上延续，优先基于当前链上状态继续观察；不要盲目重复发起新的退出交易。

### 7.3 验证路径

分两种情况执行：

#### 情况 A：`sg-sp0` 仍处于既有退出流程中

- 观察 `query.sp.exit` 返回的迁移任务是否开始正常推进
- 轮询 family / gvg 迁移状态
- 一旦满足条件，执行：
  - `docker exec moca-sp0 moca-sp completeSpExit --config /app/config.toml`
- 再验证链上已移除或状态已进入预期终态

#### 情况 B：旧流程已失效或需重新触发

- 重新参考 `tasks/sp-exit/sp-exit-plan.md`
- 按原单节点脚本路径先做 `sg-sp0` 金丝雀：
  - `spExit`
  - 等待进入退出中状态
  - 观察迁移推进
  - `completeSpExit`

### 7.4 成功判定

满足以下任一组证据，可判定 PR #24 修复有效：

- `query.sp.exit` 正常返回有效任务，迁移开始推进，最终可完成 `completeSpExit`
- 或虽然未在窗口内完成全部迁移，但相比 `rc5` 已能观察到 scheduler 正常启动、退出任务已被正确接管和推进

### 7.5 失败判定

若出现以下任一情况，应判定“问题未确认修复”并停止推进：

- `query.sp.exit` 仍报 `spExitScheduler not exit` 或等价初始化失败
- `sg-sp0` 长时间无迁移推进，日志显示 scheduler 未工作
- 升级后出现新的阻塞，导致 `spExit` / `completeSpExit` 无法执行

---

## Phase 5. 回滚与止损

### 8.1 回滚条件

满足以下任一条件立即暂停并评估回滚：

- `test-sp0` 在 `rc6` 启动失败或持续不健康
- `spExit` 相关功能相比 `rc5` 明显退化
- 其余 SP 出现批量启动异常

### 8.2 回滚方式

将 `/data/moca/compose-sp.yaml` 的镜像恢复到：

- `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5`

然后执行：

```bash
docker compose -f /data/moca/compose-sp.yaml pull sp
docker compose -f /data/moca/compose-sp.yaml up -d sp
```

若使用了专用升级脚本，也应同步准备 `rc6 -> rc5` 的回滚模板。

---

## 9. 风险与关注点

- `main` 当前已不只包含 PR #24，还包含 `#25`、`#26`，因此本次验证结论是“latest main + PR #24 在内的一组改动”共同作用下的结果，不是 PR #24 单独隔离实验
- `sg-sp0` 若仍挂着旧退出流程，验证时需避免误发第二次退出交易
- 迁移耗时具有不确定性，验证窗口需要预留足够观察时间
- `rc5` 升级时暴露过权限、healthcheck、日志目录冲突、磁盘空间问题，本次仍需逐台复核

---

## 10. 产出物

执行完成后应回写：

- 本文档补充执行记录与结论
- 如有脚本变更，新增或更新 `tasks/sp-upgrade-v1.20-rc6/upgrade-sp-image.sh`
- 如问题已解决，更新 `tasks/sp-exit/sp-exit-plan.md` 的当前状态
- 如问题未解决，新增故障记录文档，沉淀日志、链上状态、容器状态和下一步假设

---

## 10.1 后续优化记录

本次执行过程中额外观察到 `moca-storage-provider` 发布链路有可优化点，暂不在本任务内处理，后续单独跟进：

- 当前 `.github/workflows/go-releaser.yml` 在正式 tag 发布时先执行一次 `make release-dry-run`，再执行一次 `make release`
- 从实际运行时间看，这两步都在做一整轮 goreleaser 构建，耗时接近翻倍
- 当前更值得优先做的优化不是强行让 release artifact 和 GHCR image“完全并行”，而是：
  - PR / 分支保留 dry-run workflow
  - 正式 tag 发布仅执行一次 `make release`
- 若后续还要进一步提速，再考虑把 binary build、docker amd64/arm64、manifest/release 拆成多 job 并行

---

## 11. 建议的实际执行顺序

1. 拉取 `moca-storage-provider` 最新 `main`
2. 直接发布 `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7`
3. 先升级 `test-sp0`
4. 在 `test-sp0` 上验证 `sg-sp0` 退出问题
5. `test-sp0` 验证通过后，再滚动升级其余 5 台
6. 完成全量健康检查和结果沉淀

---

## 12. 待执行前最终确认

执行前建议再次确认以下 4 项：

- GHCR 发布凭据可用
- 6 台 testnet SP 的 SSH 连通性正常
- 当前 `sg-sp0` 链上状态已重新采样
- 维护窗口允许在 `test-sp0` 上先做金丝雀和较长时间观察

---

## 13. 执行记录

### 13.1 历史背景：`rc6` 发布

- 发布时间：2026-04-22
- 发布方式：`mocachain/moca-storage-provider` tag `v1.2.0-rc6` 触发 `goreleaser`
- 发布基线 commit：`f17aa932532ed63c69f93de61174028e648fcb1a`
- 正式发布 run：`24758498511`
- 镜像已可在远端主机拉取：
  - `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- 在 `test-sp0` 上实拉 digest：
  - `sha256:6f3ec0f28651178114b0465777aad643c9100c756173a52277ce37804e83315c`

### 13.2 历史背景：Testnet 滚动升级到 `rc6`

执行时间：2026-04-22

| SSH 别名 | 容器名 | 升级后镜像 | 状态 |
| --- | --- | --- | --- |
| `test-sp0` | `moca-sp0` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` | healthy |
| `test-sp1` | `moca-sp1` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` | healthy |
| `test-sp2` | `moca-sp2` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` | healthy |
| `test-sp3` | `moca-sp3` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` | healthy |
| `test-sp4` | `moca-sp4` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` | healthy |
| `test-sp5` | `moca-sp5` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` | healthy |

升级方式：

- `test-sp0` 先金丝雀升级
- `test-sp1` ~ `test-sp5` 并行滚动升级
- 全部节点继续沿用 `rc5` 已验证的 compose 兼容写法：
  - `command: --config config.toml --log.std`
  - `healthcheck: ["CMD-SHELL", "bash -c 'echo > /dev/tcp/127.0.0.1/9033'"]`

### 13.3 历史背景：`sg-sp0` 在 `rc6` 上的复测结论

升级前，在 `test-sp0` 上执行：

```bash
docker exec moca-sp0 moca-sp query.sp.exit --config /app/config.toml
```

返回：

- `rpc error: code = Unknown desc = spExitScheduler not exit`

升级到 `1.2.0-rc6` 后，在同一节点执行同一命令，返回：

```json
{"self_sp_id":1}
```

同时在 `moca-sp0` 日志中观察到：

- `manager/sp_exit_scheduler.go:347 loop subscribe sp exit event`
- `manager/sp_exit_scheduler.go:404 loop subscribe swap out event`
- `manager/sp_exit_scheduler.go:332 sp exit subscribe progress`
- `manager/sp_exit_scheduler.go:381 swap out subscribe progress`

这说明：

- PR #24 中“manager 启动时拉起 `spExitScheduler`”的修复已经在 testnet `rc6` 实例上生效
- `sg-sp0` 上导致 `query.sp.exit` 失败的直接问题已被修复

### 13.4 当前业务状态

- `sg-sp0` 当前链上状态仍为 `STATUS_GRACEFUL_EXITING`
- 本次验证确认的是：`rc6` 已修复 scheduler 未启动导致的 `query.sp.exit` / SP Exit 调度不可用问题
- 本次尚未完成 `sg-sp0 completeSpExit` 的最终收尾，需要在后续窗口继续观察当前退出流程是否随 scheduler 恢复而自然推进，或按 `sp-exit-plan.md` 继续执行收尾动作

### 13.5 本次结论

- `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` 已成功发布
- testnet 全部 6 台 SP 已成功升级到 `rc6`
- `sg-sp0` 上 `spExitScheduler not exit` 问题已确认修复
- `sg-sp0` 的完整退出流程还需要继续验证到 `completeSpExit`

### 13.6 `rc7` 发布与全量升级结果

- 发布时间：2026-04-23
- 发布方式：`mocachain/moca-storage-provider` tag `v1.2.0-rc7` 正式 `goreleaser`
- 发布基线 commit：`5fcf09fc958c08ea69762edc444de83f294b3d53`
- GitHub Release：
  - `https://github.com/mocachain/moca-storage-provider/releases/tag/v1.2.0-rc7`
- 镜像已可拉取：
  - `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7`
- 本地拉取验证 digest：
  - `sha256:9fdfe758674e441d099765dd07dfcc413d92f1ae0867de599e08a7f0a5ea680c`

升级时间：2026-04-23

| SSH 别名 | 容器名 | 升级后镜像 | 状态 |
| --- | --- | --- | --- |
| `test-sp0` | `moca-sp0` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` | healthy |
| `test-sp1` | `moca-sp1` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` | healthy |
| `test-sp2` | `moca-sp2` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` | healthy |
| `test-sp3` | `moca-sp3` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` | healthy |
| `test-sp4` | `moca-sp4` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` | healthy |
| `test-sp5` | `moca-sp5` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` | healthy |

### 13.7 `sg-sp0` 在 `rc7` 上的复测结果

在 `test-sp0` 上执行：

```bash
docker exec moca-sp0 moca-sp query.sp.exit --config /app/config.toml
```

返回：

```json
{"self_sp_id":1}
```

使用退出脚本重新采样链上状态：

- `sg-sp0` 当前状态仍为：`STATUS_GRACEFUL_EXITING`

在 `rc7` 上进一步验证：

```bash
docker exec moca-sp0 moca-sp query-gvg-by-sp --config /app/config.toml --targetSP 1
```

返回：

- `null`

说明：

- `sg-sp0` 当前已经没有 secondary GVG 残留

继续执行：

```bash
docker exec moca-sp0 moca-sp query-vgf-by-sp --config /app/config.toml --targetSP 1
```

返回：

```json
[{"id":4,"virtual_payment_address":"0x8D720138eC1f2006dbe283C9A0f6eCe4B5c2fF1e"}]
```

说明：

- `sg-sp0` 当前只剩 empty family `4`

在 `test-sp0` 上实际执行：

```bash
docker exec moca-sp0 moca-sp --config /app/config.toml sp.complete.exit --operatorAddress 0x3801382abca4d7a4886d106efC402F041ca40631
```

交易失败：

- tx hash：`0xa65f69711c60bb52cbf8cf7c07373407b10135db7c545d924a07a4e1fa5f3588`

### 13.8 `rc7` 验证结论

- PR #24 对应修复已生效：
  - `spExitScheduler` 已正常启动
  - `query.sp.exit` 可正常返回
- PR #27 / `moca-e2e` PR #30 对应修复已生效：
  - `sg-sp0` 当前已无 secondary GVG 残留
- `sg-sp0` 仍不能最终退出
- 当前剩余阻塞点已收敛为：
  - empty family `4` 仍归属 `sg-sp0`
  - `completeSpExit` 仍会被链上拒绝

因此，本次最终结论是：

- `1.2.0-rc7` 已经解决 PR #24 / PR #27 这两条 SP 服务侧问题
- 但它还不能单独让 `sg-sp0` 完成最终退出
- 如果目标是让 `sg-sp0` 真正从 SP 列表移除，仍需继续处理 empty family `4`

### 13.9 `us-sp0` 退出计划未自动生成的现场发现

在继续验证 `us-sp0` 退出时，链上已经成功进入退出状态：

- SP：`us-sp0`
- SP ID：`4`
- operator：`0xDb50898D46ca07758B8082379c6e7e79d9603bE8`
- 状态：`STATUS_GRACEFUL_EXITING`
- 退出 tx：`0x1e8e97acd0bff966b7bef1a332fbca5e366949bc3d3a31409c0b459845c7d33c`
- 退出 tx 所在区块：`19305318`

但在 `test-sp3` / `moca-sp3` 上执行：

```bash
docker exec moca-sp3 moca-sp query.sp.exit --config /app/config.toml
```

返回：

```json
{"self_sp_id":4}
```

也就是说，`spExitScheduler` 本身已经存在并可查询，但没有返回 `swap_out_src` / `swap_out_dest` 等退出迁移计划。

进一步查看 `moca-sp3` 日志，持续观察到：

```text
record not found
loop subscribe sp exit event sp_exit_events=""
loop subscribe swap out event swap_out_events=null
sp exit subscribe progress last_subscribed_block_height=1081413
```

同时，容器本地 blocksyncer 仍在处理明显落后的区块：

```text
processing block height=13593506
fetch data start:13593508 end:13593517
```

而链上最新高度已经在 `19306330` 附近，退出 tx 位于 `19305318`。因此，当前现象不是 `spExitScheduler` 没有启动，而是：

1. `us-sp0` 链上已经是 `STATUS_GRACEFUL_EXITING`
2. `us-sp0` 本地 blocksyncer / metadata DB 尚未同步到退出 tx 所在区块
3. `spExitScheduler` 的自动计划生成依赖本地 metadata DB 中的 `StorageProviderExit` 事件
4. 因为本地 DB 查不到该事件，`ListSpExitEvents` 返回空，`produceSwapOutPlan(false)` 没有被触发

对应代码路径：

- `modular/manager/sp_exit_scheduler.go`
  - `subscribeEvents()` 轮询 `ListSpExitEvents`
  - 只有当 `spExitEvents.Event != nil` 时，才会调用 `produceSwapOutPlan(false)` 生成退出迁移计划
- `store/bsdb/event_sp_exit.go`
  - `ListSpExitEvents()` 从本地 metadata DB 查询 `event_sp_exit`
  - 当前本地 DB 返回 `record not found`

因此，本次新增发现是：

- PR #24 已修复“scheduler 未启动”的问题
- PR #27 已修复“secondary GVG 只能依赖本地 metadata DB 推导”的问题
- 但当前仍存在一个新的恢复能力缺口：
  - 如果 SP 已经在链上进入 `GRACEFUL_EXITING`
  - 但本地 blocksyncer 落后或错过了历史 `StorageProviderExit` 事件
  - scheduler 不会仅凭链上 SP 状态自动重建退出计划

短期操作结论：

- 对 `us-sp0`，不能等待自动退出计划自然推进
- 需要继续按链上 family / GVG 状态手动执行 `swapIn` / `recover-vgf` / `completeSwapIn`
- 待 `primary_count=0` 且 `secondary_count=0` 后，再执行 `sp.complete.exit`

后续代码修复建议：

- `spExitScheduler` 启动或周期轮询时，应补充链上状态兜底检查
- 当发现 `selfSP.status == STATUS_GRACEFUL_EXITING` 且当前没有本地 swap-out plan 时，应允许从链上 family / secondary GVG 状态重建退出计划
- 这样即使本地 metadata DB 没有捕获到历史 `StorageProviderExit` 事件，也能恢复退出调度

### 13.10 `us-sp2` 退出执行记录（仅完成声明退出，未完成手工收尾）

2026-04-24 在 `test-sp5` / `moca-sp5` 上执行：

```bash
docker exec moca-sp5 moca-sp spExit --config /app/config.toml
```

返回：

- tx hash：`0x59e424db89548a53ccb7584d8757ccb1b46df8032cfe78fe7d87765e2659c864`

链上随后确认：

- SP：`us-sp2`
- SP ID：`6`
- operator：`0x516c01a2e8C36ecC23739987412Ec0Fe95bE0d52`
- 状态：`STATUS_GRACEFUL_EXITING`

同时采样当前 GVG 统计：

- `primary_count = 3`
- `secondary_count = 17`

本地 `query.sp.exit` 已可正常返回：

```bash
docker exec moca-sp5 moca-sp query.sp.exit --config /app/config.toml
```

返回：

```json
{"self_sp_id":6}
```

容器日志中也可看到 `spExitScheduler` 持续工作：

- `loop subscribe sp exit event`
- `loop subscribe swap out event`
- `sp exit subscribe progress`
- `swap out subscribe progress`

进一步按链上状态采样发现：

- `us-sp2` 当前 primary family 共 `3` 个：
  - empty family：`3`、`6`
  - 非 empty family：`32`、`33`、`34`
- `us-sp2` 当前作为 secondary 存在的 GVG 共 `17` 个
- 其中已确认至少包括：
  - `family_id = 7`, `gvg_id = 7`, `primary_sp_id = 2`, `secondary_sp_ids = [5, 6]`
  - `family_id = 8`, `gvg_id = 8`, `primary_sp_id = 2`, `secondary_sp_ids = [5, 6]`
  - `family_id = 9`, `gvg_id = 9`, `primary_sp_id = 2`, `secondary_sp_ids = [5, 6]`
  - `family_id = 12` ~ `24`, `28` 也存在相同模式

本次原计划尝试复用：

- `tasks/sp-exit/manual-complete-sp-exit.sh`

但现场执行后确认，本次无法继续完成手工迁移和 `completeSpExit`，原因不是脚本本身报错，而是当前可操作节点边界不足：

- 我方当前可操作的保留节点只有：
  - `sg-sp1`（SP `2`）
  - `us-sp1`（SP `5`）
- 我方无法登录和操作：
  - `sp0`（SP `7`）
  - `sp1`（SP `8`）
  - `sp2`（SP `9`）

这会直接导致 `manual-complete-sp-exit.sh` 无法为 `us-sp2` 选择可行 successor：

- 不能选 `sg-sp1`（SP `2`）
  - 因为 `us-sp2` 当前大量 secondary GVG 的 primary 已经是 `2`
  - 脚本在 secondary GVG 迁移时要求 successor 不能同时是该 GVG 的 primary
- 不能选 `us-sp1`（SP `5`）
  - 因为这些 GVG 的 `secondary_sp_ids` 已经包含 `5`
  - 脚本同样要求 successor 不能已存在于该 GVG 的 secondary 列表中

因此，本次关于 `us-sp2` 的执行结论是：

- `spExit` 已成功发出，`us-sp2` 已进入 `STATUS_GRACEFUL_EXITING`
- `spExitScheduler` 已正常启动，`query.sp.exit` 可正常返回
- 在“只能操作 `sg-sp1` / `us-sp1`、不能登录 `sp0` / `sp1` / `sp2`”的前提下，当前无法继续完成手工迁移和 `completeSpExit`
- 若要真正完成 `us-sp2` 退出，需要额外协调一个不与现有 primary / secondary 关系冲突、且具备实际操作入口的 successor SP

## Related
- [[SP Upgrade Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
- [[testnet-sp-storage-provider-image-upgrade-and-sp-exit-validation-plan-en|testnet-sp-storage-provider-image-upgrade-and-sp-exit-validation-plan-en]]
