---
title: "Fix Semgrep Workflow git diff Args Issue"
aliases:
  - fix-semgrep-workflow-en
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
source_path: "tasks/fix-ci/fix-semgrep-workflow-en.md"
---

> [!summary]
> This task note is adapted for Obsidian under CI Fixes, with topic and language navigation links added.

## Navigation
- [[Tasks Index]]
- [[CI Fixes Index]]
- [[Topic Index]]
- [[Language Index]]
- [[fix-semgrep-workflow-zh|fix-semgrep-workflow-zh]]

---

# Fix Semgrep Workflow git diff Args Issue

## Problem

The Semgrep security scan in `.github/workflows/semgrep.yml` has never actually executed.
All run records show `skipped`, or `FAILURE` on PRs that contain code changes.

## Root Cause

The workflow uses `technote-space/get-diff-action@v6.1.2` to get the list of changed files:

```yaml
- name: Get Diff
  uses: technote-space/get-diff-action@v6.1.2
  with:
    PATTERNS: |
      **/*.go
      **/*.js
      **/*.ts
      **/*.sol
      go.mod
      go.sum
```

Then uses its output variable `GIT_DIFF_FILTERED` to conditionally run semgrep:

```yaml
- run: semgrep ci --config=auto
  env:
    SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
  if: "env.GIT_DIFF_FILTERED != ''"
```

There are two issues with this design:

**Issue 1: `technote-space/get-diff-action` is no longer maintained**

The repository was archived in November 2023 and receives no further updates.

**Issue 2: Node.js version incompatibility causes invalid git diff args**

GitHub Actions runners are migrating from Node.js 20 to Node.js 24 (forced cutover on June 2, 2026).
`get-diff-action@v6.1.2` depends on Node.js 20. In the new environment, it passes invalid arguments
to `git diff`. Git cannot recognize these arguments, prints its help output and exits, resulting in:

- `GIT_DIFF_FILTERED` always being empty
- The semgrep step being permanently skipped
- Or the action itself failing, causing the entire job to show `FAILURE`

The logs from PR #70 (`chore: remove dead x/inflation module`) show git printing its full diff help
output, along with this warning:

```
Node.js 20 actions are deprecated. The following actions are running on Node.js 20
and may not work as expected: actions/checkout@v4, technote-space/get-diff-action@v6.1.2.
```

## Fix

### Prerequisite: SEMGREP_APP_TOKEN

`semgrep ci` supports diff-aware scanning (only reporting findings introduced by the PR) when
connected to the Semgrep cloud platform. This requires `SEMGREP_APP_TOKEN` to be configured
under `Settings → Secrets and variables → Actions`.

This secret is **not currently configured**. Confirm first:
- Whether the project has a Semgrep account (semgrep.dev)
- Whether a token exists but has not been added to the repository

Choose the appropriate option based on token availability:

---

### Solution

Remove the `get-diff-action` step and the `if` condition entirely. `semgrep ci` handles
diff-aware scanning automatically when connected to the cloud platform.

```yaml
name: Semgrep
on:
  pull_request: {}
  push:
    branches:
      - main
    paths:
      - .github/workflows/semgrep.yml
  schedule:
    - cron: "0 0 * * 0"
jobs:
  semgrep:
    name: Scan
    runs-on: ubuntu-latest
    container:
      image: returntocorp/semgrep
    if: (github.actor != 'dependabot[bot]')
    steps:
      - name: Permission issue fix
        run: git config --global --add safe.directory $GITHUB_WORKSPACE
      - uses: actions/checkout@v4
      - run: semgrep ci --config=auto
        env:
          SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
```

Changes:
- Remove the `get-diff-action` step
- Remove the duplicate `actions/checkout@v6`
- Remove the `if` condition on the semgrep step
- Upgrade `actions/checkout@v6` to `@v4` (v6 does not exist; the original file had a typo)

---


## Verification

After applying the fix, open a PR that includes changes to `.go` files and check the Semgrep Scan job:

```bash
# List recent workflow runs
gh run list --workflow=semgrep.yml --limit 5 --json conclusion,headBranch --jq '.[]'

# Check Scan status on a specific PR
gh pr checks <PR-number> --json name,state --jq '.[] | select(.name == "Scan")'
```

Before fix: `conclusion: skipped` or `FAILURE`
After fix: `conclusion: success` or `failure` (failure means findings were detected, which confirms the scan ran correctly)

## Files

- `.github/workflows/semgrep.yml`

## References

- [Semgrep CI documentation](https://semgrep.dev/docs/semgrep-ci/sample-ci-configs)
- [technote-space/get-diff-action archive notice](https://github.com/technote-space/get-diff-action)
- [GitHub Actions Node.js 20 deprecation announcement](https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/)

## Related
- [[CI Fixes Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
- [[fix-semgrep-workflow-zh|fix-semgrep-workflow-zh]]
