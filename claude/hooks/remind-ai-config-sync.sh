#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)

AGENT_SYNC_ROOT="$ROOT" "$ROOT/bin/ai-config-sync" remind-claude
