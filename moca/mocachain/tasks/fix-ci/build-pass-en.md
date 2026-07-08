---
title: "Mocachain Build Pass Plan"
aliases:
  - build-pass-en
  - Ensure all mocachain repositories build successfully with remote branch references. The `check-build-by-branch.sh` script was enhanced to correctly use the target repository's branch (rather than the current repository's branch) when updating dependencies.
tags:
  - mocachain
  - task
  - ci-fixes
  - en
  - fix-ci
  - ci
type: "task-note"
status: "archived"
area: "tasks"
topic: "ci-fixes"
language: "en"
source_path: "tasks/fix-ci/build-pass-en.md"
---

> [!summary]
> This task note is adapted for Obsidian under CI Fixes, with topic and language navigation links added.

## Navigation
- [[Tasks Index]]
- [[CI Fixes Index]]
- [[Topic Index]]
- [[Language Index]]
- [[build-pass|build-pass]]


# Mocachain Build Pass Plan

---

Ensure all mocachain repositories build successfully with remote branch references. The `check-build-by-branch.sh` script was enhanced to correctly use the target repository's branch (rather than the current repository's branch) when updating dependencies.

## Core Changes

### Build Script Enhancement
Modified `moca-devcontainer/scripts/check-build-by-branch.sh` to query the **target repository's** required branch when updating dependencies, instead of using the current repository's branch. This properly supports scenarios where different repositories use different branches via `REPO_BRANCH_MAP`.

**Key change**:
```bash
# Use target repository's branch when updating dependencies
local target_branch=$(get_required_branch_for_repo "$target_repo_name")
```

### Dependency Upgrade
Unified `btcd/btcec/v2` to v2.3.4 across repositories to resolve API compatibility issues.

## Pull Requests

| Repository | PR | Description |
|------------|-----|-------------|
| moca-ibc-go | [#72](https://github.com/mocachain/moca-ibc-go/pull/72) | Upgrade btcd/btcec/v2 to v2.3.4, add complete replace directives for 08-wasm submodule, fix upgrade.NewAppModule API call |

## Build Verification

Verify all repositories build successfully with remote references:
```bash
cd moca-devcontainer
REPO_BRANCH_MAP="moca-cometbft:feat/build-pass,moca-ibc-go:feat/build-pass" \
  ./scripts/check-build-by-branch.sh --branch main --check-only
```

**Verification Results**:
- ✅ 12 repositories built successfully (moca-cometbft, moca-iavl, moca-cosmos-sdk, moca-ibc-go, moca, moca-common, moca-juno, moca-callisto-juno, moca-go-sdk, moca-cmd, moca-relayer, moca-storage-provider)
- ❌ 1 repository failed (moca-callisto, reason: dependent moca-callisto-juno pseudo-version not found remotely, unrelated to these changes)
- ✅ All successful repositories use remote GitHub paths, no local relative paths (`../`, except submodule-to-parent self-references)

## Repositories Without Code Changes

| Repository | Reason |
|------------|--------|
| moca-cometbft | No code changes needed, dependencies updated automatically by build script |
| moca-iavl | No code changes needed, dependencies updated automatically by build script |
| moca-cometbft-db | No code changes needed, dependencies updated automatically by build script |
| moca-cosmos-sdk | No code changes needed, dependencies updated automatically by build script |
| moca | No code changes needed, dependencies updated automatically by build script |
| moca-common | No code changes needed, dependencies updated automatically by build script |
| moca-juno | No code changes needed, dependencies updated automatically by build script |
| moca-callisto-juno | No code changes needed, dependencies updated automatically by build script |
| moca-go-sdk | No code changes needed, dependencies updated automatically by build script |
| moca-cmd | No code changes needed, dependencies updated automatically by build script |
| moca-relayer | No code changes needed, dependencies updated automatically by build script |
| moca-storage-provider | No code changes needed, dependencies updated automatically by build script |
| moca-callisto | Build failed (dependency issue, unrelated to these changes) |

## Related
- [[CI Fixes Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
- [[build-pass|build-pass]]
