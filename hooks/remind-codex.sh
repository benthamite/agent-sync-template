#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)
export AGENT_SYNC_CONFIG="${AGENT_SYNC_CONFIG:-$ROOT/ai-config-sync.json}"

"$ROOT/bin/ai-config-sync" remind --agent codex

