---
title: "Testnet SP RC7 Upgrade And sg-sp0 Exit Validation Plan"
aliases:
  - testnet-sp-storage-provider-image-upgrade-and-sp-exit-validation-plan-en
  - Testnet SP Upgrade to `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` and `sg-sp0` Exit Fix Validation Plan
tags:
  - mocachain
  - task
  - sp-upgrade
  - en
  - sp-upgrade-v1.20-rc6
  - storage-provider
type: "task-note"
status: "archived"
area: "tasks"
topic: "sp-upgrade"
language: "en"
source_path: "tasks/sp-upgrade-v1.20-rc6/testnet-sp-storage-provider-image-upgrade-and-sp-exit-validation-plan-en.md"
---

> [!summary]
> This task note is adapted for Obsidian under SP Upgrade, with topic and language navigation links added.

## Navigation
- [[Tasks Index]]
- [[SP Upgrade Index]]
- [[Topic Index]]
- [[Language Index]]
- [[testnet-sp-storage-provider-image-upgrade-and-sp-exit-validation-plan|testnet-sp-storage-provider-image-upgrade-and-sp-exit-validation-plan]]


# Testnet SP RC7 Upgrade And sg-sp0 Exit Validation Plan

---

# Testnet SP Upgrade to `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` and `sg-sp0` Exit Fix Validation Plan

This document plans and records the following work:

1. Build and publish `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` from the latest `main` branch of `moca-storage-provider`.
2. Upgrade all 6 testnet SP nodes from `rc6` to `rc7`, following the validated procedure in `tasks/sp-upgrade-v1.20-rc5/testnet-sp-storage-provider-image-upgrade-plan.md`.
3. Re-test the `sg-sp0` exit issue described in `tasks/sp-exit/sp-exit-plan.md`, and verify whether the PR #24 / PR #27 fixes are effective.

---

## 1. Confirmed Facts

### 1.1 Code Baseline

- Local repository: `/Users/liushangliang/github/mocachain/moca-storage-provider`
- Current `main` branch HEAD: `5fcf09fc958c08ea69762edc444de83f294b3d53`
- Recent key commits on `main`:
  - `5fcf09f` `fix(manager): derive SP exit secondary GVGs from chain (#27)`
  - `f17aa93` `chore: remove dead code and stabilize CI baseline (#26)`
  - `3ebe4ed` `Merge pull request #24 from mocachain/fix/sp-exit-scheduler-startup`
  - `e4284bd` `v1.2.0-rc5`

### 1.2 Fixes Relevant to This Validation

Core changes from PR #24 are in:

- `modular/manager/manager.go`
- `modular/manager/manager_test.go`

Fix summary:

- `ManageModular.delayStartMigrateScheduler()` no longer starts only `bucketMigrateScheduler`.
- The manager now also starts `spExitScheduler` during startup.
- Tests were added to cover that `QuerySpExit()` can return normally after delayed startup.

Core changes from PR #27 are in:

- `modular/manager/sp_exit_scheduler.go`
- `modular/manager/sp_exit_scheduler_test.go`

Fix summary:

- `SPExitScheduler.produceSwapOutPlan()` no longer depends on the local metadata DB to derive secondary GVGs.
- The exit plan restores secondary GVGs from chain state, then generates swap-out plans.
- The corresponding `moca-e2e` PR #30 added secondary GVG coverage and verified final complete exit.

These fixes are directly related to the symptom in `sp-exit-plan.md`: `sg-sp0` had entered `STATUS_GRACEFUL_EXITING` but could not continue to complete exit. This is the key validation target for this task.

### 1.3 Current Testnet SP Baseline

According to the existing `rc6` upgrade record, the 6 testnet SP nodes currently run:

- `test-sp0` -> `moca-sp0` -> `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- `test-sp1` -> `moca-sp1` -> `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- `test-sp2` -> `moca-sp2` -> `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- `test-sp3` -> `moca-sp3` -> `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- `test-sp4` -> `moca-sp4` -> `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- `test-sp5` -> `moca-sp5` -> `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`

Existing SSH aliases:

- `test-sp0` `172.237.72.112`
- `test-sp1` `172.237.72.132`
- `test-sp2` `172.237.72.135`
- `test-sp3` `173.255.228.82`
- `test-sp4` `173.255.228.112`
- `test-sp5` `173.255.228.122`

---

## 2. Goals and Completion Criteria

### 2.1 Goals

- Produce a pullable image: `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7`.
- Upgrade all 6 testnet SP nodes from `1.2.0-rc6` to `1.2.0-rc7`.
- Re-validate whether the `sg-sp0` exit flow can progress to the point where `completeSpExit` is possible.
- Record upgrade and validation evidence, and confirm whether the issue has been fixed by PR #24 / PR #27.

### 2.2 Definition of Done

All of the following must be true:

1. The local `moca-storage-provider` baseline is confirmed to be `main` HEAD, and relevant checks are completed.
2. `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` can be pulled successfully.
3. All 6 testnet SP containers run `1.2.0-rc7` and are `healthy`.
4. A valid `sg-sp0` exit validation round is completed and documented:
   - If the issue is resolved, record evidence from exit declaration to final complete exit.
   - If the issue remains, record the new blocker, logs, and on-chain state.
5. Any script or documentation changes made during execution are written back to the repository.

---

## 3. Scope

### 3.1 In Scope

- Building and publishing the `moca-storage-provider` image.
- Rolling upgrade of the 6 testnet SP nodes.
- Re-testing the `sg-sp0` exit issue.
- Archiving required logs, on-chain state, and container state.

### 3.2 Out of Scope

- Upgrading non-testnet environments.
- Unrelated refactors outside this issue path.
- Unnecessary large-scale compose restructuring.

---

## 4. Execution Phases

## Phase 1. Publish the `1.2.0-rc7` Image

### 4.1 Pre-checks

Run the following in `/Users/liushangliang/github/mocachain/moca-storage-provider`:

- `git fetch origin`
- `git checkout main`
- `git pull --ff-only origin main`
- `git rev-parse HEAD`

Confirm that HEAD is still the expected commit. If `main` has moved forward, use the latest HEAD and write the actual commit into the execution record.

Confirm that the local working tree has no uncommitted changes that could pollute the release.

### 4.2 Local Validation

Recommended minimum checks:

- `make test`
- `make lint`
- If required by the release flow:
  - `make release-dry-run`

Notes:

- `Makefile` already provides `release` / `release-dry-run`.
- `.goreleaser.yml` defines multi-architecture publishing for `ghcr.io/mocachain/moca-storage-provider:{{ .Version }}`.
- `Dockerfile.release` still runs as the non-root `sp` user. Keep the compose compatibility changes already validated during `rc5`.

### 4.3 Release Action

Use the existing release flow:

- Prepare `.release-env`.
- Run the official release with version `1.2.0-rc7`.
- Validate after publishing:
  - `docker pull ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7`
  - If needed, validate `-amd64` / `-arm64` variants separately.

### 4.4 Release Evidence

Record at least:

- Actual release commit SHA.
- GHCR package link or successful `docker pull` result.
- Image digest.

Execution result:

- Actual release commit SHA: `5fcf09fc958c08ea69762edc444de83f294b3d53`
- GitHub Release: `https://github.com/mocachain/moca-storage-provider/releases/tag/v1.2.0-rc7`
- `docker pull ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` succeeded.
- Image digest:
  - `ghcr.io/mocachain/moca-storage-provider@sha256:9fdfe758674e441d099765dd07dfcc413d92f1ae0867de599e08a7f0a5ea680c`

---

## Phase 2. Prepare Upgrade Script and Operation Template

### 5.1 Reuse `rc5` Experience

Reuse the compatibility handling validated in `tasks/sp-upgrade-v1.20-rc5/testnet-sp-storage-provider-image-upgrade-plan.md`:

- `chown -R 1000:1000` for data volumes.
- Remove the `moca-sp` prefix from compose `command`, while preserving `--log.std`.
- Use `bash /dev/tcp` for healthcheck.
- Rolling restart only the `sp` service.

### 5.2 Required Adjustments for This Run

Copy the existing script and create an `rc6`-specific version, for example:

- `tasks/sp-upgrade-v1.20-rc6/upgrade-sp-image.sh`

Only make minimal changes:

- `OLD_IMAGE`: `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- `NEW_IMAGE`: `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7`

If the live compose file is already in the compatible format, keep the script idempotent and avoid breaking the existing configuration.

### 5.3 Pre-upgrade Checklist

Before running on each host, confirm:

- `docker ps` shows the currently running image is `1.2.0-rc6`.
- `/data/moca/compose-sp.yaml` exists.
- `docker compose -f /data/moca/compose-sp.yaml config --services` includes `sp`.
- `df -h` shows enough free disk space.
- If historical logs are too large, clean `moca-sp.log.*` as needed.

---

## Phase 3. Rolling Upgrade Testnet to `rc7`

### 6.1 Recommended Order

1. `test-sp0`
2. `test-sp1`
3. `test-sp2`
4. `test-sp3`
5. `test-sp4`
6. `test-sp5`

Rationale:

- `test-sp0` corresponds to `sg-sp0`; it is both the affected node and the key canary.
- Validate behavior on the affected node first, then proceed to the remaining nodes.

### 6.2 Per-host Steps

Run the same steps on each host:

1. Back up `/data/moca/compose-sp.yaml`.
2. Change the image from `1.2.0-rc6` to `1.2.0-rc7`.
3. Confirm `command` and `healthcheck` still use the compatibility format validated during `rc5`.
4. `docker compose pull sp`
5. `docker compose up -d sp`
6. Wait for healthcheck.
7. Check logs for continuous panic / configuration errors / DB connection errors.

### 6.3 Per-host Acceptance

Confirm at least:

- `docker inspect <container>` shows image `1.2.0-rc7`.
- Container status is `healthy`.
- The latest 100 log lines do not show continuous errors.
- Management interface and basic readiness checks recover.

### 6.4 Batch Control

- Continue to `test-sp1` ~ `test-sp5` only after `test-sp0` passes.
- If `test-sp0` has startup errors, scheduler initialization errors, or secondary GVG migration plan issues after upgrade, pause the full rollout.

---

## Phase 4. Validate the `sg-sp0` Exit Issue

### 7.1 Validation Goal

After PR #24 / PR #27 fixes, verify whether `sg-sp0` on `rc7` can correctly progress through SP Exit scheduling. Focus on:

- Whether `spExitScheduler` initializes correctly.
- Whether `QuerySpExit` returns the exit / migration plan normally.
- Whether secondary GVGs are correctly restored from chain state and included in the exit plan.
- Whether `sg-sp0` still remains stuck in `STATUS_GRACEFUL_EXITING` without clearing family state.
- Whether the `completeSpExit` prerequisites can be reached.

### 7.2 Pre-validation State Collection

After `test-sp0` is upgraded, collect:

- `docker logs --tail=200 moca-sp0`
- `docker exec moca-sp0 moca-sp query.sp.exit --config /app/config.toml`
- Current on-chain `sg-sp0` status
- Current family / GVG migration state

If the old `sg-sp0` exit context from `sp-exit-plan.md` is still active on-chain, continue observation from the current on-chain state. Do not blindly send a new exit transaction.

### 7.3 Validation Paths

Use one of the following paths.

#### Case A: `sg-sp0` Is Still in the Existing Exit Flow

- Observe whether `query.sp.exit` returns migration tasks and whether they start progressing.
- Poll family / GVG migration state.
- Once conditions are met, execute:
  - `docker exec moca-sp0 moca-sp completeSpExit --config /app/config.toml`
- Verify that the SP is removed on-chain or reaches the expected terminal state.

#### Case B: The Old Flow Is Invalid or Must Be Re-triggered

- Refer to `tasks/sp-exit/sp-exit-plan.md`.
- Run the original single-node canary path for `sg-sp0`:
  - `spExit`
  - Wait for exiting status.
  - Observe migration progress.
  - `completeSpExit`

### 7.4 Success Criteria

Any of the following evidence is enough to confirm that PR #24 is effective:

- `query.sp.exit` returns valid tasks, migration starts progressing, and `completeSpExit` can eventually complete.
- Or, even if all migration does not complete within the observation window, scheduler startup is confirmed and exit tasks are correctly accepted and progressing compared with `rc5`.

### 7.5 Failure Criteria

If any of the following occurs, mark the issue as not confirmed fixed and stop further rollout:

- `query.sp.exit` still reports `spExitScheduler not exit` or an equivalent initialization failure.
- `sg-sp0` shows no migration progress for a long time, and logs indicate the scheduler is not working.
- A new blocker appears after upgrade, preventing `spExit` / `completeSpExit` from running.

---

## Phase 5. Rollback and Risk Control

### 8.1 Rollback Conditions

Pause immediately and evaluate rollback if any of the following occurs:

- `test-sp0` fails to start or remains unhealthy on `rc6` / `rc7`.
- `spExit` functionality clearly regresses compared with `rc5`.
- Multiple SPs fail to start during rollout.

### 8.2 Rollback Method

Restore the image in `/data/moca/compose-sp.yaml` to:

- `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5`

Then run:

```bash
docker compose -f /data/moca/compose-sp.yaml pull sp
docker compose -f /data/moca/compose-sp.yaml up -d sp
```

If using the dedicated upgrade script, also prepare an `rc6 -> rc5` rollback template.

---

## 9. Risks and Watch Points

- Current `main` includes more than PR #24; it also includes `#25` and `#26`. Therefore, this validation result reflects the combined effect of latest `main` including PR #24, not an isolated PR #24-only experiment.
- If `sg-sp0` still has an old exit flow on-chain, avoid sending a duplicate exit transaction.
- Migration duration is uncertain; reserve enough observation time.
- During the `rc5` upgrade, issues were found around permissions, healthcheck, log directory conflicts, and disk space. Re-check these per host.

---

## 10. Deliverables

After execution, write back:

- This document with execution records and conclusions.
- Any script changes, such as new or updated `tasks/sp-upgrade-v1.20-rc6/upgrade-sp-image.sh`.
- If the issue is resolved, update the current status in `tasks/sp-exit/sp-exit-plan.md`.
- If the issue is not resolved, create a new incident record with logs, on-chain state, container state, and next hypotheses.

---

## 10.1 Follow-up Optimization Notes

During this run, an additional optimization opportunity was observed in the `moca-storage-provider` release pipeline. It is not part of this task and should be handled separately:

- Current `.github/workflows/go-releaser.yml` runs `make release-dry-run` first on official tag releases, then runs `make release`.
- Based on actual runtime, both steps perform a full goreleaser build, nearly doubling the duration.
- The higher-priority optimization is not to force release artifacts and GHCR image builds to be fully parallel. Instead:
  - Keep dry-run workflow for PRs / branches.
  - Run only one `make release` for official tag releases.
- If further speedup is needed later, consider splitting binary build, docker amd64/arm64, manifest, and release into parallel jobs.

---

## 11. Recommended Execution Order

1. Pull the latest `main` of `moca-storage-provider`.
2. Publish `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7`.
3. Upgrade `test-sp0` first.
4. Validate the `sg-sp0` exit issue on `test-sp0`.
5. After `test-sp0` passes, roll out to the remaining 5 nodes.
6. Complete full health checks and record results.

---

## 12. Final Pre-execution Confirmation

Before execution, confirm:

- GHCR publishing credentials are available.
- SSH connectivity to all 6 testnet SP hosts works.
- Current on-chain `sg-sp0` state has been re-sampled.
- The maintenance window allows a `test-sp0` canary and a longer observation period.

---

## 13. Execution Record

### 13.1 Historical Background: `rc6` Release

- Release date: 2026-04-22
- Release method: `mocachain/moca-storage-provider` tag `v1.2.0-rc6` triggered `goreleaser`
- Release baseline commit: `f17aa932532ed63c69f93de61174028e648fcb1a`
- Official release run: `24758498511`
- Image was pullable from remote hosts:
  - `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6`
- Digest pulled on `test-sp0`:
  - `sha256:6f3ec0f28651178114b0465777aad643c9100c756173a52277ce37804e83315c`

### 13.2 Historical Background: Testnet Rolling Upgrade to `rc6`

Execution date: 2026-04-22

| SSH alias | Container | Image after upgrade | Status |
| --- | --- | --- | --- |
| `test-sp0` | `moca-sp0` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` | healthy |
| `test-sp1` | `moca-sp1` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` | healthy |
| `test-sp2` | `moca-sp2` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` | healthy |
| `test-sp3` | `moca-sp3` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` | healthy |
| `test-sp4` | `moca-sp4` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` | healthy |
| `test-sp5` | `moca-sp5` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` | healthy |

Upgrade method:

- `test-sp0` was upgraded first as the canary.
- `test-sp1` ~ `test-sp5` were then upgraded in parallel rolling mode.
- All nodes continued using the compose compatibility format validated during `rc5`:
  - `command: --config config.toml --log.std`
  - `healthcheck: ["CMD-SHELL", "bash -c 'echo > /dev/tcp/127.0.0.1/9033'"]`

### 13.3 Historical Background: `sg-sp0` Re-test on `rc6`

Before upgrade, the following command was run on `test-sp0`:

```bash
docker exec moca-sp0 moca-sp query.sp.exit --config /app/config.toml
```

It returned:

- `rpc error: code = Unknown desc = spExitScheduler not exit`

After upgrading to `1.2.0-rc6`, the same command on the same node returned:

```json
{"self_sp_id":1}
```

The following logs were also observed in `moca-sp0`:

- `manager/sp_exit_scheduler.go:347 loop subscribe sp exit event`
- `manager/sp_exit_scheduler.go:404 loop subscribe swap out event`
- `manager/sp_exit_scheduler.go:332 sp exit subscribe progress`
- `manager/sp_exit_scheduler.go:381 swap out subscribe progress`

This confirms:

- The PR #24 fix that starts `spExitScheduler` during manager startup is effective on testnet `rc6`.
- The direct cause of `query.sp.exit` failure on `sg-sp0` has been fixed.

### 13.4 Current Business State

- `sg-sp0` is still in on-chain state `STATUS_GRACEFUL_EXITING`.
- This validation confirmed that `rc6` fixed the unavailable `query.sp.exit` / SP Exit scheduling issue caused by the scheduler not starting.
- Final `completeSpExit` for `sg-sp0` has not yet completed and needs continued observation or follow-up actions in a later window.

### 13.5 `rc6` Conclusion

- `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc6` was successfully published.
- All 6 testnet SPs were successfully upgraded to `rc6`.
- The `spExitScheduler not exit` issue on `sg-sp0` was confirmed fixed.
- The full `sg-sp0` exit flow still needed validation through `completeSpExit`.

### 13.6 `rc7` Release and Full Upgrade Result

- Release date: 2026-04-23
- Release method: `mocachain/moca-storage-provider` tag `v1.2.0-rc7` official `goreleaser`
- Release baseline commit: `5fcf09fc958c08ea69762edc444de83f294b3d53`
- GitHub Release:
  - `https://github.com/mocachain/moca-storage-provider/releases/tag/v1.2.0-rc7`
- Image is pullable:
  - `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7`
- Local pull validation digest:
  - `sha256:9fdfe758674e441d099765dd07dfcc413d92f1ae0867de599e08a7f0a5ea680c`

Upgrade date: 2026-04-23

| SSH alias | Container | Image after upgrade | Status |
| --- | --- | --- | --- |
| `test-sp0` | `moca-sp0` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` | healthy |
| `test-sp1` | `moca-sp1` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` | healthy |
| `test-sp2` | `moca-sp2` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` | healthy |
| `test-sp3` | `moca-sp3` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` | healthy |
| `test-sp4` | `moca-sp4` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` | healthy |
| `test-sp5` | `moca-sp5` | `ghcr.io/mocachain/moca-storage-provider:1.2.0-rc7` | healthy |

### 13.7 `sg-sp0` Re-test Result on `rc7`

On `test-sp0`, run:

```bash
docker exec moca-sp0 moca-sp query.sp.exit --config /app/config.toml
```

Response:

```json
{"self_sp_id":1}
```

Using the exit script to re-sample on-chain state:

- Current `sg-sp0` state: `STATUS_GRACEFUL_EXITING`

Further validation on `rc7`:

```bash
docker exec moca-sp0 moca-sp query-gvg-by-sp --config /app/config.toml --targetSP 1
```

Response:

- `null`

This indicates:

- `sg-sp0` currently has no remaining secondary GVG.

Then run:

```bash
docker exec moca-sp0 moca-sp query-vgf-by-sp --config /app/config.toml --targetSP 1
```

Response:

```json
[{"id":4,"virtual_payment_address":"0x8D720138eC1f2006dbe283C9A0f6eCe4B5c2fF1e"}]
```

This indicates:

- `sg-sp0` currently only has empty family `4` remaining.

On `test-sp0`, run:

```bash
docker exec moca-sp0 moca-sp --config /app/config.toml sp.complete.exit --operatorAddress 0x3801382abca4d7a4886d106efC402F041ca40631
```

The transaction failed:

- tx hash: `0xa65f69711c60bb52cbf8cf7c07373407b10135db7c545d924a07a4e1fa5f3588`

### 13.8 `rc7` Validation Conclusion

- The PR #24 fix is effective:
  - `spExitScheduler` starts normally.
  - `query.sp.exit` returns normally.
- The PR #27 / `moca-e2e` PR #30 fix is effective:
  - `sg-sp0` currently has no remaining secondary GVG.
- `sg-sp0` still cannot complete final exit.
- The remaining blocker has narrowed to:
  - Empty family `4` still belongs to `sg-sp0`.
  - `completeSpExit` is still rejected on-chain.

Final conclusion for this run:

- `1.2.0-rc7` has resolved the two SP-service-side issues from PR #24 / PR #27.
- But `1.2.0-rc7` alone cannot make `sg-sp0` complete final exit.
- If the goal is to fully remove `sg-sp0` from the SP list, empty family `4` still needs to be handled.

### 13.9 Field Finding: `us-sp0` Exit Plan Was Not Generated Automatically

During continued validation of `us-sp0` exit, the SP had successfully entered exiting state on-chain:

- SP: `us-sp0`
- SP ID: `4`
- operator: `0xDb50898D46ca07758B8082379c6e7e79d9603bE8`
- status: `STATUS_GRACEFUL_EXITING`
- exit tx: `0x1e8e97acd0bff966b7bef1a332fbca5e366949bc3d3a31409c0b459845c7d33c`
- exit tx block: `19305318`

However, on `test-sp3` / `moca-sp3`, running:

```bash
docker exec moca-sp3 moca-sp query.sp.exit --config /app/config.toml
```

returned:

```json
{"self_sp_id":4}
```

In other words, `spExitScheduler` exists and is queryable, but it does not return `swap_out_src` / `swap_out_dest` exit migration plans.

Further inspection of `moca-sp3` logs repeatedly showed:

```text
record not found
loop subscribe sp exit event sp_exit_events=""
loop subscribe swap out event swap_out_events=null
sp exit subscribe progress last_subscribed_block_height=1081413
```

At the same time, the local blocksyncer inside the container was still processing much older blocks:

```text
processing block height=13593506
fetch data start:13593508 end:13593517
```

The latest on-chain height was around `19306330`, and the exit tx was at block `19305318`. Therefore, this is not a case where `spExitScheduler` failed to start. The actual situation is:

1. `us-sp0` is already `STATUS_GRACEFUL_EXITING` on-chain.
2. The local blocksyncer / metadata DB of `us-sp0` has not caught up to the exit tx block.
3. Automatic plan generation in `spExitScheduler` depends on the `StorageProviderExit` event in the local metadata DB.
4. Because the local DB cannot find that event, `ListSpExitEvents` returns empty and `produceSwapOutPlan(false)` is not triggered.

Relevant code paths:

- `modular/manager/sp_exit_scheduler.go`
  - `subscribeEvents()` polls `ListSpExitEvents`.
  - It calls `produceSwapOutPlan(false)` to generate the exit migration plan only when `spExitEvents.Event != nil`.
- `store/bsdb/event_sp_exit.go`
  - `ListSpExitEvents()` queries `event_sp_exit` from the local metadata DB.
  - The current local DB returns `record not found`.

Therefore, the new finding is:

- PR #24 fixed the scheduler startup issue.
- PR #27 fixed the issue where secondary GVG derivation depended only on the local metadata DB.
- But there is still a recovery capability gap:
  - If an SP has already entered `GRACEFUL_EXITING` on-chain,
  - but the local blocksyncer is behind or missed the historical `StorageProviderExit` event,
  - the scheduler does not rebuild the exit plan from on-chain SP status alone.

Short-term operational conclusion:

- For `us-sp0`, do not wait for automatic exit plan progression.
- Continue manual `swapIn` / `recover-vgf` / `completeSwapIn` based on on-chain family / GVG state.
- After `primary_count=0` and `secondary_count=0`, run `sp.complete.exit`.

Follow-up code fix recommendation:

- `spExitScheduler` should add an on-chain status fallback during startup or periodic polling.
- When `selfSP.status == STATUS_GRACEFUL_EXITING` and there is no local swap-out plan, it should be allowed to rebuild the exit plan from on-chain family / secondary GVG state.
- This would let exit scheduling recover even when the local metadata DB did not capture the historical `StorageProviderExit` event.

## Related
- [[SP Upgrade Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
- [[testnet-sp-storage-provider-image-upgrade-and-sp-exit-validation-plan|testnet-sp-storage-provider-image-upgrade-and-sp-exit-validation-plan]]
