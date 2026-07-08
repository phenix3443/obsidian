#!/usr/bin/env bash

set -euo pipefail

MOCA_BIN="${MOCA_BIN:-/Users/liushangliang/github/mocachain/moca/build/mocad}"
RPC="${RPC:-tcp://54.38.38.12:26657}"
REST="${REST:-http://54.38.38.12:1317}"

TARGET_SP_ID="4"
TARGET_OPERATOR="0xDb50898D46ca07758B8082379c6e7e79d9603bE8"
TARGET_SSH_HOST="test-sp3"
TARGET_CONTAINER="moca-sp3"
TARGET_CONFIG="/app/config.toml"

SUCCESSOR_SP_ID="2"
SUCCESSOR_SSH_HOST="test-sp1"
SUCCESSOR_CONTAINER="moca-sp1"
SUCCESSOR_CONFIG="/app/config.toml"

FAMILY_LIMIT="${FAMILY_LIMIT:-80}"
WAIT_INTERVAL="${WAIT_INTERVAL:-5}"
WAIT_ATTEMPTS="${WAIT_ATTEMPTS:-30}"
DRY_RUN=false
SKIP_COMPLETE_EXIT=false

usage() {
  cat <<'EOF'
Usage:
  manual-complete-sp-exit.sh [options]

Goal:
  Manually finish a graceful SP exit when the local SP exit scheduler did not
  rebuild an exit plan from events. The script:

  1. Finds primary families still owned by the exiting SP.
  2. Moves each primary family to a successor SP by swapIn/recover/completeSwapIn.
  3. Finds secondary GVGs that still contain the exiting SP.
  4. Moves each secondary GVG to the successor SP by GVG-level swapIn/completeSwapIn.
  5. Sends sp.complete.exit from the exiting SP container.
  6. Verifies the exiting SP no longer exists on chain.

Defaults match the 2026-04-23 us-sp0 -> sg-sp1 operation:
  exiting SP:   us-sp0 / SP 4 / test-sp3 / moca-sp3
  successor SP: sg-sp1 / SP 2 / test-sp1 / moca-sp1

Options:
  --target-sp-id ID             Exiting SP ID. Default: 4
  --target-operator ADDRESS     Exiting SP operator address.
  --target-ssh-host HOST        SSH host for exiting SP runtime. Default: test-sp3
  --target-container NAME       Exiting SP container. Default: moca-sp3
  --target-config PATH          Exiting SP config path. Default: /app/config.toml

  --successor-sp-id ID          Successor SP ID. Default: 2
  --successor-ssh-host HOST     SSH host for successor runtime. Default: test-sp1
  --successor-container NAME    Successor container. Default: moca-sp1
  --successor-config PATH       Successor config path. Default: /app/config.toml

  --mocad PATH                  mocad binary path.
  --rpc URL                     CometBFT RPC URL.
  --rest URL                    REST API URL.
  --family-limit N              Scan family IDs from 1..N. Default: 80
  --wait-interval SEC           Recover poll interval. Default: 5
  --wait-attempts N             Recover poll attempts per family. Default: 30
  --skip-complete-exit          Migrate only; do not send sp.complete.exit.
  --dry-run                     Print commands instead of executing.
  -h, --help                    Show this help.

Examples:
  ./manual-complete-sp-exit.sh

  ./manual-complete-sp-exit.sh \
    --target-sp-id 4 \
    --target-operator 0xDb50898D46ca07758B8082379c6e7e79d9603bE8 \
    --successor-sp-id 2
EOF
}

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

die() {
  log "ERROR: $*"
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

rpc_status_url() {
  local rpc_http
  rpc_http="${RPC/tcp:\/\//http://}"
  printf '%s/status\n' "$rpc_http"
}

validate_endpoints() {
  if ! curl -fsS --max-time 5 "$(rpc_status_url)" >/dev/null; then
    die "RPC endpoint is unreachable: ${RPC}"
  fi

  if ! curl -fsS --max-time 5 "${REST}/cosmos/base/tendermint/v1beta1/node_info" >/dev/null; then
    die "REST endpoint is unreachable: ${REST}"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target-sp-id)
        TARGET_SP_ID="$2"
        shift 2
        ;;
      --target-operator)
        TARGET_OPERATOR="$2"
        shift 2
        ;;
      --target-ssh-host)
        TARGET_SSH_HOST="$2"
        shift 2
        ;;
      --target-container)
        TARGET_CONTAINER="$2"
        shift 2
        ;;
      --target-config)
        TARGET_CONFIG="$2"
        shift 2
        ;;
      --successor-sp-id)
        SUCCESSOR_SP_ID="$2"
        shift 2
        ;;
      --successor-ssh-host)
        SUCCESSOR_SSH_HOST="$2"
        shift 2
        ;;
      --successor-container)
        SUCCESSOR_CONTAINER="$2"
        shift 2
        ;;
      --successor-config)
        SUCCESSOR_CONFIG="$2"
        shift 2
        ;;
      --mocad)
        MOCA_BIN="$2"
        shift 2
        ;;
      --rpc)
        RPC="$2"
        shift 2
        ;;
      --rest)
        REST="$2"
        shift 2
        ;;
      --family-limit)
        FAMILY_LIMIT="$2"
        shift 2
        ;;
      --wait-interval)
        WAIT_INTERVAL="$2"
        shift 2
        ;;
      --wait-attempts)
        WAIT_ATTEMPTS="$2"
        shift 2
        ;;
      --skip-complete-exit)
        SKIP_COMPLETE_EXIT=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "unknown option: $1"
        ;;
    esac
  done
}

run_cmd() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

run_shell() {
  local cmd="$1"
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] %s\n' "$cmd"
    return 0
  fi
  eval "$cmd"
}

retry_capture() {
  local output
  local attempt
  for attempt in 1 2 3 4 5; do
    if output="$("$@" 2>/dev/null)"; then
      printf '%s\n' "$output"
      return 0
    fi
    sleep 2
  done
  return 1
}

query_family() {
  retry_capture "$MOCA_BIN" query virtualgroup global-virtual-group-family "$1" --node "$RPC" --output json
}

query_family_gvgs() {
  retry_capture "$MOCA_BIN" query virtualgroup global-virtual-group-by-family-id "$1" --node "$RPC" --output json
}

query_sp_stats() {
  curl -fsS "${REST}/moca/virtualgroup/sp_gvg_statistics?sp_id=${TARGET_SP_ID}"
}

successor_exec() {
  local command="$1"
  run_shell "ssh ${SUCCESSOR_SSH_HOST} \"docker exec ${SUCCESSOR_CONTAINER} ${command}\""
}

target_exec() {
  local command="$1"
  run_shell "ssh ${TARGET_SSH_HOST} \"docker exec ${TARGET_CONTAINER} ${command}\""
}

contains_csv_value() {
  local csv="$1"
  local needle="$2"
  local item

  IFS=',' read -r -a items <<<"$csv"
  for item in "${items[@]}"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

wait_recover_success() {
  local family_id="$1"
  local attempt
  local recover_output

  if [[ "$DRY_RUN" == true ]]; then
    log "dry-run: skip recover polling for family=${family_id}"
    return 0
  fi

  for ((attempt = 1; attempt <= WAIT_ATTEMPTS; attempt++)); do
    recover_output="$(
      ssh "${SUCCESSOR_SSH_HOST}" \
        "docker exec ${SUCCESSOR_CONTAINER} moca-sp query-recover-p --config ${SUCCESSOR_CONFIG} --vgf ${family_id} --gvgId 0" \
        2>/dev/null || true
    )"
    if printf '%s' "$recover_output" | grep -q 'Successful'; then
      log "family=${family_id} recover successful at attempt ${attempt}"
      return 0
    fi
    log "family=${family_id} waiting recover attempt=${attempt}/${WAIT_ATTEMPTS}"
    sleep "$WAIT_INTERVAL"
  done

  log "family=${family_id} recover status was not detected as Successful; continuing to completeSwapIn and verifying chain state"
}

move_primary_family() {
  local family_id="$1"
  local family_json="$2"
  local gvg_count
  local after_primary

  gvg_count="$(printf '%s' "$family_json" | jq -r '.global_virtual_group_family.global_virtual_group_ids | length')"
  log "moving primary family=${family_id} gvg_count=${gvg_count} from SP ${TARGET_SP_ID} to SP ${SUCCESSOR_SP_ID}"

  successor_exec "moca-sp swapIn --config ${SUCCESSOR_CONFIG} --vgf ${family_id} --gvgId 0 --targetSP ${TARGET_SP_ID}"

  if [[ "$gvg_count" != "0" ]]; then
    successor_exec "moca-sp recover-vgf --config ${SUCCESSOR_CONFIG} --vgf ${family_id}"
    wait_recover_success "$family_id"
  else
    log "family=${family_id} is empty; skipping recover-vgf"
  fi

  successor_exec "moca-sp completeSwapIn --config ${SUCCESSOR_CONFIG} --vgf ${family_id} --gvgId 0" || true

  after_primary="$(query_family "$family_id" | jq -r '.global_virtual_group_family.primary_sp_id')"
  [[ "$after_primary" == "$SUCCESSOR_SP_ID" ]] || die "family=${family_id} primary is ${after_primary}, expected ${SUCCESSOR_SP_ID}"
  log "family=${family_id} moved successfully"
}

move_secondary_gvg() {
  local family_id="$1"
  local gvg_id="$2"
  local gvg_json="$3"
  local primary_sp_id
  local secondary_csv
  local after_secondary_csv

  primary_sp_id="$(printf '%s' "$gvg_json" | jq -r '.primary_sp_id')"
  secondary_csv="$(printf '%s' "$gvg_json" | jq -r '.secondary_sp_ids | join(",")')"

  [[ "$primary_sp_id" != "$SUCCESSOR_SP_ID" ]] || die "successor SP ${SUCCESSOR_SP_ID} is primary for GVG ${gvg_id}"
  if contains_csv_value "$secondary_csv" "$SUCCESSOR_SP_ID"; then
    die "successor SP ${SUCCESSOR_SP_ID} is already secondary for GVG ${gvg_id}: ${secondary_csv}"
  fi

  log "moving secondary gvg=${gvg_id} family=${family_id} primary=${primary_sp_id} secondary=${secondary_csv}"
  successor_exec "moca-sp swapIn --config ${SUCCESSOR_CONFIG} --vgf 0 --gvgId ${gvg_id} --targetSP ${TARGET_SP_ID}"
  successor_exec "moca-sp completeSwapIn --config ${SUCCESSOR_CONFIG} --vgf 0 --gvgId ${gvg_id}" || true

  after_secondary_csv="$(
    query_family_gvgs "$family_id" |
      jq -r --argjson gvg_id "$gvg_id" '.global_virtual_groups[] | select(.id == $gvg_id) | .secondary_sp_ids | join(",")'
  )"
  if contains_csv_value "$after_secondary_csv" "$TARGET_SP_ID"; then
    die "GVG ${gvg_id} still contains exiting SP ${TARGET_SP_ID}: ${after_secondary_csv}"
  fi
  contains_csv_value "$after_secondary_csv" "$SUCCESSOR_SP_ID" || die "GVG ${gvg_id} does not contain successor SP ${SUCCESSOR_SP_ID}: ${after_secondary_csv}"
  log "gvg=${gvg_id} secondary moved successfully, new_secondary=${after_secondary_csv}"
}

migrate_primary_families() {
  local family_id
  local family_json
  local primary_sp_id

  log "scanning primary families owned by SP ${TARGET_SP_ID}"
  for ((family_id = 1; family_id <= FAMILY_LIMIT; family_id++)); do
    family_json="$(query_family "$family_id" || true)"
    [[ -n "$family_json" ]] || continue

    primary_sp_id="$(printf '%s' "$family_json" | jq -r '.global_virtual_group_family.primary_sp_id // empty')"
    [[ "$primary_sp_id" == "$TARGET_SP_ID" ]] || continue

    move_primary_family "$family_id" "$family_json"
    if [[ "$DRY_RUN" != true ]]; then
      query_sp_stats
      echo
    fi
  done
}

migrate_secondary_gvgs() {
  local family_id
  local gvg_lines
  local line
  local gvg_id
  local gvg_json

  log "scanning secondary GVGs containing SP ${TARGET_SP_ID}"
  for ((family_id = 1; family_id <= FAMILY_LIMIT; family_id++)); do
    gvg_lines="$(
      query_family_gvgs "$family_id" 2>/dev/null |
        jq -c --arg target "$TARGET_SP_ID" '.global_virtual_groups[]? | select((.secondary_sp_ids // []) | map(tostring) | index($target))' || true
    )"
    [[ -n "$gvg_lines" ]] || continue

    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      gvg_json="$line"
      gvg_id="$(printf '%s' "$gvg_json" | jq -r '.id')"
      move_secondary_gvg "$family_id" "$gvg_id" "$gvg_json"
      if [[ "$DRY_RUN" != true ]]; then
        query_sp_stats
        echo
      fi
    done <<<"$gvg_lines"
  done
}

complete_exit() {
  if [[ "$SKIP_COMPLETE_EXIT" == true ]]; then
    log "skip complete exit requested"
    return 0
  fi

  log "sending complete SP exit for SP ${TARGET_SP_ID}"
  target_exec "moca-sp --config ${TARGET_CONFIG} sp.complete.exit --operatorAddress ${TARGET_OPERATOR}"
}

verify_exit() {
  local stats

  if [[ "$DRY_RUN" == true || "$SKIP_COMPLETE_EXIT" == true ]]; then
    log "skip final chain verification"
    return 0
  fi

  stats="$(query_sp_stats)"
  log "final SP ${TARGET_SP_ID} stats: ${stats}"

  if "$MOCA_BIN" query sp storage-provider "$TARGET_SP_ID" --node "$RPC" --output json >/tmp/manual-complete-sp-exit.verify 2>&1; then
    cat /tmp/manual-complete-sp-exit.verify
    die "SP ${TARGET_SP_ID} still exists on chain"
  fi

  if grep -q 'StorageProvider does not exist' /tmp/manual-complete-sp-exit.verify; then
    log "SP ${TARGET_SP_ID} no longer exists on chain"
    return 0
  fi

  cat /tmp/manual-complete-sp-exit.verify
  die "failed to verify SP ${TARGET_SP_ID} removal"
}

main() {
  parse_args "$@"
  need_cmd jq
  need_cmd curl
  [[ -x "$MOCA_BIN" ]] || die "mocad binary is not executable: ${MOCA_BIN}"
  validate_endpoints

  log "target SP=${TARGET_SP_ID} operator=${TARGET_OPERATOR} runtime=${TARGET_SSH_HOST}/${TARGET_CONTAINER}"
  log "successor SP=${SUCCESSOR_SP_ID} runtime=${SUCCESSOR_SSH_HOST}/${SUCCESSOR_CONTAINER}"

  migrate_primary_families
  migrate_secondary_gvgs
  complete_exit
  verify_exit
}

main "$@"
