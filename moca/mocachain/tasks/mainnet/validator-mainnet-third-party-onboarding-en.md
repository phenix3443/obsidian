---
title: "Moca Mainnet Validator Third-Party Onboarding Checklist"
aliases:
  - validator-mainnet-third-party-onboarding-en
tags:
  - mocachain
  - task
  - mainnet-ops
  - en
  - mainnet
type: "task-note"
status: "archived"
area: "tasks"
topic: "mainnet-ops"
language: "en"
source_path: "tasks/mainnet/validator-mainnet-third-party-onboarding-en.md"
---

> [!summary]
> This task note is adapted for Obsidian under Mainnet Ops, with topic and language navigation links added.

> [!info]
> Long-lived validator onboarding knowledge now lives in [[core/Validator Onboarding|Validator Onboarding]]. This page keeps task-specific background, documentation gaps, and execution context.

## Navigation
- [[Tasks Index]]
- [[Mainnet Ops Index]]
- [[Topic Index]]
- [[Language Index]]
- [[validator-mainnet-third-party-onboarding|validator-mainnet-third-party-onboarding]]
- [[core/Validator Onboarding|Validator Onboarding]]

---

# Moca Mainnet Validator Third-Party Onboarding Checklist

## Purpose

This document summarizes, for third-party onboarding to a Moca mainnet validator:

- what materials we should provide to the partner
- what the partner should prepare in advance
- what sequence both sides should follow
- what documentation and configuration risks are already visible in the current workspace

This document only covers `validator` onboarding and does not include `storage provider (SP)`.

## Scope

- a third party wants to join Moca mainnet as an independent validator operator
- the target role is a validator node
- the process includes node deployment, validator registration, go-live validation, and ongoing operations

## 1. What We Should Provide

### 1. Mainnet authoritative network parameter pack

At minimum, this should include:

- `chain_id`
- `genesis.json`
- recommended `config.toml`
- recommended `app.toml`
- official RPC endpoints
- official gRPC endpoints
- official REST/LCD endpoints
- official EVM RPC endpoints
- bootstrap node information
  - `seeds`, or
  - `persistent_peers`
- if fast sync / rapid bootstrap is supported, also provide:
  - state sync RPC servers
  - how to obtain trust height / trust hash
  - snapshot access method

These items should ideally be packaged into a single `network-pack/` directory instead of asking the partner to assemble them from multiple repositories and files.

### 2. Official software artifacts

At minimum, provide:

- the recommended `mocad` version
- the corresponding release tag
- binary download URLs or Docker image references
- checksum / image digest
- upgrade strategy guidance
  - whether `cosmovisor` is required
  - whether direct binary replacement is allowed

### 3. Validator admission process

We should clearly explain:

- how a validator joins mainnet
- whether governance is required
- whether manual approval / allowlist / foundation review is required
- minimum self-delegation requirements
- minimum proposal deposit requirements
- recommended gas / fee settings
- expected timeline from submission to production onboarding
- who reviews and approves the request

If the process includes governance, we should also provide:

- a proposal template
- field-by-field instructions
- example commands
- common failure cases

### 4. Validator identity / submission template

We should give the partner a standard template that asks for:

- `moniker`
- `identity`
- `website`
- `security_contact`
- `details`
- validator operator address
- delegator address
- relayer address
- challenger address
- consensus pubkey
- BLS public key
- BLS proof

If some of these fields are not actually required on mainnet, the template should still mark them clearly as:

- required
- optional
- not-used-on-mainnet

### 5. Node deployment and operations requirements

We should clearly provide:

- minimum hardware requirements
  - CPU
  - memory
  - disk type / size
  - network bandwidth
- recommended OS versions
- required ports
- recommended directory layout
- logging guidance
- monitoring and alerting guidance
- backup requirements
- upgrade procedures
- rollback procedures
- node migration precautions
- double-sign / downtime / missed-sign risk notes

If the team recommends a sentry architecture, that should be stated explicitly rather than left to assumption.

### 6. Go-live acceptance checklist

Acceptance criteria should be explicit so both sides use the same standard.

At minimum:

- node has completed initial sync
- P2P connectivity is healthy
- RPC / gRPC / REST endpoints are functional
- validator is queryable on-chain
- validator status is healthy
- self-delegation has arrived
- proposal has passed, if applicable
- block signing is stable
- monitoring / alerting is in place
- key backup has been completed

## 2. What the Partner Should Prepare

### 1. Infrastructure and network environment

The partner should prepare at least:

- a production runtime environment
- preferably a multi-node setup rather than a single bare node
- public IPs
- domain names or publicly identifiable endpoints
- sufficient bandwidth and SSD storage
- baseline security hardening
  - SSH controls
  - firewalling
  - least-privilege access
  - audit logging

If a sentry architecture is required, the partner should prepare at least:

- 1 validator signer / core node
- multiple sentry / edge nodes

### 2. Operational capability

The partner should be comfortable with:

- Linux operations
- systemd or container orchestration
- binary and/or Docker-based deployment
- `cosmovisor`
- Prometheus / Grafana / Alertmanager basics
- emergency upgrade and failover handling

### 3. Funding

The partner should prepare:

- required self-delegation funds
- proposal deposit funds
- ongoing gas budget
- long-term operating budget

In formal communication, we should provide concrete values instead of only saying "refer to on-chain parameters":

- minimum self-delegation
- recommended self-delegation
- minimum deposit
- recommended gas price

### 4. Addresses and key material

The partner should generate and securely manage:

- validator operator key
- delegator key
- consensus key
- if required by protocol:
  - relayer key
  - challenger key
  - BLS key

They should also prepare:

- an address inventory
- a pubkey inventory
- metadata used in the proposal / onboarding flow

### 5. Security and backup plan

Before go-live, the partner should define:

- how `priv_validator_key.json` will be stored
- how `priv_validator_state.json` will be migrated when needed
- whether HSM / remote signer will be used
- how double-signing will be prevented
- how cold backup will be handled
- how disaster recovery / failover will be performed

## 3. Recommended Onboarding Flow

### Phase 1: Documentation alignment

We provide:

- network parameter pack
- release and version guidance
- validator admission process
- submission template

The partner submits:

- organization information
- operations contact
- moniker and public profile
- addresses and pubkeys

### Phase 2: Environment preparation

The partner completes:

- machine provisioning
- baseline security hardening
- node deployment
- sync/bootstrap
- monitoring and alerting setup

We assist with:

- config review against mainnet requirements
- version and chain parameter validation
- troubleshooting sync or connectivity issues

### Phase 3: Validator registration / admission

If governance is required:

- the partner submits proposal materials
- we verify fields and financial parameters
- the proposal is submitted
- voting and execution are tracked

If governance is not required:

- validator creation follows the direct mainnet admission process

### Phase 4: Go-live acceptance

Both sides confirm:

- on-chain queries work
- validator status is healthy
- block signing is active
- metrics look healthy
- there are no unresolved alerts

### Phase 5: Ongoing operations

It is recommended to establish:

- an upgrade notification process
- an on-call contact path
- an incident response channel
- upgrade windows
- regular health checks

## 4. Recommended Deliverable Pack Structure

We recommend using the following structure for external delivery:

```text
validator-onboarding-pack/
├── 01-network-pack/
│   ├── genesis.json
│   ├── client.toml
│   ├── config.toml
│   ├── app.toml
│   └── README.md
├── 02-release/
│   ├── version.md
│   ├── binaries.md
│   └── checksums.txt
├── 03-validator-admission/
│   ├── process.md
│   ├── proposal-template.json
│   ├── proposal-fields.md
│   └── checklist.md
├── 04-ops-runbook/
│   ├── deploy.md
│   ├── upgrade.md
│   ├── monitoring.md
│   ├── backup-restore.md
│   └── incident-response.md
└── 05-acceptance/
    ├── acceptance-checklist.md
    └── handover.md
```

## 5. Risks Identified in the Current Workspace

### 1. Mainnet chain ID is inconsistent across files

There is a conflict in the current workspace:

- `moca/asset/configs/mainnet_config/genesis.json` uses `moca_5151-1`
- `moca/asset/configs/mainnet_config/client.toml` uses `moca_5151-1`
- `moca-devcontainer/networks/mainnet/network.env` uses `moca_5151-1`
- `moca-e2e/config/mainnet.yaml` uses `moca_2288-1`

Before sharing materials externally, we should first determine the single authoritative value and then align all documentation and configuration accordingly.

### 2. Mainnet peer settings do not look like a final external bootstrap configuration

In the current `moca/asset/configs/mainnet_config/config.toml`:

- `seeds = ""`
- `persistent_peers` still appears to use a local-style address

That suggests the current mainnet config in-repo is closer to a release template than a ready-to-distribute bootstrap pack for external validator operators.

We still need to provide:

- real seeds
- real persistent peers
- or state sync bootstrap parameters

### 3. There is no single authoritative mainnet validator admission SOP in the workspace

What we currently have includes:

- testnet proposal generation scripts
- local `create-validator` automation

What is still missing is a clean, authoritative "mainnet third-party validator onboarding SOP".

That should be prepared before formal external onboarding.

## 6. Minimum External Communication Baseline

If we need to start the conversation with a third party now, the minimum baseline should include:

- the currently recommended mainnet version
- the single correct mainnet `chain_id`
- the official genesis file
- official RPC / gRPC / REST / EVM RPC endpoints
- validator admission method
- the list of addresses and pubkeys they must prepare
- minimum funding requirements
- minimum hardware requirements
- contact path and approval process

Until the above items are fully aligned, we should avoid asking a third party to onboard directly from repository contents alone.

## 7. Recommended Follow-Up Work

The next work items should ideally be split into three deliverables:

1. unify the authoritative mainnet parameters
2. produce a formal validator onboarding pack
3. produce a one-page onboarding checklist for BD / ecosystem partner communication

This separation keeps engineering materials, operations materials, and business-facing materials from getting mixed together.

## Related
- [[Mainnet Ops Index]]
- [[Tasks Index]]
- [[Topic Index]]
- [[Language Index]]
- [[WORKSPACE]]
- [[Contracts]]
- [[validator-mainnet-third-party-onboarding|validator-mainnet-third-party-onboarding]]
