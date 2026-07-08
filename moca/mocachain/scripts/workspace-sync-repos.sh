#!/usr/bin/env bash
# Sync all git repositories listed in a VS Code / Cursor multi-root workspace file:
# ensure each repo is on the target branch (default: main), then pull latest.
# Exception: folder basename go-ethereum uses develop.

set -u

abort() {
  echo "ABORT: $*" >&2
  exit 1
}

# go-ethereum tracks develop; all other roots use TARGET_BRANCH (-b, default main).
effective_branch_for_root() {
  local root="$1"
  case "$(basename "$root")" in
    go-ethereum) echo "develop" ;;
    *) echo "$TARGET_BRANCH" ;;
  esac
}

TARGET_BRANCH="main"
WORKSPACE_FILE=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: workspace-sync-repos.sh [options]

  -w, --workspace PATH   Path to .code-workspace file (see resolution below)
  -b, --branch NAME      Expected branch for all repos except go-ethereum (default: main)
  -n, --dry-run          Only check branch; do not pull
  -h, --help             Show this help

The go-ethereum workspace folder always uses branch develop (-b does not apply).
The documentation root entry (`name: obsidian`, `path: ..`) is skipped.

Workspace file resolution (first match wins):
  1) -w / --workspace
  2) MOCA_CODE_WORKSPACE environment variable
  3) Walk upward from current directory for mocachain.code-workspace
  4) Relative to this script: ../mocachain.code-workspace

Exit status: 0 if all repos succeed. Aborts immediately if a workspace folder is missing,
the target branch cannot be checked out, or (in non-dry-run) git pull fails.
EOF
}

# Switch git work tree at $1 to branch $2 after fetch; abort if branch is missing or switch fails.
checkout_target_branch() {
  local root="$1"
  local branch="$2"
  git -C "$root" fetch origin "$branch" 2>/dev/null || git -C "$root" fetch origin

  if git -C "$root" rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
    git -C "$root" switch "$branch" || abort "git switch failed in $root (branch $branch)"
    return 0
  fi
  if git -C "$root" rev-parse --verify --quiet "refs/remotes/origin/$branch" >/dev/null; then
    git -C "$root" switch -c "$branch" --track "origin/$branch" || abort "git switch --track failed in $root (branch $branch)"
    return 0
  fi
  abort "branch '$branch' does not exist locally or on origin in $root"
}

resolve_workspace_file() {
  if [[ -n "$WORKSPACE_FILE" ]]; then
    if [[ ! -f "$WORKSPACE_FILE" ]]; then
      echo "error: workspace file not found: $WORKSPACE_FILE" >&2
      exit 2
    fi
    realpath -mq "$WORKSPACE_FILE" 2>/dev/null || readlink -f "$WORKSPACE_FILE" 2>/dev/null || echo "$WORKSPACE_FILE"
    return
  fi

  if [[ -n "${MOCA_CODE_WORKSPACE:-}" ]]; then
    if [[ ! -f "$MOCA_CODE_WORKSPACE" ]]; then
      echo "error: MOCA_CODE_WORKSPACE not a file: $MOCA_CODE_WORKSPACE" >&2
      exit 2
    fi
    realpath -mq "$MOCA_CODE_WORKSPACE" 2>/dev/null || readlink -f "$MOCA_CODE_WORKSPACE" 2>/dev/null || echo "$MOCA_CODE_WORKSPACE"
    return
  fi

  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/mocachain.code-workspace" ]]; then
      realpath -mq "$dir/mocachain.code-workspace" 2>/dev/null || readlink -f "$dir/mocachain.code-workspace" 2>/dev/null || echo "$dir/mocachain.code-workspace"
      return
    fi
    dir="$(dirname "$dir")"
  done

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local candidate="$script_dir/../mocachain.code-workspace"
  candidate="$(realpath -mq "$candidate" 2>/dev/null || readlink -f "$candidate" 2>/dev/null || echo "$candidate")"
  if [[ -f "$candidate" ]]; then
    echo "$candidate"
    return
  fi

  echo "error: could not locate mocachain.code-workspace (use -w or set MOCA_CODE_WORKSPACE)" >&2
  exit 2
}

list_workspace_roots() {
  local ws="$1"
  python3 - "$ws" <<'PY'
import json
import os
import re
import sys

ws_path = os.path.abspath(sys.argv[1])
base = os.path.dirname(ws_path)
with open(ws_path, encoding="utf-8") as f:
    raw = f.read()
# VS Code allows trailing commas in workspace JSON; strip them for stdlib json.
raw = re.sub(r",(\s*[\]}])", r"\1", raw)
data = json.loads(raw)
for folder in data.get("folders", []):
    if folder.get("name") == "obsidian" or folder.get("path") == "..":
        continue
    p = folder.get("path")
    if not p:
        continue
    abs_p = os.path.normpath(os.path.join(base, p))
    print(abs_p)
PY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -w|--workspace)
      WORKSPACE_FILE="${2:-}"
      shift 2
      ;;
    -b|--branch)
      TARGET_BRANCH="${2:-}"
      shift 2
      ;;
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$TARGET_BRANCH" ]]; then
  echo "error: branch name must not be empty" >&2
  exit 2
fi

WS_ABS="$(resolve_workspace_file)"
echo "workspace: $WS_ABS"
echo "expected branch: $TARGET_BRANCH (go-ethereum: develop)"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "mode: dry-run (no pull)"
fi
echo ""

while IFS= read -r root; do
  [[ -z "$root" ]] && continue
  if [[ ! -d "$root" ]]; then
    abort "missing workspace directory: $root"
  fi
  if ! git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    abort "not a git repository: $root"
  fi

  want="$(effective_branch_for_root "$root")"
  current="$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  if [[ "$current" == "HEAD" ]] || [[ "$current" != "$want" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      if ! git -C "$root" rev-parse --verify --quiet "refs/heads/$want" >/dev/null; then
        if [[ -z "$(git -C "$root" ls-remote --heads origin "refs/heads/$want" 2>/dev/null | head -n 1)" ]]; then
          abort "branch '$want' does not exist locally or on origin in $root (dry-run)"
        fi
      fi
      if [[ "$current" == "HEAD" ]]; then
        echo "DRY  $root (detached HEAD -> would checkout $want)"
      else
        echo "DRY  $root (on '$current' -> would checkout $want)"
      fi
      continue
    fi
    echo "checkout $want in $root ..."
    checkout_target_branch "$root" "$want"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "OK  $root (branch $(git -C "$root" rev-parse --abbrev-ref HEAD))"
    continue
  fi

  echo "pull $root ..."
  git -C "$root" pull --ff-only || abort "git pull --ff-only failed in $root"
  echo "OK  $root"
done < <(list_workspace_roots "$WS_ABS")

exit 0
