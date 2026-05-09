#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$0")" && pwd)
TMP=$(mktemp -d)

cleanup() {
  if command -v trash >/dev/null 2>&1; then
    trash "$TMP"
  else
    printf 'Leaving smoke-test directory for manual cleanup: %s\n' "$TMP" >&2
  fi
}
trap cleanup EXIT

fail() {
  printf 'smoke-test failed: %s\n' "$1" >&2
  exit 1
}

export GIT_AUTHOR_NAME="Agent Sync Smoke Test"
export GIT_AUTHOR_EMAIL="agent-sync@example.invalid"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

AGENT_SYNC_ROOT="$ROOT" "$ROOT/bin/ai-config-sync" audit

COPY="$TMP/template"
mkdir -p -- "$COPY"
rsync -a --exclude '.git' --exclude 'tmp' "$ROOT/" "$COPY/"
git -C "$COPY" init -q
git -C "$COPY" add .
git -C "$COPY" commit -q -m baseline

printf '\nSmoke-test global edit.\n' >> "$COPY/claude/skills/example/SKILL.md"
git -C "$COPY" add claude/skills/example/SKILL.md
if (cd "$COPY" && AGENT_SYNC_ROOT="$COPY" "$COPY/bin/ai-config-sync" guard-commit "git commit -m one-sided") >/dev/null 2>&1; then
  fail "one-sided global skill edit was not blocked"
fi

printf '\nSmoke-test global edit.\n' >> "$COPY/codex/skills/example/SKILL.md"
git -C "$COPY" add codex/skills/example/SKILL.md
(cd "$COPY" && AGENT_SYNC_ROOT="$COPY" "$COPY/bin/ai-config-sync" guard-commit "git commit -m paired") >/dev/null

PROJECT="$TMP/project"
mkdir -p -- "$PROJECT/.claude/skills/local" "$PROJECT/.codex/skills/local"
printf '# Local Skill\n' > "$PROJECT/.claude/skills/local/SKILL.md"
printf '# Local Skill\n' > "$PROJECT/.codex/skills/local/SKILL.md"
git -C "$PROJECT" init -q
git -C "$PROJECT" add .
git -C "$PROJECT" commit -q -m baseline

printf '\nOne-sided local edit.\n' >> "$PROJECT/.codex/skills/local/SKILL.md"
git -C "$PROJECT" add .codex/skills/local/SKILL.md
if (cd "$PROJECT" && AGENT_SYNC_ROOT="$ROOT" "$ROOT/bin/ai-config-sync" guard-commit "git commit -m one-sided") >/dev/null 2>&1; then
  fail "one-sided project-local skill edit was not blocked"
fi
if AGENT_SYNC_ROOT="$ROOT" "$ROOT/bin/ai-config-sync" guard-commit "git -C $PROJECT commit -m one-sided" >/dev/null 2>&1; then
  fail "one-sided project-local skill edit was not blocked through git -C"
fi

printf '\nOne-sided local edit.\n' >> "$PROJECT/.claude/skills/local/SKILL.md"
git -C "$PROJECT" add .claude/skills/local/SKILL.md
(cd "$PROJECT" && AGENT_SYNC_ROOT="$ROOT" "$ROOT/bin/ai-config-sync" guard-commit "git commit -m paired") >/dev/null

printf '{"hooks": {}}\n' > "$PROJECT/.codex/hooks.json"
git -C "$PROJECT" add .codex/hooks.json
if (cd "$PROJECT" && AGENT_SYNC_ROOT="$ROOT" "$ROOT/bin/ai-config-sync" guard-commit "git commit -m one-sided-hooks") >/dev/null 2>&1; then
  fail "one-sided project-local hook registration was not blocked"
fi

printf '{"hooks": {}}\n' > "$PROJECT/.claude/settings.json"
git -C "$PROJECT" add -f .claude/settings.json
(cd "$PROJECT" && AGENT_SYNC_ROOT="$ROOT" "$ROOT/bin/ai-config-sync" guard-commit "git commit -m paired-hooks") >/dev/null

printf 'smoke-test: ok\n'
