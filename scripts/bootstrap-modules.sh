#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DOCURA_DIR="$ROOT_DIR/docura-backend"
INTELLIGENCE_DIR="$ROOT_DIR/intelligence-service"

DOCURA_REPO_URL="git@github.com:sarathkumar365/docura-backend.git"
INTELLIGENCE_REPO_URL="git@github.com:sarathkumar365/intelligence-service.git"
DEFAULT_BRANCH="main"

usage() {
  cat <<USAGE
Usage:
  scripts/bootstrap-modules.sh [--clone-only]

Behavior:
  - If module folder is missing: clone it.
  - If module folder exists and is a git repo: fetch + pull --ff-only.

Flags:
  --clone-only   Clone missing repos only; do not pull existing repos.
USAGE
}

CLONE_ONLY="false"
if [[ "${1:-}" == "--clone-only" ]]; then
  CLONE_ONLY="true"
elif [[ $# -gt 0 ]]; then
  usage
  exit 1
fi

sync_repo() {
  local name="$1"
  local dir="$2"
  local url="$3"

  if [[ ! -d "$dir" ]]; then
    echo "[$name] missing -> cloning"
    git clone "$url" "$dir"
    return
  fi

  if [[ ! -d "$dir/.git" ]]; then
    echo "[$name] exists but is not a git repository: $dir" >&2
    echo "[$name] please move/remove this directory and run again." >&2
    exit 1
  fi

  if [[ "$CLONE_ONLY" == "true" ]]; then
    echo "[$name] exists -> clone-only mode, skipping update"
    return
  fi

  echo "[$name] exists -> fetching"
  git -C "$dir" fetch origin "$DEFAULT_BRANCH"

  local current_branch
  current_branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD)"

  if [[ "$current_branch" != "$DEFAULT_BRANCH" ]]; then
    echo "[$name] current branch is '$current_branch'; skipping auto-pull (expected '$DEFAULT_BRANCH')."
    echo "[$name] run manual update if needed: git -C "$dir" pull --ff-only origin $current_branch"
    return
  fi

  echo "[$name] pulling latest $DEFAULT_BRANCH"
  git -C "$dir" pull --ff-only origin "$DEFAULT_BRANCH"
}

echo "Bootstrapping Corvanta module repositories..."
sync_repo "docura-backend" "$DOCURA_DIR" "$DOCURA_REPO_URL"
sync_repo "intelligence-service" "$INTELLIGENCE_DIR" "$INTELLIGENCE_REPO_URL"
echo "Done."
