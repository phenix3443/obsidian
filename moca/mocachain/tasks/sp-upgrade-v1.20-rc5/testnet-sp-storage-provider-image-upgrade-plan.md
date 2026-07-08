---
title: "Testnet 存储节点 SP 镜像替换执行计划"
aliases:
  - testnet-sp-storage-provider-image-upgrade-plan
tags:
  - mocachain
  - task
  - sp-upgrade
  - zh
  - sp-upgrade-v1.20-rc5
  - storage-provider
type: "task-note"
status: "archived"
area: "tasks"
topic: "sp-upgrade"
language: "zh-CN"
source_path: "tasks/sp-upgrade-v1.20-rc5/testnet-sp-storage-provider-image-upgrade-plan.md"
---

> [!summary]
> 该任务笔记已适配为 Obsidian 文档，归类到 SP Upgrade，并补齐索引与语言导航。

## Navigation
- [[Tasks Index]]
- [[SP Upgrade Index]]
- [[Topic Index]]
- [[Language Index]]

---

# Testnet 存储节点 SP 镜像替换执行计划

本文档说明如何在 testnet 各 SP 节点上将 Storage Provider 容器镜像由 `zkmelabs/moca-storage-provider:v1.0.0-alpha.1` 替换为 `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5`，含现场核验记录、命令模板、检查清单与回滚。

---

## 1. 验证结论

### 1.1 镜像与制品

| 项目 | 状态 | 说明 |
|------|------|------|
| 目标镜像 `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5` | 已核对 | [GitHub Packages：moca-storage-provider](https://github.com/mocachain/moca-storage-provider/pkgs/container/moca-storage-provider) 显示该 tag 存在且为 Public，可 `docker pull`。 |
| 旧镜像 `zkmelabs/moca-storage-provider:v1.0.0-alpha.1` | 全部已替换 | 6 节点均已从此镜像升级至目标镜像。 |

### 1.2 SSH 清单（与本地 `~/.ssh/config.d/zkme-testnet.sconf` 一致）

| SSH 别名 | 用户 | HostName |
|----------|------|----------|
| test-sp0 | root | 172.237.72.112 |
| test-sp1 | root | 172.237.72.132 |
| test-sp2 | root | 172.237.72.135 |
| test-sp3 | root | 173.255.228.82 |
| test-sp4 | root | 173.255.228.112 |
| test-sp5 | root | 173.255.228.122 |

### 1.3 与测试网 SP 域名的对应关系（参考）

详见仓库内 [tech-asserssment/storage-provider-registration/SP_Testnet_Analysis.md](../tech-asserssment/storage-provider-registration/SP_Testnet_Analysis.md)。现场观测到的 hostname 与容器命名如下表「主机名 / 容器名」列。

---

## 2. 现场核验记录表

**核验说明**：下列结果由自动化 SSH 在 **2026-04-10** 采集，全部 6 节点已核验并升级完成。

| SSH 别名 | 主机名（hostname） | SP 容器名 | 运行中镜像 | Compose 项目 | Compose 文件路径 | 核验状态 |
|----------|-------------------|-----------|------------|--------------|------------------|----------|
| test-sp0 | sg-sp-full-node-0 | moca-sp0 | ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5 | moca | /data/moca/compose-sp.yaml | 已核验 |
| test-sp1 | sg-sp-full-node-1 | moca-sp1 | ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5 | moca | /data/moca/compose-sp.yaml | 已核验 |
| test-sp2 | sg-sp-full-node-2 | moca-sp2 | ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5 | moca | /data/moca/compose-sp.yaml | 已核验 |
| test-sp3 | us-sp-full-node-0 | moca-sp3 | ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5 | moca | /data/moca/compose-sp.yaml | 已核验 |
| test-sp4 | us-sp-full-node-1 | moca-sp4 | ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5 | moca | /data/moca/compose-sp.yaml | 已核验 |
| test-sp5 | us-sp-full-node-2 | moca-sp5 | ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5 | moca | /data/moca/compose-sp.yaml | 已核验 |

**IaC / 配置源路径（现场已确认，便于与 Git 对齐）**

| 字段 | 值 |
|------|-----|
| Compose 文件（全部节点一致） | `/data/moca/compose-sp.yaml` |
| Compose 服务名（`docker compose … up -d` 使用） | `sp`（同文件另有 `nginx_proxy`、`node_exporter`） |
| 存储 Provider `image` 行（升级后） | 约第 4 行：`image: "ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5"` |
| 升级脚本 | [`mocachain/upgrade-sp-image.sh`](upgrade-sp-image.sh) |

---

## 3. 命令模板（每台主机执行前请替换 `<host>`）

### 3.1 连接与发现

```bash
ssh <host>   # 例如：ssh test-sp0

hostname
docker compose -f /data/moca/compose-sp.yaml ls
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
docker inspect moca-sp0 --format '{{.Config.Image}}'   # 容器名按实际上表替换为 moca-sp0 … moca-sp5
grep -n 'image:' /data/moca/compose-sp.yaml
```

### 3.2 升级前备份

```bash
cp -a /data/moca/compose-sp.yaml "/data/moca/compose-sp.yaml.bak.$(date +%Y%m%d%H%M%S)"
docker inspect "$(docker ps -q -f name=moca-sp)" --format '{{.Image}}@{{.Id}}' >> /tmp/sp-image-pre-upgrade.txt
```

（若一台机上容器名固定，可将 `name=moca-sp` 改为具体名如 `moca-sp0`。）

### 3.3 修改镜像并滚动更新（Docker Compose v2）

在 `/data/moca/compose-sp.yaml` 中将 Storage Provider 的 `image` 改为：

`ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5`

然后（**test-sp0 上已确认** Storage Provider 对应 compose **服务名为 `sp`**，与容器名 `moca-sp0` 等不同）：

```bash
cd /data/moca
docker compose -f /data/moca/compose-sp.yaml pull sp
docker compose -f /data/moca/compose-sp.yaml up -d sp
```

若其他主机命名不一致，先执行：

```bash
docker compose -f /data/moca/compose-sp.yaml config --services
```

### 3.4 升级后快速检查

```bash
docker ps --filter name=moca-sp --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
docker compose -f /data/moca/compose-sp.yaml logs --tail=100 sp
```

对外端点可按 [SP_Testnet_Analysis.md](../tech-asserssment/storage-provider-registration/SP_Testnet_Analysis.md) 中 `testnet-sg-sp*` / `testnet-us-sp*` 做 HTTPS 与业务探活。

### 3.5 GHCR 鉴权（仅当镜像变为私有时）

```bash
docker login ghcr.io
```

当前该 tag 为 Public，一般无需登录。

---

## 4. 建议执行流程

### 4.1 事前准备

- [x] 确认本机可 `ssh test-sp0` … `ssh test-sp5`（`test-sp4`/`test-sp5` 曾超时，后续窗口恢复）。
- [x] 约定维护窗口；SP 重启可能影响对象上传/下载。
- [x] 确认节点架构与镜像一致（均为 `linux/amd64`）。

### 4.2 每台主机：先核验再替换

- [x] 使用 §3.1 确认容器镜像与 compose 中 `image` 一致。
- [x] 仅当确认为 `zkmelabs/moca-storage-provider:v1.0.0-alpha.1` 时，再修改并 `pull` + `up -d`。
- [x] **金丝雀**：先在 `test-sp0` 完成 §3.3–3.4，再推广到其余节点。

### 4.3 升级后验证

- [x] 容器 `healthy` / 日志无持续 panic。
- [ ] 对应公网端点 TLS 与业务探活。
- [ ] 按需执行链上/CLI 读路径或小额写入测试（按内部规范）。

### 4.4 文档与配置同步

- [ ] 若 `/data/moca/compose-sp.yaml` 由 Git 或 Ansible 下发，在源仓库提交相同镜像变更，避免下次部署被覆盖。

### 4.5 一键升级脚本

升级步骤已封装为可复用脚本 [`upgrade-sp-image.sh`](upgrade-sp-image.sh)，用法：

```bash
ssh test-spN 'bash -s' < mocachain/upgrade-sp-image.sh
ssh test-spN 'bash -s -- -c' < mocachain/upgrade-sp-image.sh   # 加 -c 清理旧日志
ssh test-spN 'bash -s -- -n <new_image>' < mocachain/upgrade-sp-image.sh  # 自定义目标镜像
```

---

## 5. 回滚

1. 将 `/data/moca/compose-sp.yaml` 中 SP 的 `image` 恢复为 `zkmelabs/moca-storage-provider:v1.0.0-alpha.1`（或使用备份文件还原）。
2. 执行：

```bash
docker compose -f /data/moca/compose-sp.yaml pull sp
docker compose -f /data/moca/compose-sp.yaml up -d sp
```

3. 若曾记录 digest，也可固定为 digest 回滚。

---

## 6. 风险与注意点

- **版本跨度大**：`v1.0.0-alpha.1` → `1.2.0-rc5` 存在以下已知兼容性变化（均已在升级脚本中处理）：
  - 新镜像以非 root 用户 `sp`（uid 1000）运行，需 `chown` 数据卷。
  - 新镜像设置了 `ENTRYPOINT=[moca-sp]`，compose `command` 不能再包含 `moca-sp` 前缀。
  - SP 主日志与 Juno blocksyncer 对 `[Log] Path` 用途冲突，需用 `--log.std` 禁用文件日志。
  - 新镜像不含 `curl`，healthcheck 需改用 `bash /dev/tcp`。
- **磁盘空间**：旧版可能积累数百 GB 日志文件（`moca-sp.log.*`），升级前检查 `df -h`，必要时清理。
- **多服务 Compose**：同一文件含 `nginx_proxy`、`node_exporter` 等，升级时仅针对 `sp` 服务，避免误重启无关服务。

---

## 7. 流程图（概览）

```mermaid
flowchart LR
  preflight[Preflight_SSH_and_window]
  discover[Per_host_discover_compose_or_unit]
  verify[Verify_current_image_string]
  change[Update_image_to_GHCR_rc5]
  validate[Validate_container_and_endpoint]
  rollback[Rollback_if_needed]
  preflight --> discover --> verify --> change --> validate
  validate -->|fail| rollback
```

---

## 8. 修订记录

| 日期 | 说明 |
|------|------|
| 2026-04-10 | 初版：写入执行步骤；完成 test-sp0–3 现场核验；compose 路径与镜像行确认；test-sp4/5 待补。 |
| 2026-04-10 | 见 §9：test-sp0–3 升级至 1.2.0-rc5 完成（healthy）；test-sp4/5 SSH 超时待补。 |
| 2026-04-10 | test-sp5 升级完成（healthy）；test-sp4 仍 SSH 超时。 |
| 2026-04-10 | test-sp4 升级完成（healthy）。全部 6 节点升级完毕。 |

---

## 9. 执行记录（2026-04-10）

### 9.1 金丝雀阶段（test-sp0）

在 test-sp0 上依次遇到并解决了 **3 个兼容性问题**：

| 问题 | 根因 | 修复 |
|------|------|------|
| `permission denied: /app/moca-sp.log` | 新镜像默认 `USER=sp`（uid 1000），数据卷文件均为 root 属主 | `chown -R 1000:1000 /data/moca/spN` |
| `Error 1045: Access denied for user 'root'@'localhost'` | 新镜像 `ENTRYPOINT=[moca-sp]`，而旧镜像 `Entrypoint=[]`；compose `command: moca-sp --config config.toml` 拼接后变为 `moca-sp moca-sp --config ...`，`--config` 未被解析，程序用默认 DSN（root@localhost）连库 | compose `command` 改为 `--config config.toml`（去掉 `moca-sp` 前缀） |
| `stat moca-sp.log/10.10.0.8: not a directory` | SP 主日志系统将 `[Log] Path` 创建为**文件符号链接**，而 Juno blocksyncer 将同一路径作为**目录根**来创建子目录 `<nodeIP>/`，两者冲突 | compose command 追加 `--log.std` 禁用文件日志（Docker stdout 已捕获），使 `[Log] Path` 不被占用 |
| healthcheck 显示 `unhealthy` | 新镜像不含 `curl`；原 healthcheck 用 `curl -f` | healthcheck 改为 `bash -c 'echo > /dev/tcp/127.0.0.1/9033'` |

### 9.2 滚动升级（test-sp1–3）

test-sp0 金丝雀验证通过后，对 test-sp1、test-sp2、test-sp3 批量执行相同变更。

- **test-sp3** 首次启动时因 **磁盘 100% 满**（旧版遗留 293 GB 日志文件）panic，清理 `moca-sp.log.*` 后恢复。

### 9.3 最终状态

| SSH 别名 | 镜像 | 状态 | 备注 |
|----------|------|------|------|
| test-sp0 | ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5 | **healthy** | 金丝雀节点 |
| test-sp1 | ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5 | **healthy** | |
| test-sp2 | ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5 | **healthy** | |
| test-sp3 | ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5 | **healthy** | 清理旧日志后恢复 |
| test-sp4 | ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5 | **healthy** | 2026-04-10 第三次窗口完成 |
| test-sp5 | ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5 | **healthy** | 2026-04-10 第二次窗口完成 |

### 9.4 test-sp4 升级记录

2026-04-10 第三次窗口 SSH 恢复后执行，与 test-sp0–3/5 相同变更流程：chown 数据卷 → 修改 compose（image/command/healthcheck）→ pull → up -d。一次通过，无额外问题。

### 9.5 各节点 compose 变更差异汇总

对比升级前后，每台机器 `compose-sp.yaml` 的变化（以 test-sp0 为例，其余同理）：

```diff
-    image: "zkmelabs/moca-storage-provider:v1.0.0-alpha.1"
+    image: "ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5"
-    command: moca-sp --config config.toml
+    command: --config config.toml --log.std
-      test: ["CMD", "curl", "-f", "http://localhost:9033/health"]
+      test: ["CMD-SHELL", "bash -c 'echo > /dev/tcp/127.0.0.1/9033'"]
```

## Related
- [[SP Upgrade Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
