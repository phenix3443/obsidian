#!/usr/bin/env bash
# Task-scoped helper for the testnet-validator snapshot notes.
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DEFAULT_NETWORK="testnet"
DEFAULT_RPC_URL_TESTNET="https://testnet-lcd.mocachain.org"
DEFAULT_RPC_URL_DEVNET_2="https://tm-rpc.devnet-2.mocachain.dev"
DEFAULT_MOCAD_BIN="/Users/liushangliang/github/mocachain/moca/build/mocad"
FORMAT="json"
NETWORK="$DEFAULT_NETWORK"
RPC_URL=""
MOCAD_BIN="$DEFAULT_MOCAD_BIN"

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [--network testnet|devnet-2] [--format json|markdown] [--rpc-url URL] [--mocad-bin PATH]

Query the current Moca validator set and print a merged summary.

Options:
  --network NAME    Built-in network: testnet or devnet-2 (default: $DEFAULT_NETWORK)
  --format FORMAT   Output format: json or markdown (default: json)
  --rpc-url URL     CometBFT RPC endpoint override
  --mocad-bin PATH  mocad binary path (default: $DEFAULT_MOCAD_BIN)
  -h, --help        Show this help

Examples:
  $SCRIPT_NAME
  $SCRIPT_NAME --network devnet-2
  $SCRIPT_NAME --format markdown
  $SCRIPT_NAME --rpc-url $DEFAULT_RPC_URL_TESTNET
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --network)
        [[ $# -ge 2 ]] || {
          echo "--network requires a value" >&2
          exit 1
        }
        NETWORK="$2"
        shift 2
        ;;
      --format)
        [[ $# -ge 2 ]] || {
          echo "--format requires a value" >&2
          exit 1
        }
        FORMAT="$2"
        shift 2
        ;;
      --rpc-url)
        [[ $# -ge 2 ]] || {
          echo "--rpc-url requires a value" >&2
          exit 1
        }
        RPC_URL="$2"
        shift 2
        ;;
      --mocad-bin)
        [[ $# -ge 2 ]] || {
          echo "--mocad-bin requires a value" >&2
          exit 1
        }
        MOCAD_BIN="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  case "$FORMAT" in
    json|markdown)
      ;;
    *)
      echo "--format must be json or markdown" >&2
      exit 1
      ;;
  esac

  case "$NETWORK" in
    testnet|devnet-2)
      ;;
    *)
      echo "--network must be testnet or devnet-2" >&2
      exit 1
      ;;
  esac

  if [[ -z "$RPC_URL" ]]; then
    case "$NETWORK" in
      testnet)
        RPC_URL="$DEFAULT_RPC_URL_TESTNET"
        ;;
      devnet-2)
        RPC_URL="$DEFAULT_RPC_URL_DEVNET_2"
        ;;
    esac
  fi
}

query_json() {
  local status_file validators_file staking_file slashing_file params_file
  local queried_at
  local summary_json

  status_file="$(mktemp)"
  validators_file="$(mktemp)"
  staking_file="$(mktemp)"
  slashing_file="$(mktemp)"
  params_file="$(mktemp)"
  queried_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  curl -sSL --max-time 20 "$RPC_URL/status" >"$status_file"
  curl -sSL --max-time 20 "$RPC_URL/validators?page=1&per_page=100" >"$validators_file"
  "$MOCAD_BIN" query staking validators --node "$RPC_URL" --output json >"$staking_file"
  "$MOCAD_BIN" query slashing signing-infos --node "$RPC_URL" --output json >"$slashing_file"
  "$MOCAD_BIN" query staking params --node "$RPC_URL" --output json >"$params_file"

  summary_json="$(jq -n \
    --arg queried_at "$queried_at" \
    --arg network "$NETWORK" \
    --arg rpc_url "$RPC_URL" \
    --slurpfile status "$status_file" \
    --slurpfile consensus "$validators_file" \
    --slurpfile staking "$staking_file" \
    --slurpfile slashing "$slashing_file" \
    --slurpfile params "$params_file" '
    def staking_consensus_key:
      .consensus_pubkey.value // .consensus_pubkey.key;
    def slashing_index:
      reduce $slashing[0].info[] as $item
        ({};
          .[(($item.address | ltrimstr("0x")) | ascii_upcase)] = $item
        );
    ($consensus[0].result.validators) as $active
    | ($active | map(.voting_power | tonumber) | add) as $total_voting_power
    | ($active | map(.pub_key.value)) as $active_pubkeys
    | (slashing_index) as $slashing_by_address
    | {
        queried_at: $queried_at,
        network: $network,
        rpc_url: $rpc_url,
        chain_id: $status[0].result.node_info.network,
        latest_block_height: ($status[0].result.sync_info.latest_block_height | tonumber),
        latest_block_time: $status[0].result.sync_info.latest_block_time,
        latest_block_hash: $status[0].result.sync_info.latest_block_hash,
        staking_params: $params[0].params,
        active_validator_count: ($active | length),
        staking_validator_count: ($staking[0].validators | length),
        total_voting_power: $total_voting_power,
        active_validators: [
          $active[] as $validator
          | ($staking[0].validators[] | select((staking_consensus_key) == $validator.pub_key.value)) as $staking_validator
          | ($slashing_by_address[$validator.address] // {}) as $slashing_info
          | {
              moniker: $staking_validator.description.moniker,
              consensus_address: $validator.address,
              consensus_pubkey: $validator.pub_key.value,
              operator_address: $staking_validator.operator_address,
              status: $staking_validator.status,
              jailed: ($staking_validator.jailed // false),
              voting_power: ($validator.voting_power | tonumber),
              power_share_pct: ((($validator.voting_power | tonumber) / $total_voting_power) * 100),
              commission_rate: $staking_validator.commission.commission_rates.rate,
              tokens: $staking_validator.tokens,
              website: ($staking_validator.description.website // ""),
              relayer_address: ($staking_validator.relayer_address // null),
              challenger_address: ($staking_validator.challenger_address // null),
              missed_blocks_counter: (($slashing_info.missed_blocks_counter // "0") | tonumber),
              jailed_until: ($slashing_info.jailed_until // "1970-01-01T00:00:00Z")
            }
        ],
        inactive_validators: [
          $staking[0].validators[]
          | . as $staking_validator
          | select($active_pubkeys | index($staking_validator | staking_consensus_key) | not)
          | {
              moniker: .description.moniker,
              operator_address: .operator_address,
              consensus_pubkey: (staking_consensus_key),
              status: .status,
              jailed: (.jailed // false),
              commission_rate: .commission.commission_rates.rate,
              tokens: .tokens,
              unbonding_time: .unbonding_time
            }
        ]
      }')"

  rm -f "$status_file" "$validators_file" "$staking_file" "$slashing_file" "$params_file"
  printf '%s\n' "$summary_json"
}

print_markdown() {
  local summary_json
  summary_json="$(query_json)"

  jq -r '
    def round4: ((. * 10000 | round) / 10000);
    def round2: ((. * 100 | round) / 100);
    "## Moca Validator Snapshot",
    "",
    "- queried_at: `\(.queried_at)`",
    "- network: `\(.network)`",
    "- chain_id: `\(.chain_id)`",
    "- latest_block_height: `\(.latest_block_height)`",
    "- latest_block_time: `\(.latest_block_time)`",
    "- rpc_url: `\(.rpc_url)`",
    "",
    "### Active Validators",
    "",
    "| Moniker | Status | Voting Power | Share | Commission | Operator | Missed Blocks |",
    "| --- | --- | ---: | ---: | ---: | --- | ---: |",
    (.active_validators[] | "| `\(.moniker)` | `\(.status)` | \(.voting_power) | \(.power_share_pct | round4)% | \((.commission_rate | tonumber) * 100 | round2)% | `\(.operator_address)` | \(.missed_blocks_counter) |"),
    "",
    "### Inactive Validators",
    "",
    "| Moniker | Status | Jailed | Tokens | Operator | Unbonding Time |",
    "| --- | --- | --- | ---: | --- | --- |",
    (.inactive_validators[] | "| `\(.moniker)` | `\(.status)` | `\(.jailed)` | `\(.tokens)` | `\(.operator_address)` | `\(.unbonding_time)` |")
  ' <<<"$summary_json"
}

main() {
  parse_args "$@"

  require_cmd curl
  require_cmd jq
  [[ -x "$MOCAD_BIN" ]] || {
    echo "mocad binary is not executable: $MOCAD_BIN" >&2
    exit 1
  }

  case "$FORMAT" in
    json)
      query_json
      ;;
    markdown)
      print_markdown
      ;;
  esac
}

main "$@"
