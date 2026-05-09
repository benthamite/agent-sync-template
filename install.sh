#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$0")" && pwd)
STABLE="$HOME/.agent-sync-template"

link_path() {
  local source=$1
  local dest=$2
  mkdir -p -- "$(dirname -- "$dest")"
  if [ -L "$dest" ]; then
    ln -sfn -- "$source" "$dest"
  elif [ -e "$dest" ]; then
    printf 'Refusing to replace existing non-symlink: %s\n' "$dest" >&2
    printf 'Move it aside or merge it manually, then rerun install.sh.\n' >&2
    exit 1
  else
    ln -s -- "$source" "$dest"
  fi
}

if [ -L "$STABLE" ]; then
  ln -sfn -- "$ROOT" "$STABLE"
elif [ -e "$STABLE" ]; then
  printf 'Refusing to replace existing non-symlink: %s\n' "$STABLE" >&2
  exit 1
else
  ln -s -- "$ROOT" "$STABLE"
fi

mkdir -p -- "$HOME/.claude" "$HOME/.codex"

link_path "$ROOT/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link_path "$ROOT/claude/skills" "$HOME/.claude/skills"
link_path "$ROOT/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
link_path "$ROOT/codex/config.toml" "$HOME/.codex/config.toml"
link_path "$ROOT/codex/hooks.json" "$HOME/.codex/hooks.json"
link_path "$ROOT/codex/rules" "$HOME/.codex/rules"
link_path "$ROOT/codex/skills" "$HOME/.codex/skills"

python3 - "$HOME/.claude/settings.json" <<'PY'
from __future__ import annotations

import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

settings_path = Path(sys.argv[1])
settings_path.parent.mkdir(parents=True, exist_ok=True)

if settings_path.exists():
    try:
        data = json.loads(settings_path.read_text() or "{}")
    except Exception as exc:
        raise SystemExit(f"Invalid {settings_path}: {exc}")
    stamp = datetime.now().strftime("%Y%m%d%H%M%S")
    shutil.copy2(settings_path, settings_path.with_suffix(settings_path.suffix + f".bak.{stamp}"))
else:
    data = {}

hooks = data.setdefault("hooks", {})

def ensure_hook(event: str, matcher: str, command: str) -> None:
    entries = hooks.setdefault(event, [])
    entry = None
    for candidate in entries:
        if candidate.get("matcher") == matcher:
            entry = candidate
            break
    if entry is None:
        entry = {"matcher": matcher, "hooks": []}
        entries.append(entry)
    commands = {
        hook.get("command")
        for hook in entry.setdefault("hooks", [])
        if isinstance(hook, dict)
    }
    if command not in commands:
        entry["hooks"].append({"type": "command", "command": command})

ensure_hook(
    "PreToolUse",
    "Bash",
    "~/.agent-sync-template/claude/hooks/require-ai-config-sync.sh",
)
ensure_hook(
    "PostToolUse",
    "Edit|Write",
    "~/.agent-sync-template/claude/hooks/remind-ai-config-sync.sh",
)

settings_path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
PY

"$ROOT/bin/ai-config-sync" audit-live
