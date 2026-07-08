#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

DEFAULT_HOSTS_CSV="test-sp0,test-sp1,test-sp2,test-sp3,test-sp4,test-sp5"
DEFAULT_TARGET_IP="54.38.38.12"
DEFAULT_SINCE="10m"
DEFAULT_RETENTION_DAYS="3"
DEFAULT_SSH_CONNECT_TIMEOUT="20"
DEFAULT_LCD_HOST="testnet-lcd.mocachain.org"
DEFAULT_RPC_HOST="testnet-rpc.mocachain.org"

HOSTS_CSV="$DEFAULT_HOSTS_CSV"
TARGET_IP="$DEFAULT_TARGET_IP"
SINCE="$DEFAULT_SINCE"
RETENTION_DAYS="$DEFAULT_RETENTION_DAYS"
SSH_CONNECT_TIMEOUT="$DEFAULT_SSH_CONNECT_TIMEOUT"
LCD_HOST="$DEFAULT_LCD_HOST"
RPC_HOST="$DEFAULT_RPC_HOST"
APPLY=false

SSH_OPTS=(
  -o BatchMode=yes
  -o ConnectTimeout="$SSH_CONNECT_TIMEOUT"
)

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME <subcommand> [options]

Run testnet SP checks and fixes from the local machine via SSH.

Subcommands:
  check-health          Check moca-sp container status on each host
  check-db-sync         Check database sync height on each host
  check-chain-access    Check hosts mapping, config endpoints, and recent chain access errors
  check-resources       Check memory, cache, data directory size, and legacy log size
  fix-chain-access      Fix hosts/config chain access settings (dry-run unless --apply)
  cleanup-legacy-logs   Remove legacy file logs (dry-run unless --apply)
  install-log-retention Install /etc/cron.daily/moca-sp-log-retention (dry-run unless --apply)
  verify                Run a concise post-change verification summary
  help                  Show this help

Options:
  --hosts CSV           Comma-separated hosts (default: $DEFAULT_HOSTS_CSV)
  --apply               Execute write operations for fix/install/cleanup commands
  --ip IP               Stable RPC IP for /etc/hosts mapping (default: $DEFAULT_TARGET_IP)
  --since DURATION      Docker log window, e.g. 10m, 1h (default: $DEFAULT_SINCE)
  --retention-days N    Delete legacy logs older than N days (default: $DEFAULT_RETENTION_DAYS)
  --ssh-timeout N       SSH connect timeout in seconds (default: $DEFAULT_SSH_CONNECT_TIMEOUT)
  --lcd-host HOST       LCD domain to manage (default: $DEFAULT_LCD_HOST)
  --rpc-host HOST       RPC domain to manage (default: $DEFAULT_RPC_HOST)
  -h, --help            Show this help

Examples:
  $SCRIPT_NAME check-health
  $SCRIPT_NAME check-db-sync
  $SCRIPT_NAME check-chain-access --hosts test-sp0,test-sp4 --since 30m
  $SCRIPT_NAME fix-chain-access --hosts test-sp0 --apply
  $SCRIPT_NAME cleanup-legacy-logs --hosts test-sp0,test-sp4
  $SCRIPT_NAME install-log-retention --apply
  $SCRIPT_NAME verify --hosts test-sp0,test-sp1
EOF
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

die() {
  log "ERROR: $*"
  exit 1
}

parse_args() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi

  SUBCOMMAND="$1"
  shift

  case "$SUBCOMMAND" in
    help|-h|--help)
      usage
      exit 0
      ;;
    check-health|check-db-sync|check-chain-access|check-resources|fix-chain-access|cleanup-legacy-logs|install-log-retention|verify)
      ;;
    *)
      die "unknown subcommand: $SUBCOMMAND"
      ;;
  esac

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --hosts)
        [[ $# -ge 2 ]] || die "--hosts requires a value"
        HOSTS_CSV="$2"
        shift 2
        ;;
      --apply)
        APPLY=true
        shift
        ;;
      --ip)
        [[ $# -ge 2 ]] || die "--ip requires a value"
        TARGET_IP="$2"
        shift 2
        ;;
      --since)
        [[ $# -ge 2 ]] || die "--since requires a value"
        SINCE="$2"
        shift 2
        ;;
      --retention-days)
        [[ $# -ge 2 ]] || die "--retention-days requires a value"
        RETENTION_DAYS="$2"
        shift 2
        ;;
      --ssh-timeout)
        [[ $# -ge 2 ]] || die "--ssh-timeout requires a value"
        SSH_CONNECT_TIMEOUT="$2"
        shift 2
        ;;
      --lcd-host)
        [[ $# -ge 2 ]] || die "--lcd-host requires a value"
        LCD_HOST="$2"
        shift 2
        ;;
      --rpc-host)
        [[ $# -ge 2 ]] || die "--rpc-host requires a value"
        RPC_HOST="$2"
        shift 2
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

parse_hosts() {
  local raw="$1"
  raw="${raw//[[:space:]]/}"
  IFS=',' read -r -a HOSTS <<<"$raw"
  [[ ${#HOSTS[@]} -gt 0 ]] || die "no hosts specified"
}

host_index() {
  local host="$1"
  if [[ "$host" =~ ^test-sp([0-9]+)$ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    die "host '$host' must match test-spN"
  fi
}

container_name_for_host() {
  local index
  index="$(host_index "$1")"
  echo "moca-sp${index}"
}

config_path_for_host() {
  local index
  index="$(host_index "$1")"
  echo "/data/moca/sp${index}/config.toml"
}

data_dir_for_host() {
  local index
  index="$(host_index "$1")"
  echo "/data/moca/sp${index}"
}

quote_env() {
  printf "%q" "$1"
}

validate_args() {
  [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]] || die "--retention-days must be a non-negative integer"
  [[ "$SSH_CONNECT_TIMEOUT" =~ ^[0-9]+$ ]] || die "--ssh-timeout must be a non-negative integer"
  [[ "$TARGET_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "--ip must look like an IPv4 address"
  SSH_OPTS=(
    -o BatchMode=yes
    -o ConnectTimeout="$SSH_CONNECT_TIMEOUT"
  )
}

run_remote_script() {
  local host="$1"
  local script="$2"
  shift 2

  local env_prefix=""
  while [[ $# -gt 0 ]]; do
    local key="$1"
    local value="$2"
    shift 2
    env_prefix+="${key}=$(quote_env "$value") "
  done

  ssh "${SSH_OPTS[@]}" "$host" "${env_prefix}bash -s" <<<"$script"
}

log_header() {
  local host="$1"
  log "=== $SUBCOMMAND on $host ==="
}

run_for_hosts() {
  local fn="$1"
  local failures=()
  local host

  for host in "${HOSTS[@]}"; do
    log_header "$host"
    if ! "$fn" "$host"; then
      log "FAILED: $SUBCOMMAND on $host"
      failures+=("$host")
    fi
    echo
  done

  if [[ ${#failures[@]} -gt 0 ]]; then
    die "subcommand '$SUBCOMMAND' failed on: ${failures[*]}"
  fi
}

check_health_host() {
  local host="$1"
  local container
  container="$(container_name_for_host "$host")"

  local remote_script
  remote_script=$(cat <<'EOF'
set -euo pipefail
docker inspect "$CONTAINER" --format 'container={{.Config.Hostname}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} status={{.State.Status}} restart={{.RestartCount}}'
EOF
)

  run_remote_script "$host" "$remote_script" \
    CONTAINER "$container"
}

check_db_sync_host() {
  local host="$1"
  local config_path container
  config_path="$(config_path_for_host "$host")"
  container="$(container_name_for_host "$host")"

  local remote_script
  remote_script=$(cat <<'EOF'
set -euo pipefail
command -v python3 >/dev/null
command -v mysql >/dev/null

eval "$(python3 - <<'PY'
import shlex
from pathlib import Path

config_path = Path(__import__("os").environ["CONFIG_PATH"])
current = None
values = {}
chain_address = ""

for raw_line in config_path.read_text().splitlines():
    line = raw_line.strip()
    if not line or line.startswith("#"):
        continue
    if line.startswith("[") and line.endswith("]"):
        current = line[1:-1].strip()
        continue
    if current == "Chain" and line.startswith("ChainAddress") and "=" in line:
        value = line.split("=", 1)[1].split("#", 1)[0].strip()
        if "[" in value and "]" in value:
            inner = value[value.find("[") + 1:value.rfind("]")]
            first = inner.split(",", 1)[0].strip()
            if first.startswith(("'", '"')) and first.endswith(("'", '"')):
                chain_address = first[1:-1]
        continue
    if current != "BsDB" or "=" not in line:
        continue
    key, value = line.split("=", 1)
    key = key.strip()
    value = value.split("#", 1)[0].strip()
    if value.startswith(("'", '"')) and value.endswith(("'", '"')):
        value = value[1:-1]
    values[key] = value

address = values.get("Address", "")
if not address:
    raise SystemExit("missing BsDB.Address in config.toml")

if ":" in address:
    db_host, db_port = address.rsplit(":", 1)
else:
    db_host, db_port = address, "3306"

required = {
    "DB_USER": values.get("User", ""),
    "DB_PASSWD": values.get("Passwd", ""),
    "DB_NAME": values.get("Database", ""),
    "DB_HOST": db_host,
    "DB_PORT": db_port,
    "CHAIN_RPC": chain_address,
}
missing = [k for k, v in required.items() if not v]
if missing:
    raise SystemExit("missing BsDB fields: " + ", ".join(missing))

for key, value in required.items():
    print(f"{key}={shlex.quote(value)}")
PY
)"

echo "--- db"
echo "database=$DB_NAME address=$DB_HOST:$DB_PORT user=$DB_USER"
epoch_row="$(MYSQL_PWD="$DB_PASSWD" mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" -N -B -e "SELECT block_height, update_time FROM epoch ORDER BY block_height DESC LIMIT 1;" 2>/dev/null || true)"
epoch_height=""
epoch_update_time=""
if [[ -n "$epoch_row" ]]; then
  IFS=$'\t' read -r epoch_height epoch_update_time <<<"$epoch_row"
fi
echo "epoch_block_height=$epoch_height"
echo "epoch_update_time=$epoch_update_time"

chain_info="$(CHAIN_RPC="$CHAIN_RPC" python3 - <<'PY'
import json
import os
import urllib.request

url = os.environ["CHAIN_RPC"].rstrip("/") + "/status"
try:
    with urllib.request.urlopen(url, timeout=8) as response:
        payload = json.load(response)
    latest_height = payload["result"]["sync_info"]["latest_block_height"]
    latest_time = payload["result"]["sync_info"]["latest_block_time"]
    print(f"{latest_height}\t{latest_time}")
except Exception:
    pass
PY
)"
chain_height=""
chain_time=""
if [[ -n "$chain_info" ]]; then
  IFS=$'\t' read -r chain_height chain_time <<<"$chain_info"
fi
echo "chain_latest_height=$chain_height"
echo "chain_latest_time=$chain_time"

if [[ -n "$epoch_height" && -n "$chain_height" ]]; then
  lag_blocks=$((chain_height - epoch_height))
  echo "lag_blocks=$lag_blocks"
else
  lag_blocks=""
  echo "lag_blocks="
fi

estimate="$(docker logs --since "$SINCE" "$CONTAINER" 2>&1 | python3 - <<'PY'
import datetime as dt
import re
import sys

height_re = re.compile(r'height\s*:?\s*([0-9]+)')
time_re = re.compile(r'"t":"([^"]+)"')
samples = []

for raw in sys.stdin:
    h = height_re.search(raw)
    if not h:
        continue
    t = time_re.search(raw)
    if not t:
        continue
    try:
        ts = dt.datetime.fromisoformat(t.group(1).replace("Z", "+00:00"))
        samples.append((ts.timestamp(), int(h.group(1))))
    except Exception:
        continue

if len(samples) < 2:
    sys.exit(0)

first_ts, first_height = samples[0]
last_ts, last_height = samples[-1]
elapsed = last_ts - first_ts
progress = last_height - first_height
if elapsed <= 0 or progress <= 0:
    sys.exit(0)

rate = progress / elapsed
print(f"{first_height}\t{last_height}\t{elapsed:.0f}\t{rate:.6f}")
PY
)"
echo "--- summary"
echo "--- sync_estimate"
if [[ -n "$estimate" && -n "$lag_blocks" ]]; then
  IFS=$'\t' read -r first_height last_height elapsed_seconds blocks_per_second <<<"$estimate"
  rate_pretty="$(BLOCKS_PER_SECOND="$blocks_per_second" python3 - <<'PY'
import os
print(f"{float(os.environ['BLOCKS_PER_SECOND']):.2f}")
PY
)"
  eta_seconds="$(LAG_BLOCKS="$lag_blocks" BLOCKS_PER_SECOND="$blocks_per_second" python3 - <<'PY'
import os
lag = float(os.environ["LAG_BLOCKS"])
rate = float(os.environ["BLOCKS_PER_SECOND"])
if rate <= 0:
    raise SystemExit(0)
print(int(lag / rate))
PY
)"
  eta_human="$(ETA_SECONDS="$eta_seconds" python3 - <<'PY'
import os
seconds = int(os.environ["ETA_SECONDS"])
days, rem = divmod(seconds, 86400)
hours, rem = divmod(rem, 3600)
minutes, seconds = divmod(rem, 60)
parts = []
if days:
    parts.append(f"{days}d")
if hours:
    parts.append(f"{hours}h")
if minutes:
    parts.append(f"{minutes}m")
parts.append(f"{seconds}s")
print(" ".join(parts))
PY
)"
  eta_at="$(ETA_SECONDS="$eta_seconds" python3 - <<'PY'
import datetime as dt
import os
seconds = int(os.environ["ETA_SECONDS"])
target = dt.datetime.now().astimezone() + dt.timedelta(seconds=seconds)
print(target.strftime("%Y-%m-%d %H:%M:%S %Z"))
PY
)"
  echo "summary current=$epoch_height chain=$chain_height lag=$lag_blocks rate=${rate_pretty}blk/s eta=$eta_human eta_at=\"$eta_at\""
  echo "rate_window_start_height=$first_height"
  echo "rate_window_end_height=$last_height"
  echo "rate_window_elapsed_seconds=$elapsed_seconds"
  echo "sync_rate_blocks_per_second=$blocks_per_second"
  echo "estimated_catchup_seconds=$eta_seconds"
  echo "estimated_catchup=$eta_human"
  echo "estimated_catchup_at=$eta_at"
else
  echo "summary current=$epoch_height chain=$chain_height lag=$lag_blocks rate=unknown eta=unknown eta_at=unknown"
  echo "sync_rate_blocks_per_second="
  echo "estimated_catchup="
  echo "estimated_catchup_at="
fi

echo "--- migrate_subscribe_progress"
MYSQL_PWD="$DB_PASSWD" mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" -N -B -e "SELECT event_name, last_subscribed_block_height FROM migrate_subscribe_progress ORDER BY event_name;" 2>/dev/null | while IFS=$'\t' read -r event_name subscribed_height; do
  [[ -n "${event_name:-}" ]] || continue
  echo "${event_name}=${subscribed_height}"
done || true
EOF
)

  run_remote_script "$host" "$remote_script" \
    CONFIG_PATH "$config_path" \
    CONTAINER "$container" \
    SINCE "$SINCE"
}

check_chain_access_host() {
  local host="$1"
  local container config_path
  container="$(container_name_for_host "$host")"
  config_path="$(config_path_for_host "$host")"

  local remote_script
  remote_script=$(cat <<'EOF'
set -euo pipefail
echo "--- hosts"
grep -E "(${LCD_HOST}|${RPC_HOST})" /etc/hosts || true
echo "--- config"
sed -n '/ChainAddress/p;/RpcAddress/p' "$CONFIG_PATH"
echo "--- recent errors"
docker logs --since "$SINCE" "$CONTAINER" 2>&1 | egrep '403 Forbidden|certificate signed by unknown authority|missing port in address|get latest block height failed|failed to list storage providers|failed to get block from node' | tail -n 20 || true
EOF
)

  run_remote_script "$host" "$remote_script" \
    CONTAINER "$container" \
    CONFIG_PATH "$config_path" \
    SINCE "$SINCE" \
    LCD_HOST "$LCD_HOST" \
    RPC_HOST "$RPC_HOST"
}

check_resources_host() {
  local host="$1"
  local container data_dir
  container="$(container_name_for_host "$host")"
  data_dir="$(data_dir_for_host "$host")"

  local remote_script
  remote_script=$(cat <<'EOF'
set -euo pipefail
echo "--- free"
free -h
echo "--- meminfo"
egrep 'MemTotal|MemFree|MemAvailable|Cached:|Buffers:|Active\(|Inactive\(|AnonPages|Slab|SReclaimable|SUnreclaim' /proc/meminfo
echo "--- docker stats"
echo "container mem_usage cpu"
docker stats --no-stream --format '{{.Name}} {{.MemUsage}} {{.CPUPerc}}' "$CONTAINER"
echo "--- data size"
du -sh "$DATA_DIR" 2>/dev/null
echo "--- legacy log size"
du -ch "$DATA_DIR"/moca-sp.log.* "$DATA_DIR"/logs.* 2>/dev/null | tail -n 1 || true
EOF
)

  run_remote_script "$host" "$remote_script" \
    CONTAINER "$container" \
    DATA_DIR "$data_dir"
}

fix_chain_access_host() {
  local host="$1"
  local container config_path
  container="$(container_name_for_host "$host")"
  config_path="$(config_path_for_host "$host")"

  local remote_script
  remote_script=$(cat <<'EOF'
set -euo pipefail
echo "--- before hosts"
grep -E "(${LCD_HOST}|${RPC_HOST})" /etc/hosts || true
echo "--- before config"
sed -n '/ChainAddress/p;/RpcAddress/p' "$CONFIG_PATH"

if [[ "$APPLY_MODE" != "true" ]]; then
  echo "DRY-RUN: would ensure /etc/hosts contains:"
  echo "  $TARGET_IP $RPC_HOST"
  echo "  $TARGET_IP $LCD_HOST"
  echo "DRY-RUN: would update config to:"
  echo "  ChainAddress = ['http://$LCD_HOST:80']"
  echo "  RpcAddress = ['http://$RPC_HOST:80']"
  exit 0
fi

command -v python3 >/dev/null
cp -a /etc/hosts "/etc/hosts.bak.$(date +%Y%m%d%H%M%S)"
cp -a "$CONFIG_PATH" "$CONFIG_PATH.bak.$(date +%Y%m%d%H%M%S)"

python3 - <<'PY'
import os
import re
from pathlib import Path

target_ip = os.environ["TARGET_IP"]
lcd_host = os.environ["LCD_HOST"]
rpc_host = os.environ["RPC_HOST"]
config_path = Path(os.environ["CONFIG_PATH"])

hosts_path = Path("/etc/hosts")
lines = hosts_path.read_text().splitlines()
def should_drop(line: str) -> bool:
    fields = line.split()
    return rpc_host in fields or lcd_host in fields

filtered = [line for line in lines if not should_drop(line)]
filtered.append(f"{target_ip} {rpc_host}")
filtered.append(f"{target_ip} {lcd_host}")
hosts_path.write_text("\n".join(filtered) + "\n")

text = config_path.read_text()
text, chain_count = re.subn(r"^ChainAddress\s*=.*$", f"ChainAddress = ['http://{lcd_host}:80']", text, count=1, flags=re.M)
text, rpc_count = re.subn(r"^RpcAddress\s*=.*$", f"RpcAddress = ['http://{rpc_host}:80']", text, count=1, flags=re.M)
if chain_count != 1 or rpc_count != 1:
    raise SystemExit("failed to update ChainAddress/RpcAddress in config.toml")
config_path.write_text(text)
PY

docker restart "$CONTAINER" >/dev/null
sleep 3

echo "--- after hosts"
grep -E "(${LCD_HOST}|${RPC_HOST})" /etc/hosts || true
echo "--- after config"
sed -n '/ChainAddress/p;/RpcAddress/p' "$CONFIG_PATH"
echo "--- container"
docker inspect "$CONTAINER" --format 'health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} status={{.State.Status}} restart={{.RestartCount}}'
EOF
)

  run_remote_script "$host" "$remote_script" \
    APPLY_MODE "$APPLY" \
    TARGET_IP "$TARGET_IP" \
    LCD_HOST "$LCD_HOST" \
    RPC_HOST "$RPC_HOST" \
    CONTAINER "$container" \
    CONFIG_PATH "$config_path"
}

cleanup_legacy_logs_host() {
  local host="$1"
  local data_dir
  data_dir="$(data_dir_for_host "$host")"

  local remote_script
  remote_script=$(cat <<'EOF'
set -euo pipefail
command -v python3 >/dev/null
python3 - <<'PY'
import os
import time
from pathlib import Path

data_dir = Path(os.environ["DATA_DIR"])
apply_mode = os.environ["APPLY_MODE"] == "true"
retention_days = int(os.environ["RETENTION_DAYS"])

paths = sorted(
    p for pattern in ("moca-sp.log.*", "logs.*")
    for p in data_dir.glob(pattern)
    if p.is_file()
)
now = time.time()
cutoff = retention_days * 86400
paths = [p for p in paths if retention_days == 0 or now - p.stat().st_mtime > cutoff]
total = sum(p.stat().st_size for p in paths)

print(f"retention_days={retention_days}")
print(f"matches={len(paths)} total_gb={total/1024/1024/1024:.2f}")
for path in paths[:10]:
    print(path)
if len(paths) > 10:
    print(f"... {len(paths) - 10} more")

if apply_mode:
    for path in paths:
        path.unlink()
    print("deleted=true")
else:
    print("deleted=false")
PY
EOF
)

  run_remote_script "$host" "$remote_script" \
    APPLY_MODE "$APPLY" \
    DATA_DIR "$data_dir" \
    RETENTION_DAYS "$RETENTION_DAYS"
}

install_log_retention_host() {
  local host="$1"

  local remote_script
  remote_script=$(cat <<'EOF'
set -euo pipefail
SCRIPT_PATH="/etc/cron.daily/moca-sp-log-retention"

cat <<PLAN
script_path=$SCRIPT_PATH
retention_days=$RETENTION_DAYS
patterns=moca-sp.log.* logs.*
PLAN

if [[ "$APPLY_MODE" != "true" ]]; then
  echo "DRY-RUN: would install the following script:"
  cat <<SCRIPT
#!/bin/sh
set -eu

for dir in /data/moca/sp[0-9]; do
  [ -d "\$dir" ] || continue
  find "\$dir" -maxdepth 1 -type f \( -name "moca-sp.log.*" -o -name "logs.*" \) -mtime +$RETENTION_DAYS -delete
done
SCRIPT
  exit 0
fi

cat > "$SCRIPT_PATH" <<SCRIPT
#!/bin/sh
set -eu

for dir in /data/moca/sp[0-9]; do
  [ -d "\$dir" ] || continue
  find "\$dir" -maxdepth 1 -type f \( -name "moca-sp.log.*" -o -name "logs.*" \) -mtime +$RETENTION_DAYS -delete
done
SCRIPT

chmod 755 "$SCRIPT_PATH"
sh -n "$SCRIPT_PATH"
"$SCRIPT_PATH"
ls -l "$SCRIPT_PATH"
EOF
)

  run_remote_script "$host" "$remote_script" \
    APPLY_MODE "$APPLY" \
    RETENTION_DAYS "$RETENTION_DAYS"
}

verify_host() {
  local host="$1"
  local container data_dir
  container="$(container_name_for_host "$host")"
  data_dir="$(data_dir_for_host "$host")"

  local remote_script
  remote_script=$(cat <<'EOF'
set -euo pipefail
echo "--- container"
docker inspect "$CONTAINER" --format 'health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} status={{.State.Status}} restart={{.RestartCount}}'
echo "--- docker logging"
docker inspect "$CONTAINER" --format '{{json .HostConfig.LogConfig}}'
echo "--- chain config"
sed -n '/ChainAddress/p;/RpcAddress/p' "$CONFIG_PATH"
echo "--- hosts"
grep -E "(${LCD_HOST}|${RPC_HOST})" /etc/hosts || true
echo "--- legacy file count"
find "$DATA_DIR" -maxdepth 1 -type f \( -name 'moca-sp.log.*' -o -name 'logs.*' \) | wc -l
echo "--- recent chain errors"
docker logs --since "$SINCE" "$CONTAINER" 2>&1 | egrep '403 Forbidden|certificate signed by unknown authority|missing port in address|get latest block height failed|failed to list storage providers|failed to get block from node' | tail -n 20 || true
EOF
)

  run_remote_script "$host" "$remote_script" \
    CONTAINER "$container" \
    DATA_DIR "$data_dir" \
    CONFIG_PATH "$(config_path_for_host "$host")" \
    SINCE "$SINCE" \
    LCD_HOST "$LCD_HOST" \
    RPC_HOST "$RPC_HOST"
}

main() {
  parse_args "$@"
  parse_hosts "$HOSTS_CSV"
  validate_args

  log "Subcommand:      $SUBCOMMAND"
  log "Hosts:           $HOSTS_CSV"
  log "Apply mode:      $APPLY"
  log "Since:           $SINCE"
  log "Retention days:  $RETENTION_DAYS"
  log "Target IP:       $TARGET_IP"

  case "$SUBCOMMAND" in
    check-health)
      run_for_hosts check_health_host
      ;;
    check-db-sync)
      run_for_hosts check_db_sync_host
      ;;
    check-chain-access)
      run_for_hosts check_chain_access_host
      ;;
    check-resources)
      run_for_hosts check_resources_host
      ;;
    fix-chain-access)
      run_for_hosts fix_chain_access_host
      ;;
    cleanup-legacy-logs)
      run_for_hosts cleanup_legacy_logs_host
      ;;
    install-log-retention)
      run_for_hosts install_log_retention_host
      ;;
    verify)
      run_for_hosts verify_host
      ;;
    *)
      die "unsupported subcommand: $SUBCOMMAND"
      ;;
  esac
}

main "$@"
