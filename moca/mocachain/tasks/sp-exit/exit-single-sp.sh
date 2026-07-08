#!/usr/bin/env bash

set -euo pipefail

MOCA_ROOT="${MOCA_ROOT:-/Users/liushangliang/github/mocachain}"
NETWORK_CONFIG_SH="${NETWORK_CONFIG_SH:-${MOCA_ROOT}/moca-devcontainer/libs/network_config.sh}"
MOCA_BIN_DEFAULT="${MOCA_ROOT}/moca/build/mocad"
DEFAULT_NETWORK="${NETWORK:-testnet}"
DEFAULT_WAIT_INTERVAL=15
DEFAULT_WAIT_TIMEOUT=3600
FAMILY_QUERY_LIMIT="${FAMILY_QUERY_LIMIT:-200}"

MODE="exit"

TARGET=""
NETWORK_NAME="$DEFAULT_NETWORK"
MOCA_BIN="${MOCA_BIN:-$MOCA_BIN_DEFAULT}"
RPC_OVERRIDE=""
DECLARE_CMD_TEMPLATE=""
FINALIZE_CMD_TEMPLATE=""
READY_CHECK_CMD_TEMPLATE=""
WAIT_INTERVAL="$DEFAULT_WAIT_INTERVAL"
WAIT_TIMEOUT="$DEFAULT_WAIT_TIMEOUT"
SKIP_DECLARE=false
SKIP_FINALIZE=false
DRY_RUN=false

MANUAL_FAMILY_ID=""
SUCCESSOR_TARGET=""
SUCCESSOR_SWAPIN_CMD_TEMPLATE=""
SUCCESSOR_RECOVER_CMD_TEMPLATE=""
SUCCESSOR_COMPLETE_SWAPIN_CMD_TEMPLATE=""
SUCCESSOR_COMPLETE_SWAPOUT_CMD_TEMPLATE=""
SKIP_MANUAL_RECOVER=false
SKIP_MANUAL_COMPLETE_SWAPOUT=true

CHAIN_ID=""
RPC=""
EVM_RPC=""

TARGET_MONIKER=""
TARGET_OPERATOR=""
TARGET_SP_ID=""
TARGET_SSH_HOST=""
TARGET_CONTAINER=""
TARGET_CONFIG_PATH=""

SUCCESSOR_MONIKER=""
SUCCESSOR_OPERATOR=""
SUCCESSOR_SP_ID=""
SUCCESSOR_SSH_HOST=""
SUCCESSOR_CONTAINER=""
SUCCESSOR_CONFIG_PATH=""
SUCCESSOR_SSH_HOST_OVERRIDE=""
SUCCESSOR_CONTAINER_OVERRIDE=""
SUCCESSOR_CONFIG_PATH_OVERRIDE=""

readonly EXITING_STATUSES="STATUS_GRACEFUL_EXITING,STATUS_FORCED_EXITING"
readonly EXIT_TARGET_MONIKERS_CSV="sg-sp0,sg-sp1,sg-sp2,us-sp0,us-sp1,us-sp2"
usage() {
  cat <<'EOF'
Usage:
  exit-single-sp.sh --target <sg-sp0|sg-sp1|sg-sp2|us-sp0|us-sp1|us-sp2|operator|sp_id> [options]

Goal:
  Support two operational modes:
  1. default exit mode:
     chain-side inventory -> declare exit -> wait -> finalize -> verify removal
  2. manual family migration mode:
     inspect family -> reserve swap-in on successor -> optional recover -> complete swap-in
     -> optional complete swap-out -> verify family primary changed

Exit mode examples:
  exit-single-sp.sh --target sg-sp0

  exit-single-sp.sh \
    --target sg-sp0 \
    --declare-cmd 'ssh test-sp0 "docker exec moca-sp0 moca-sp spExit --config /app/config.toml"' \
    --finalize-cmd 'ssh test-sp0 "docker exec moca-sp0 moca-sp completeSpExit --config /app/config.toml"'

Manual family migration examples:
  exit-single-sp.sh \
    --target sg-sp0 \
    --manual-family-id 4 \
    --successor sp0 \
    --successor-ssh-host your-preserved-sp-host \
    --successor-container your-preserved-sp-container \
    --successor-config /app/config.toml \
    --successor-swapin-cmd 'your successor swapIn command'

  exit-single-sp.sh \
    --target sg-sp0 \
    --manual-family-id 4 \
    --successor sp0 \
    --successor-swapin-cmd '...' \
    --successor-complete-swapin-cmd '...' \
    --skip-manual-complete-swapout

Common options:
  --target VALUE                         One of the 6 exit targets, an operator address, or an SP ID
  --network NAME                         Network config to load from moca-devcontainer (default: testnet)
  --rpc URL                              Override node URL used by mocad queries
  --mocad PATH                           Override mocad binary path
  --wait-interval SEC                    Poll interval in seconds (default: 15)
  --wait-timeout SEC                     Max wait per phase in seconds (default: 3600)
  --dry-run                              Print resolved commands without executing them
  -h, --help                             Show this help

Exit mode options:
  --declare-cmd CMD                      Command template to declare exit
  --finalize-cmd CMD                     Command template to finalize exit
  --ready-check-cmd CMD                  Optional custom readiness check; exit code 0 means ready
  --skip-declare                         Skip declare step and start from current chain status
  --skip-finalize                        Stop after declare/wait and do not send finalize

Manual family migration options:
  --manual-family-id ID                  Enable manual family migration mode for this family ID
  --successor VALUE                      Successor SP moniker/operator/sp_id, usually sp0|sp1|sp2
  --successor-ssh-host HOST              Explicit SSH host for successor runtime
  --successor-container NAME             Explicit container name for successor runtime
  --successor-config PATH                Explicit config.toml path for successor runtime
  --successor-swapin-cmd CMD             Command template to send reserve swap-in
  --successor-recover-cmd CMD            Command template to trigger recover-vgf
  --successor-complete-swapin-cmd CMD    Command template to send completeSwapIn
  --successor-complete-swapout-cmd CMD   Optional command template to send sp.complete.swapout
  --skip-manual-recover                  Skip recover-vgf step
  --skip-manual-complete-swapout         Skip debug complete swap-out step (default)
  --no-skip-manual-complete-swapout      Execute debug complete swap-out after completeSwapIn

Template variables:
  Source target:
    {moniker} {operator} {sp_id} {rpc} {chain_id}
  Family:
    {family_id} {family_primary_sp_id} {family_gvg_count} {family_gvg_ids_csv}
  Successor:
    {successor_moniker} {successor_operator} {successor_sp_id}
    {successor_ssh_host} {successor_container} {successor_config}
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

current_epoch() {
  date +%s
}

new_deadline() {
  echo $(( $(current_epoch) + WAIT_TIMEOUT ))
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target)
        [[ $# -ge 2 ]] || die "--target requires a value"
        TARGET="$2"
        shift 2
        ;;
      --network)
        [[ $# -ge 2 ]] || die "--network requires a value"
        NETWORK_NAME="$2"
        shift 2
        ;;
      --rpc)
        [[ $# -ge 2 ]] || die "--rpc requires a value"
        RPC_OVERRIDE="$2"
        shift 2
        ;;
      --mocad)
        [[ $# -ge 2 ]] || die "--mocad requires a value"
        MOCA_BIN="$2"
        shift 2
        ;;
      --declare-cmd)
        [[ $# -ge 2 ]] || die "--declare-cmd requires a value"
        DECLARE_CMD_TEMPLATE="$2"
        shift 2
        ;;
      --finalize-cmd)
        [[ $# -ge 2 ]] || die "--finalize-cmd requires a value"
        FINALIZE_CMD_TEMPLATE="$2"
        shift 2
        ;;
      --ready-check-cmd)
        [[ $# -ge 2 ]] || die "--ready-check-cmd requires a value"
        READY_CHECK_CMD_TEMPLATE="$2"
        shift 2
        ;;
      --wait-interval)
        [[ $# -ge 2 ]] || die "--wait-interval requires a value"
        WAIT_INTERVAL="$2"
        shift 2
        ;;
      --wait-timeout)
        [[ $# -ge 2 ]] || die "--wait-timeout requires a value"
        WAIT_TIMEOUT="$2"
        shift 2
        ;;
      --skip-declare)
        SKIP_DECLARE=true
        shift
        ;;
      --skip-finalize)
        SKIP_FINALIZE=true
        shift
        ;;
      --manual-family-id)
        [[ $# -ge 2 ]] || die "--manual-family-id requires a value"
        MANUAL_FAMILY_ID="$2"
        MODE="manual-family"
        shift 2
        ;;
      --successor)
        [[ $# -ge 2 ]] || die "--successor requires a value"
        SUCCESSOR_TARGET="$2"
        shift 2
        ;;
      --successor-swapin-cmd)
        [[ $# -ge 2 ]] || die "--successor-swapin-cmd requires a value"
        SUCCESSOR_SWAPIN_CMD_TEMPLATE="$2"
        shift 2
        ;;
      --successor-ssh-host)
        [[ $# -ge 2 ]] || die "--successor-ssh-host requires a value"
        SUCCESSOR_SSH_HOST_OVERRIDE="$2"
        shift 2
        ;;
      --successor-container)
        [[ $# -ge 2 ]] || die "--successor-container requires a value"
        SUCCESSOR_CONTAINER_OVERRIDE="$2"
        shift 2
        ;;
      --successor-config)
        [[ $# -ge 2 ]] || die "--successor-config requires a value"
        SUCCESSOR_CONFIG_PATH_OVERRIDE="$2"
        shift 2
        ;;
      --successor-recover-cmd)
        [[ $# -ge 2 ]] || die "--successor-recover-cmd requires a value"
        SUCCESSOR_RECOVER_CMD_TEMPLATE="$2"
        shift 2
        ;;
      --successor-complete-swapin-cmd)
        [[ $# -ge 2 ]] || die "--successor-complete-swapin-cmd requires a value"
        SUCCESSOR_COMPLETE_SWAPIN_CMD_TEMPLATE="$2"
        shift 2
        ;;
      --successor-complete-swapout-cmd)
        [[ $# -ge 2 ]] || die "--successor-complete-swapout-cmd requires a value"
        SUCCESSOR_COMPLETE_SWAPOUT_CMD_TEMPLATE="$2"
        shift 2
        ;;
      --skip-manual-recover)
        SKIP_MANUAL_RECOVER=true
        shift
        ;;
      --skip-manual-complete-swapout)
        SKIP_MANUAL_COMPLETE_SWAPOUT=true
        shift
        ;;
      --no-skip-manual-complete-swapout)
        SKIP_MANUAL_COMPLETE_SWAPOUT=false
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

  [[ -n "$TARGET" ]] || die "--target is required"
  [[ "$WAIT_INTERVAL" =~ ^[0-9]+$ ]] || die "--wait-interval must be an integer"
  [[ "$WAIT_TIMEOUT" =~ ^[0-9]+$ ]] || die "--wait-timeout must be an integer"
  if [[ "$MODE" == "manual-family" ]]; then
    [[ "$MANUAL_FAMILY_ID" =~ ^[0-9]+$ ]] || die "--manual-family-id must be an integer"
    [[ -n "$SUCCESSOR_TARGET" ]] || die "--successor is required in manual family migration mode"
  fi
}

load_network_config() {
  [[ -f "$NETWORK_CONFIG_SH" ]] || die "network config not found: $NETWORK_CONFIG_SH"
  # shellcheck source=/dev/null
  source "$NETWORK_CONFIG_SH" "$NETWORK_NAME"

  RPC="${RPC_OVERRIDE:-${RPC:-}}"
  CHAIN_ID="${CHAIN_ID:-}"
  EVM_RPC="${EVM_RPC:-}"

  [[ -n "$RPC" ]] || die "RPC is empty after loading network config"
  [[ -n "$CHAIN_ID" ]] || die "CHAIN_ID is empty after loading network config"
  [[ -x "$MOCA_BIN" || -f "$MOCA_BIN" ]] || die "mocad binary not found: $MOCA_BIN"
}

set_target_identity() {
  TARGET_MONIKER="$1"
  TARGET_OPERATOR="$2"
  TARGET_SP_ID="$3"
  TARGET_SSH_HOST="$4"
  TARGET_CONTAINER="$5"
  TARGET_CONFIG_PATH="$6"
}

set_successor_identity() {
  SUCCESSOR_MONIKER="$1"
  SUCCESSOR_OPERATOR="$2"
  SUCCESSOR_SP_ID="$3"
  SUCCESSOR_SSH_HOST="$4"
  SUCCESSOR_CONTAINER="$5"
  SUCCESSOR_CONFIG_PATH="$6"
}

set_known_identity() {
  local prefix="$1"
  local lookup="$2"

  case "$lookup" in
    sg-sp0)
      if [[ "$prefix" == "target" ]]; then
        set_target_identity "sg-sp0" "0x3801382abca4d7a4886d106efC402F041ca40631" "1" "test-sp0" "moca-sp0" "/app/config.toml"
      else
        set_successor_identity "sg-sp0" "0x3801382abca4d7a4886d106efC402F041ca40631" "1" "test-sp0" "moca-sp0" "/app/config.toml"
      fi
      ;;
    sg-sp1)
      if [[ "$prefix" == "target" ]]; then
        set_target_identity "sg-sp1" "0x012d29e0F5CA242b69E2De14b7D1b7659fB0513f" "2" "test-sp1" "moca-sp1" "/app/config.toml"
      else
        set_successor_identity "sg-sp1" "0x012d29e0F5CA242b69E2De14b7D1b7659fB0513f" "2" "test-sp1" "moca-sp1" "/app/config.toml"
      fi
      ;;
    sg-sp2)
      if [[ "$prefix" == "target" ]]; then
        set_target_identity "sg-sp2" "0x334dB11F7E0EB53e90e7eE81270130e0a67078ED" "3" "test-sp2" "moca-sp2" "/app/config.toml"
      else
        set_successor_identity "sg-sp2" "0x334dB11F7E0EB53e90e7eE81270130e0a67078ED" "3" "test-sp2" "moca-sp2" "/app/config.toml"
      fi
      ;;
    us-sp0)
      if [[ "$prefix" == "target" ]]; then
        set_target_identity "us-sp0" "0xDb50898D46ca07758B8082379c6e7e79d9603bE8" "4" "test-sp3" "moca-sp3" "/app/config.toml"
      else
        set_successor_identity "us-sp0" "0xDb50898D46ca07758B8082379c6e7e79d9603bE8" "4" "test-sp3" "moca-sp3" "/app/config.toml"
      fi
      ;;
    us-sp1)
      if [[ "$prefix" == "target" ]]; then
        set_target_identity "us-sp1" "0xEF52CE1a1F4aa538a6Ab61B35b806438cB2C808F" "5" "test-sp4" "moca-sp4" "/app/config.toml"
      else
        set_successor_identity "us-sp1" "0xEF52CE1a1F4aa538a6Ab61B35b806438cB2C808F" "5" "test-sp4" "moca-sp4" "/app/config.toml"
      fi
      ;;
    us-sp2)
      if [[ "$prefix" == "target" ]]; then
        set_target_identity "us-sp2" "0x516c01a2e8C36ecC23739987412Ec0Fe95bE0d52" "6" "test-sp5" "moca-sp5" "/app/config.toml"
      else
        set_successor_identity "us-sp2" "0x516c01a2e8C36ecC23739987412Ec0Fe95bE0d52" "6" "test-sp5" "moca-sp5" "/app/config.toml"
      fi
      ;;
    sp0)
      if [[ "$prefix" == "target" ]]; then
        set_target_identity "sp0" "0x969437b439A2D901B158adeCD7800cF42F44F1BE" "7" "" "" ""
      else
        set_successor_identity "sp0" "0x969437b439A2D901B158adeCD7800cF42F44F1BE" "7" "" "" ""
      fi
      ;;
    sp1)
      if [[ "$prefix" == "target" ]]; then
        set_target_identity "sp1" "0x8FdFEebb88D9150f2405c6e1d01eed2A763F9716" "8" "" "" ""
      else
        set_successor_identity "sp1" "0x8FdFEebb88D9150f2405c6e1d01eed2A763F9716" "8" "" "" ""
      fi
      ;;
    sp2)
      if [[ "$prefix" == "target" ]]; then
        set_target_identity "sp2" "0x3b62eb597bd09B818d88F187120E70e0dD8e39f0" "9" "" "" ""
      else
        set_successor_identity "sp2" "0x3b62eb597bd09B818d88F187120E70e0dD8e39f0" "9" "" "" ""
      fi
      ;;
    *)
      return 1
      ;;
  esac

  return 0
}

query_all_sps_json() {
  "$MOCA_BIN" query sp storage-providers --node "$RPC" --output json
}

resolve_identity_from_chain() {
  local prefix="$1"
  local raw_target="$2"
  local moniker=""
  local operator=""
  local sp_id=""
  local ssh_host=""
  local container=""
  local config_path=""
  local all_json row

  if set_known_identity "$prefix" "$raw_target"; then
    return 0
  fi

  case "$raw_target" in
    0x[0-9a-fA-F][0-9a-fA-F]*)
      operator="$raw_target"
      ;;
    [0-9]*)
      sp_id="$raw_target"
      ;;
    *)
      die "unsupported ${prefix} identifier: $raw_target"
      ;;
  esac

  all_json="$(query_all_sps_json)"
  if [[ -n "$operator" ]]; then
    row="$(printf '%s\n' "$all_json" | jq -r --arg op "$operator" '.sps[] | select(.operator_address == $op) | [.description.moniker, .operator_address, .id] | @tsv' | head -1)"
    [[ -n "$row" ]] || die "${prefix} operator not found on chain: $operator"
    moniker="$(printf '%s' "$row" | cut -f1)"
    operator="$(printf '%s' "$row" | cut -f2)"
    sp_id="$(printf '%s' "$row" | cut -f3)"
  else
    row="$(printf '%s\n' "$all_json" | jq -r --argjson id "$sp_id" '.sps[] | select(.id == $id) | [.description.moniker, .operator_address, .id] | @tsv' | head -1)"
    [[ -n "$row" ]] || die "${prefix} SP ID not found on chain: $sp_id"
    moniker="$(printf '%s' "$row" | cut -f1)"
    operator="$(printf '%s' "$row" | cut -f2)"
    sp_id="$(printf '%s' "$row" | cut -f3)"
  fi

  if set_known_identity "$prefix" "$moniker"; then
    return 0
  fi

  if [[ "$prefix" == "target" ]]; then
    set_target_identity "$moniker" "$operator" "$sp_id" "$ssh_host" "$container" "$config_path"
  else
    set_successor_identity "$moniker" "$operator" "$sp_id" "$ssh_host" "$container" "$config_path"
  fi
}

resolve_target() {
  resolve_identity_from_chain "target" "$TARGET"
  contains_csv_value "$EXIT_TARGET_MONIKERS_CSV" "$TARGET_MONIKER" \
    || die "target '$TARGET' resolves to '$TARGET_MONIKER', which is not in the allowed 6-node exit set"
}

resolve_successor() {
  resolve_identity_from_chain "successor" "$SUCCESSOR_TARGET"
  apply_successor_runtime_overrides
}

apply_successor_runtime_overrides() {
  [[ -n "$SUCCESSOR_SSH_HOST_OVERRIDE" ]] && SUCCESSOR_SSH_HOST="$SUCCESSOR_SSH_HOST_OVERRIDE"
  [[ -n "$SUCCESSOR_CONTAINER_OVERRIDE" ]] && SUCCESSOR_CONTAINER="$SUCCESSOR_CONTAINER_OVERRIDE"
  [[ -n "$SUCCESSOR_CONFIG_PATH_OVERRIDE" ]] && SUCCESSOR_CONFIG_PATH="$SUCCESSOR_CONFIG_PATH_OVERRIDE"
}

query_sp_json_by_operator() {
  local operator="$1"
  "$MOCA_BIN" query sp storage-provider-by-operator-address "$operator" --node "$RPC" --output json 2>/dev/null || true
}

query_sp_json() {
  query_sp_json_by_operator "$TARGET_OPERATOR"
}

query_successor_sp_json() {
  query_sp_json_by_operator "$SUCCESSOR_OPERATOR"
}

sp_exists() {
  local json="$1"
  [[ -n "$json" ]] && [[ "$json" != "null" ]] && printf '%s\n' "$json" | jq -e '.storage_provider.id // .storageProvider.id' >/dev/null 2>&1
}

sp_field() {
  local json="$1"
  local expr="$2"
  printf '%s\n' "$json" | jq -r "$expr // empty"
}

query_all_families_json() {
  "$MOCA_BIN" query virtualgroup global-virtual-group-families "$FAMILY_QUERY_LIMIT" --node "$RPC" --output json
}

query_family_json_by_id() {
  local family_id="$1"
  "$MOCA_BIN" query virtualgroup global-virtual-group-family "$family_id" --node "$RPC" --output json 2>/dev/null || true
}

target_primary_family_count() {
  local families_json
  families_json="$(query_all_families_json)"
  printf '%s\n' "$families_json" | jq -r --argjson sp_id "$TARGET_SP_ID" '(.gvg_families // []) | map(select(.primary_sp_id == $sp_id)) | length'
}

target_primary_family_ids_csv() {
  local families_json
  families_json="$(query_all_families_json)"
  printf '%s\n' "$families_json" | jq -r --argjson sp_id "$TARGET_SP_ID" '(.gvg_families // []) | map(select(.primary_sp_id == $sp_id).id) | join(",")'
}

render_template() {
  local template="$1"
  local family_json family_primary_sp_id family_gvg_count family_gvg_ids_csv

  family_primary_sp_id=""
  family_gvg_count=""
  family_gvg_ids_csv=""
  if [[ -n "$MANUAL_FAMILY_ID" ]]; then
    family_json="$(query_family_json_by_id "$MANUAL_FAMILY_ID")"
    family_primary_sp_id="$(printf '%s\n' "$family_json" | jq -r '.global_virtual_group_family.primary_sp_id // empty' 2>/dev/null || true)"
    family_gvg_count="$(printf '%s\n' "$family_json" | jq -r '(.global_virtual_group_family.global_virtual_group_ids // []) | length' 2>/dev/null || true)"
    family_gvg_ids_csv="$(printf '%s\n' "$family_json" | jq -r '(.global_virtual_group_family.global_virtual_group_ids // []) | map(tostring) | join(",")' 2>/dev/null || true)"
  fi

  template="${template//\{moniker\}/$TARGET_MONIKER}"
  template="${template//\{operator\}/$TARGET_OPERATOR}"
  template="${template//\{sp_id\}/$TARGET_SP_ID}"
  template="${template//\{rpc\}/$RPC}"
  template="${template//\{chain_id\}/$CHAIN_ID}"
  template="${template//\{family_id\}/$MANUAL_FAMILY_ID}"
  template="${template//\{family_primary_sp_id\}/$family_primary_sp_id}"
  template="${template//\{family_gvg_count\}/$family_gvg_count}"
  template="${template//\{family_gvg_ids_csv\}/$family_gvg_ids_csv}"
  template="${template//\{successor_moniker\}/$SUCCESSOR_MONIKER}"
  template="${template//\{successor_operator\}/$SUCCESSOR_OPERATOR}"
  template="${template//\{successor_sp_id\}/$SUCCESSOR_SP_ID}"
  template="${template//\{successor_ssh_host\}/$SUCCESSOR_SSH_HOST}"
  template="${template//\{successor_container\}/$SUCCESSOR_CONTAINER}"
  template="${template//\{successor_config\}/$SUCCESSOR_CONFIG_PATH}"
  printf '%s\n' "$template"
}

default_exit_command_template() {
  local phase="$1"
  local subcommand=""

  [[ -n "$TARGET_SSH_HOST" ]] || die "no default SSH host mapping for target '$TARGET_MONIKER'"
  [[ -n "$TARGET_CONTAINER" ]] || die "no default container mapping for target '$TARGET_MONIKER'"
  [[ -n "$TARGET_CONFIG_PATH" ]] || die "no default config path mapping for target '$TARGET_MONIKER'"

  case "$phase" in
    declare) subcommand="spExit" ;;
    finalize) subcommand="completeSpExit" ;;
    *) die "unsupported exit phase: $phase" ;;
  esac

  printf 'ssh %s "docker exec %s moca-sp %s --config %s"\n' \
    "$TARGET_SSH_HOST" \
    "$TARGET_CONTAINER" \
    "$subcommand" \
    "$TARGET_CONFIG_PATH"
}

require_successor_runtime_mapping() {
  [[ -n "$SUCCESSOR_SSH_HOST" ]] || die "successor '$SUCCESSOR_MONIKER' has no known SSH mapping; please pass explicit successor command templates"
  [[ -n "$SUCCESSOR_CONTAINER" ]] || die "successor '$SUCCESSOR_MONIKER' has no known container mapping; please pass explicit successor command templates"
  [[ -n "$SUCCESSOR_CONFIG_PATH" ]] || die "successor '$SUCCESSOR_MONIKER' has no known config path; please pass explicit successor command templates"
}

default_manual_command_template() {
  local phase="$1"
  require_successor_runtime_mapping

  case "$phase" in
    swapin)
      printf 'ssh %s "docker exec %s moca-sp swapIn --config %s --vgf %s --gvgId 0 --targetSP %s"\n' \
        "$SUCCESSOR_SSH_HOST" "$SUCCESSOR_CONTAINER" "$SUCCESSOR_CONFIG_PATH" "$MANUAL_FAMILY_ID" "$TARGET_SP_ID"
      ;;
    recover)
      printf 'ssh %s "docker exec %s moca-sp recover-vgf --config %s --vgf %s"\n' \
        "$SUCCESSOR_SSH_HOST" "$SUCCESSOR_CONTAINER" "$SUCCESSOR_CONFIG_PATH" "$MANUAL_FAMILY_ID"
      ;;
    complete-swapin)
      printf 'ssh %s "docker exec %s moca-sp completeSwapIn --config %s --vgf %s --gvgId 0"\n' \
        "$SUCCESSOR_SSH_HOST" "$SUCCESSOR_CONTAINER" "$SUCCESSOR_CONFIG_PATH" "$MANUAL_FAMILY_ID"
      ;;
    complete-swapout)
      printf 'ssh %s "docker exec %s moca-sp sp.complete.swapout --config %s --operatorAddress %s --familyID %s"\n' \
        "$SUCCESSOR_SSH_HOST" "$SUCCESSOR_CONTAINER" "$SUCCESSOR_CONFIG_PATH" "$SUCCESSOR_OPERATOR" "$MANUAL_FAMILY_ID"
      ;;
    *)
      die "unsupported manual phase: $phase"
      ;;
  esac
}

extract_tx_hash() {
  local text="$1"
  printf '%s\n' "$text" | awk '
    BEGIN { IGNORECASE = 1 }
    {
      if (match($0, /(0x)?[0-9a-f]{64}/)) {
        print substr($0, RSTART, RLENGTH)
        exit
      }
    }
  '
}

run_template_command() {
  local phase="$1"
  local template="$2"
  local rendered output

  rendered="$(render_template "$template")"
  [[ -n "$rendered" ]] || die "$phase command is empty"
  log "$phase command: $rendered"

  if [[ "$DRY_RUN" == true ]]; then
    return 0
  fi

  output="$(bash -lc "$rendered" 2>&1)" || {
    printf '%s\n' "$output" >&2
    die "$phase command failed"
  }

  if [[ -n "$output" ]]; then
    printf '%s\n' "$output"
  fi
}

current_status() {
  local json="$1"
  sp_field "$json" '.storage_provider.status // .storageProvider.status'
}

wait_for_status() {
  local wanted_csv="$1"
  local deadline json status
  deadline="$(new_deadline)"

  while (( $(current_epoch) <= deadline )); do
    json="$(query_sp_json)"
    if ! sp_exists "$json"; then
      log "SP no longer exists on chain while waiting for status: $wanted_csv"
      return 1
    fi

    status="$(current_status "$json")"
    log "current status: ${status:-<empty>}"
    contains_csv_value "$wanted_csv" "$status" && return 0
    sleep "$WAIT_INTERVAL"
  done

  return 1
}

wait_until_removed() {
  local deadline json status
  deadline="$(new_deadline)"

  while (( $(current_epoch) <= deadline )); do
    json="$(query_sp_json)"
    if ! sp_exists "$json"; then
      return 0
    fi
    status="$(current_status "$json")"
    log "SP still exists on chain, status=${status:-<empty>}"
    sleep "$WAIT_INTERVAL"
  done

  return 1
}

run_ready_check() {
  local rendered
  rendered="$(render_template "$READY_CHECK_CMD_TEMPLATE")"
  log "ready-check command: $rendered"

  [[ "$DRY_RUN" == true ]] && return 0
  bash -lc "$rendered" >/dev/null 2>&1
}

family_count_ready_for_finalize() {
  local count family_ids
  count="$(target_primary_family_count)"
  family_ids="$(target_primary_family_ids_csv)"

  if [[ "$count" =~ ^[0-9]+$ ]]; then
    log "current primary family count: $count"
    [[ -n "$family_ids" ]] && log "current primary family ids: $family_ids"
    [[ "$count" == "0" ]]
    return $?
  fi

  log "family count query unavailable, still waiting"
  return 1
}

wait_until_ready_for_finalize() {
  local deadline
  deadline="$(new_deadline)"

  while (( $(current_epoch) <= deadline )); do
    if [[ -n "$READY_CHECK_CMD_TEMPLATE" ]]; then
      if run_ready_check; then
        log "custom ready-check passed"
        return 0
      fi
    else
      if family_count_ready_for_finalize; then
        log "target no longer owns any primary family"
        return 0
      fi
    fi

    sleep "$WAIT_INTERVAL"
  done

  return 1
}

log_tx_hash_if_present() {
  local phase="$1"
  local output="$2"
  local tx_hash=""

  [[ -n "$output" ]] || return 0
  tx_hash="$(extract_tx_hash "$output" || true)"
  [[ -n "$tx_hash" ]] && log "$phase tx hash: $tx_hash"
}

print_target_summary() {
  local json status funding endpoint deposit
  json="$(query_sp_json)"
  sp_exists "$json" || die "target SP is not found on chain: $TARGET_OPERATOR"

  status="$(current_status "$json")"
  funding="$(sp_field "$json" '.storage_provider.funding_address // .storageProvider.funding_address // .storageProvider.fundingAddress')"
  endpoint="$(sp_field "$json" '.storage_provider.endpoint // .storageProvider.endpoint')"
  deposit="$(sp_field "$json" '.storage_provider.total_deposit // .storageProvider.total_deposit // .storageProvider.totalDeposit')"

  log "target summary:"
  log "  moniker: $TARGET_MONIKER"
  log "  sp_id: $TARGET_SP_ID"
  log "  operator: $TARGET_OPERATOR"
  log "  ssh_host: ${TARGET_SSH_HOST:-<unset>}"
  log "  container: ${TARGET_CONTAINER:-<unset>}"
  log "  config: ${TARGET_CONFIG_PATH:-<unset>}"
  log "  funding: $funding"
  log "  endpoint: $endpoint"
  log "  status: $status"
  log "  total_deposit: $deposit"
}

print_successor_summary() {
  local json status endpoint
  json="$(query_successor_sp_json)"
  sp_exists "$json" || die "successor SP is not found on chain: $SUCCESSOR_OPERATOR"

  status="$(current_status "$json")"
  endpoint="$(sp_field "$json" '.storage_provider.endpoint // .storageProvider.endpoint')"

  log "successor summary:"
  log "  moniker: $SUCCESSOR_MONIKER"
  log "  sp_id: $SUCCESSOR_SP_ID"
  log "  operator: $SUCCESSOR_OPERATOR"
  log "  ssh_host: ${SUCCESSOR_SSH_HOST:-<unset>}"
  log "  container: ${SUCCESSOR_CONTAINER:-<unset>}"
  log "  config: ${SUCCESSOR_CONFIG_PATH:-<unset>}"
  log "  endpoint: $endpoint"
  log "  status: $status"
}

print_manual_family_summary() {
  local family_json family_exists family_primary_sp_id family_gvg_count family_gvg_ids_csv

  family_json="$(query_family_json_by_id "$MANUAL_FAMILY_ID")"
  family_exists="$(printf '%s\n' "$family_json" | jq -e '.global_virtual_group_family.id' >/dev/null 2>&1 && echo yes || echo no)"
  [[ "$family_exists" == "yes" ]] || die "family not found on chain: $MANUAL_FAMILY_ID"

  family_primary_sp_id="$(printf '%s\n' "$family_json" | jq -r '.global_virtual_group_family.primary_sp_id')"
  family_gvg_count="$(printf '%s\n' "$family_json" | jq -r '(.global_virtual_group_family.global_virtual_group_ids // []) | length')"
  family_gvg_ids_csv="$(printf '%s\n' "$family_json" | jq -r '(.global_virtual_group_family.global_virtual_group_ids // []) | map(tostring) | join(",")')"

  log "manual family summary:"
  log "  family_id: $MANUAL_FAMILY_ID"
  log "  current_primary_sp_id: $family_primary_sp_id"
  log "  gvg_count: $family_gvg_count"
  log "  gvg_ids: ${family_gvg_ids_csv:-<empty>}"

  [[ "$family_primary_sp_id" == "$TARGET_SP_ID" ]] \
    || die "family $MANUAL_FAMILY_ID primary_sp_id is $family_primary_sp_id, not target SP ID $TARGET_SP_ID"

  [[ "$SUCCESSOR_SP_ID" != "$TARGET_SP_ID" ]] \
    || die "successor SP must be different from target SP"
}

require_execution_template() {
  local message="$1"
  local template="$2"
  [[ -n "$template" ]] || die "$message"
}

wait_until_family_primary_changes() {
  local deadline family_json current_primary_sp_id
  deadline="$(new_deadline)"

  while (( $(current_epoch) <= deadline )); do
    family_json="$(query_family_json_by_id "$MANUAL_FAMILY_ID")"
    current_primary_sp_id="$(printf '%s\n' "$family_json" | jq -r '.global_virtual_group_family.primary_sp_id // empty' 2>/dev/null || true)"
    log "family $MANUAL_FAMILY_ID current primary_sp_id: ${current_primary_sp_id:-<empty>}"

    [[ "$current_primary_sp_id" == "$SUCCESSOR_SP_ID" ]] && return 0
    sleep "$WAIT_INTERVAL"
  done

  return 1
}

manual_family_has_gvgs() {
  local family_json count
  family_json="$(query_family_json_by_id "$MANUAL_FAMILY_ID")"
  count="$(printf '%s\n' "$family_json" | jq -r '(.global_virtual_group_family.global_virtual_group_ids // []) | length')"
  [[ "$count" != "0" ]]
}

run_exit_mode() {
  if [[ -z "$DECLARE_CMD_TEMPLATE" ]]; then
    DECLARE_CMD_TEMPLATE="$(default_exit_command_template declare)"
  fi
  if [[ -z "$FINALIZE_CMD_TEMPLATE" ]]; then
    FINALIZE_CMD_TEMPLATE="$(default_exit_command_template finalize)"
  fi

  print_target_summary

  if [[ "$DRY_RUN" == true ]]; then
    log "declare command: $(render_template "$DECLARE_CMD_TEMPLATE")"
    if [[ "$SKIP_FINALIZE" == false ]]; then
      log "finalize command: $(render_template "$FINALIZE_CMD_TEMPLATE")"
    fi
    if [[ -n "$READY_CHECK_CMD_TEMPLATE" ]]; then
      log "ready-check command: $(render_template "$READY_CHECK_CMD_TEMPLATE")"
    fi
    log "dry-run complete"
    exit 0
  fi

  if [[ "$SKIP_DECLARE" == false ]]; then
    require_execution_template "--declare-cmd is required unless --skip-declare is used" "$DECLARE_CMD_TEMPLATE"
    log "starting declare phase"
    local declare_output
    declare_output="$(run_template_command "declare" "$DECLARE_CMD_TEMPLATE")"
    log_tx_hash_if_present "declare" "$declare_output"
  fi

  log "waiting for exiting status"
  wait_for_status "$EXITING_STATUSES" || die "SP did not reach exiting status within timeout"
  log "target entered exiting status"

  if [[ "$SKIP_FINALIZE" == true ]]; then
    log "skip-finalize enabled, stopping after declare and exiting-status verification"
    exit 0
  fi

  require_execution_template "--finalize-cmd is required unless --skip-finalize is used" "$FINALIZE_CMD_TEMPLATE"
  log "waiting until finalize is ready"
  wait_until_ready_for_finalize || die "SP did not become ready for finalize within timeout"

  log "starting finalize phase"
  local finalize_output
  finalize_output="$(run_template_command "finalize" "$FINALIZE_CMD_TEMPLATE")"
  log_tx_hash_if_present "finalize" "$finalize_output"

  log "waiting until SP is removed from chain"
  wait_until_removed || die "SP still exists on chain after finalize timeout"
  log "success: SP exit flow completed and chain verification passed"
}

run_manual_family_mode() {
  print_target_summary
  print_successor_summary
  print_manual_family_summary

  if [[ -z "$SUCCESSOR_SWAPIN_CMD_TEMPLATE" ]]; then
    SUCCESSOR_SWAPIN_CMD_TEMPLATE="$(default_manual_command_template swapin)"
  fi
  if [[ "$SKIP_MANUAL_RECOVER" == false && -z "$SUCCESSOR_RECOVER_CMD_TEMPLATE" && "$(manual_family_has_gvgs && echo yes || echo no)" == "yes" ]]; then
    SUCCESSOR_RECOVER_CMD_TEMPLATE="$(default_manual_command_template recover)"
  fi
  if [[ -z "$SUCCESSOR_COMPLETE_SWAPIN_CMD_TEMPLATE" ]]; then
    SUCCESSOR_COMPLETE_SWAPIN_CMD_TEMPLATE="$(default_manual_command_template complete-swapin)"
  fi
  if [[ "$SKIP_MANUAL_COMPLETE_SWAPOUT" == false && -z "$SUCCESSOR_COMPLETE_SWAPOUT_CMD_TEMPLATE" ]]; then
    SUCCESSOR_COMPLETE_SWAPOUT_CMD_TEMPLATE="$(default_manual_command_template complete-swapout)"
  fi

  log "manual family migration plan:"
  log "  step1 reserve swap-in on successor"
  log "  step2 recover-vgf on successor when family has GVGs"
  log "  step3 completeSwapIn on successor"
  log "  step4 optional debug complete swap-out on successor"
  log "  step5 verify family primary moved from source to successor"

  if [[ "$DRY_RUN" == true ]]; then
    log "successor swapIn command: $(render_template "$SUCCESSOR_SWAPIN_CMD_TEMPLATE")"
    if [[ -n "$SUCCESSOR_RECOVER_CMD_TEMPLATE" ]]; then
      log "successor recover-vgf command: $(render_template "$SUCCESSOR_RECOVER_CMD_TEMPLATE")"
    fi
    log "successor completeSwapIn command: $(render_template "$SUCCESSOR_COMPLETE_SWAPIN_CMD_TEMPLATE")"
    if [[ "$SKIP_MANUAL_COMPLETE_SWAPOUT" == false ]]; then
      log "successor complete swap-out command: $(render_template "$SUCCESSOR_COMPLETE_SWAPOUT_CMD_TEMPLATE")"
    fi
    log "dry-run complete"
    exit 0
  fi

  require_execution_template "--successor-swapin-cmd is required for manual family migration" "$SUCCESSOR_SWAPIN_CMD_TEMPLATE"
  require_execution_template "--successor-complete-swapin-cmd is required for manual family migration" "$SUCCESSOR_COMPLETE_SWAPIN_CMD_TEMPLATE"

  log "starting successor reserve swap-in"
  local swapin_output
  swapin_output="$(run_template_command "successor-swapin" "$SUCCESSOR_SWAPIN_CMD_TEMPLATE")"
  log_tx_hash_if_present "successor-swapin" "$swapin_output"

  if manual_family_has_gvgs && [[ "$SKIP_MANUAL_RECOVER" == false ]]; then
    require_execution_template "--successor-recover-cmd is required when the family has GVGs and recover is not skipped" "$SUCCESSOR_RECOVER_CMD_TEMPLATE"
    log "starting successor recover-vgf"
    run_template_command "successor-recover" "$SUCCESSOR_RECOVER_CMD_TEMPLATE" >/dev/null
  else
    log "recover-vgf skipped"
  fi

  log "starting successor completeSwapIn"
  local complete_swapin_output
  complete_swapin_output="$(run_template_command "successor-complete-swapin" "$SUCCESSOR_COMPLETE_SWAPIN_CMD_TEMPLATE")"
  log_tx_hash_if_present "successor-complete-swapin" "$complete_swapin_output"

  if [[ "$SKIP_MANUAL_COMPLETE_SWAPOUT" == false ]]; then
    require_execution_template "--successor-complete-swapout-cmd is required when debug complete swap-out is enabled" "$SUCCESSOR_COMPLETE_SWAPOUT_CMD_TEMPLATE"
    log "starting successor debug complete swap-out"
    local complete_swapout_output
    complete_swapout_output="$(run_template_command "successor-complete-swapout" "$SUCCESSOR_COMPLETE_SWAPOUT_CMD_TEMPLATE")"
    log_tx_hash_if_present "successor-complete-swapout" "$complete_swapout_output"
  fi

  log "waiting for family primary to switch to successor"
  wait_until_family_primary_changes || die "family $MANUAL_FAMILY_ID primary_sp_id did not switch to successor SP ID $SUCCESSOR_SP_ID"
  log "success: family $MANUAL_FAMILY_ID primary switched to successor $SUCCESSOR_MONIKER($SUCCESSOR_SP_ID)"
}

main() {
  parse_args "$@"
  need_cmd jq
  load_network_config
  resolve_target

  case "$MODE" in
    exit)
      run_exit_mode
      ;;
    manual-family)
      resolve_successor
      run_manual_family_mode
      ;;
    *)
      die "unsupported mode: $MODE"
      ;;
  esac
}

main "$@"
