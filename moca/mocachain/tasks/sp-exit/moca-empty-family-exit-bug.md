---
title: "`moca` Bug: Empty Family Can Block `CompleteStorageProviderExit`"
aliases:
  - moca-empty-family-exit-bug
tags:
  - mocachain
  - task
  - sp-exit
  - en
  - storage-provider
type: "task-note"
status: "archived"
area: "tasks"
topic: "sp-exit"
language: "en"
source_path: "tasks/sp-exit/moca-empty-family-exit-bug.md"
---

> [!summary]
> This task note is adapted for Obsidian under SP Exit, with topic and language navigation links added.

## Navigation
- [[Tasks Index]]
- [[SP Exit Index]]
- [[Topic Index]]
- [[Language Index]]
- [[moca-empty-family-exit-bug-zh|moca-empty-family-exit-bug-zh]]

---

# `moca` Bug: Empty Family Can Block `CompleteStorageProviderExit`

## Problem

There is a boundary-case bug in the current graceful SP exit flow:

- an exiting SP may still own a `GlobalVirtualGroupFamily`
- but that family is already empty, meaning:
  - `global_virtual_group_ids == []`

In this situation, the SP can still be blocked from completing:

- `CompleteStorageProviderExit`

## Observed Testnet Case

Observed on testnet:

- SP moniker: `sg-sp0`
- SP ID: `1`
- status: `STATUS_GRACEFUL_EXITING`

Remaining family:

- `family_id = 4`
- `primary_sp_id = 1`
- `global_virtual_groups = []`

This means:

- the SP still has family ownership on-chain
- but there is no actual GVG content left under that family

As a result, the SP remains stuck in:

- `STATUS_GRACEFUL_EXITING`

instead of being able to complete its exit.

## Why This Is a `moca` Bug

This is a chain-side exit semantics issue.

The final decision about whether an SP is allowed to complete its exit is made on-chain, not in the SP service.

Today, the exit path effectively treats empty family ownership as a blocking condition, even though:

- the family contains no GVGs
- there is no actual migration work left to perform

That causes a dead-end state:

- nothing remains to migrate
- but exit is still not allowed

## Expected Behavior

An empty family should not block `CompleteStorageProviderExit`.

If an exiting SP only has empty-family ownership left, the chain should allow the SP to complete its exit.

## Recommended Fix

Fix this in `moca`, in the exit validation path.

Recommended behavior:

- if a family is still owned by the exiting SP
- but `global_virtual_group_ids` is empty
- then that family should be treated as non-blocking for SP exit

## Suggested Implementation Direction

Preferred place to fix:

- `StorageProviderExitable`

Relevant files:

- [keeper.go](/Users/liushangliang/github/mocachain/moca/x/virtualgroup/keeper/keeper.go)
- [msg_server.go](/Users/liushangliang/github/mocachain/moca/x/virtualgroup/keeper/msg_server.go)

Likely affected methods:

- `StorageProviderExitable`
- `CompleteStorageProviderExit`

## Practical Fix Strategy

Adjust the exit validation logic so that:

1. empty families are excluded from the conditions that block exit
2. only families / relations with actual GVG content still block exit

In other words:

- empty-family ownership should not keep `PrimaryCount` / exitability in a state that prevents final exit

## What Should Still Remain True

This change should **not** weaken normal exit safety rules.

After the fix:

- an SP with non-empty families must still be blocked from `completeSpExit`
- an SP with actual secondary relationships that still matter must still be blocked
- only empty-family leftovers should be ignored or auto-cleared from exit validation

## Minimum Test Coverage

The fix should include tests for:

1. exiting SP with only empty family left
   - expected: `completeSpExit` is allowed

2. exiting SP with non-empty family still present
   - expected: `completeSpExit` is still blocked

3. exiting SP with a mix of empty and non-empty families
   - expected: only non-empty families block exit

## Desired Outcome

After this fix:

- empty-family leftovers no longer trap an SP in `STATUS_GRACEFUL_EXITING`
- graceful exit can complete correctly
- the chain behavior matches the real migration state

## Related
- [[SP Exit Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
- [[moca-empty-family-exit-bug-zh|moca-empty-family-exit-bug-zh]]
