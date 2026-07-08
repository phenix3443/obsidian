---
title: "Request `sp0` to Take Over Empty Family `4` So `sg-sp0` Can Fully Exit"
aliases:
  - sp0-family-4-swapin-request
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
source_path: "tasks/sp-exit/sp0-family-4-swapin-request.md"
---

> [!summary]
> This task note is adapted for Obsidian under SP Exit, with topic and language navigation links added.

## Navigation
- [[Tasks Index]]
- [[SP Exit Index]]
- [[Topic Index]]
- [[Language Index]]
- [[sp0-family-4-swapin-request-zh|sp0-family-4-swapin-request-zh]]

---

# Request `sp0` to Take Over Empty Family `4` So `sg-sp0` Can Fully Exit

## Background

We are currently completing the graceful exit of the following Storage Provider on testnet:

- SP moniker: `sg-sp0`
- SP ID: `1`
- SP operator: `0x3801382abca4d7a4886d106efC402F041ca40631`

The `moca-storage-provider` fixes for the SP Exit scheduler issue and the secondary GVG discovery issue have already been applied and validated. However, `sg-sp0` still cannot finish the final `completeSpExit`.

The remaining blocker has now been narrowed down to:

- there is still one empty family owned by `sg-sp0` on-chain
- family ID: `4`
- `primary_sp_id = 1`
- `global_virtual_group_ids = []`

In other words:

- this family no longer contains any GVG
- but its ownership is still attached to `sg-sp0`
- which prevents `sg-sp0` from completing its final exit

## Goal

Please let `sp0` take over this empty family `4`.

The recommended successor SP for this operation is:

- successor SP moniker: `sp0`
- successor SP ID: `7`

After completion, ownership of family `4` should move:

- from `sg-sp0` (`sp_id = 1`)

to:

- `sp0` (`sp_id = 7`)

Once that is done, we will continue the final `completeSpExit` flow on `sg-sp0`.

## Assumption

`sp0` is not running inside Docker, so the commands below are written for directly executing the `moca-sp` binary on the host machine.

Please replace the placeholders below with the actual values on your machine:

- `<moca-sp-binary>`
- `<sp0-config-path>`

Typical examples:

```bash
/usr/local/bin/moca-sp
/path/to/config.toml
```

## Steps

### Step 1. Send reserve swap-in from `sp0`

Run the following command on the machine hosting `sp0`:

```bash
<moca-sp-binary> swapIn --config <sp0-config-path> --vgf 4 --gvgId 0 --targetSP 1
```

Parameter meaning:

- `--targetSP 1`: the current owner being taken over is `sg-sp0`
- `--vgf 4`: the target family to take over is family `4`
- `--gvgId 0`: this is a family-level swap-in, not a single-GVG swap-in

Expected result:

- the command returns successfully
- the output includes a transaction hash

### Step 2. Complete the swap-in from `sp0`

Since family `4` is an empty family, there is no actual data recovery work to wait for, so you can continue directly with:

```bash
<moca-sp-binary> completeSwapIn --config <sp0-config-path> --vgf 4 --gvgId 0
```

Expected result:

- the command returns successfully
- the output includes a transaction hash

## Please Send Back

After completing the above steps, please send back:

1. the full output of the `swapIn` command
2. the full output of the `completeSwapIn` command
3. the transaction hashes of both transactions
4. the full error message if either command fails

## What We Will Do Next

After you complete the two steps above, we will continue with the following checks and finalization:

1. verify that family `4` is no longer owned by `sg-sp0`
2. verify that `sg-sp0` no longer holds this empty family
3. run the following on `sg-sp0`:

```bash
moca-sp --config /app/config.toml sp.complete.exit --operatorAddress 0x3801382abca4d7a4886d106efC402F041ca40631
```

4. verify that `sg-sp0` has fully exited and no longer appears in the SP list

## Ready-to-Forward Command Template

If the binary path and config path are already known on the `sp0` host, you can forward these two commands directly:

```bash
<moca-sp-binary> swapIn --config <sp0-config-path> --vgf 4 --gvgId 0 --targetSP 1
<moca-sp-binary> completeSwapIn --config <sp0-config-path> --vgf 4 --gvgId 0
```

## Note

This is not a request to re-run `spExit`.

`sg-sp0` is already in:

- `STATUS_GRACEFUL_EXITING`

The only purpose of this operation is to move the remaining empty family `4` away from `sg-sp0`, so that the final `completeSpExit` can succeed.

## Related
- [[SP Exit Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
- [[sp0-family-4-swapin-request-zh|sp0-family-4-swapin-request-zh]]
