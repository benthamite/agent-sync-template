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

CONFIG_REPO="$TMP/config"
mkdir -p \
  "$CONFIG_REPO/claude/skills/alpha" \
  "$CONFIG_REPO/codex/skills/alpha" \
  "$CONFIG_REPO/claude/hooks" \
  "$CONFIG_REPO/codex/hooks"

cat > "$CONFIG_REPO/claude/CLAUDE.md" <<'EOF'
# Global Claude instructions

- Keep paired agent files synchronized.
EOF

cat > "$CONFIG_REPO/codex/AGENTS.md" <<'EOF'
# Global Codex instructions

- Keep paired agent files synchronized.
EOF

cat > "$CONFIG_REPO/claude/skills/alpha/SKILL.md" <<'EOF'
---
name: alpha
description: Smoke-test skill.
allowed-tools: Bash
---

# Alpha

Do the alpha workflow.
EOF

cat > "$CONFIG_REPO/codex/skills/alpha/SKILL.md" <<'EOF'
---
name: alpha
description: Smoke-test skill.
---

# Alpha

Do the alpha workflow.
EOF

cat > "$CONFIG_REPO/claude/hooks/sync.sh" <<'EOF'
#!/usr/bin/env bash
echo sync
EOF

cat > "$CONFIG_REPO/codex/hooks/sync.sh" <<'EOF'
#!/usr/bin/env bash
echo sync
EOF

cat > "$CONFIG_REPO/ai-config-sync.json" <<EOF
{
  "global": {
    "file_pairs": [
      {
        "name": "global instructions",
        "claude": "$CONFIG_REPO/claude/CLAUDE.md",
        "codex": "$CONFIG_REPO/codex/AGENTS.md",
        "normalizer": "instructions"
      }
    ],
    "skill_roots": [
      {
        "name": "global skills",
        "claude": "$CONFIG_REPO/claude/skills",
        "codex": "$CONFIG_REPO/codex/skills"
      }
    ],
    "hook_roots": [
      {
        "name": "global hooks",
        "claude": "$CONFIG_REPO/claude/hooks",
        "codex": "$CONFIG_REPO/codex/hooks"
      }
    ]
  },
  "project_local": {
    "skill_roots": [
      {
        "claude": ".claude/skills",
        "codex": ".codex/skills"
      }
    ],
    "hook_roots": [
      {
        "claude": ".claude/hooks",
        "codex": ".codex/hooks"
      }
    ],
    "registration_pairs": [
      {
        "claude": ".claude/settings.json",
        "codex": ".codex/hooks.json"
      }
    ]
  },
  "ignore": []
}
EOF

git -C "$CONFIG_REPO" init -q
git -C "$CONFIG_REPO" add .
git -C "$CONFIG_REPO" commit -q -m baseline

"$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" audit

printf '\nOne-sided global edit.\n' >> "$CONFIG_REPO/claude/skills/alpha/SKILL.md"
git -C "$CONFIG_REPO" add claude/skills/alpha/SKILL.md
if (cd "$CONFIG_REPO" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m one-sided") >/dev/null 2>&1; then
  fail "one-sided global skill edit was not blocked"
fi

printf '\nOne-sided global edit.\n' >> "$CONFIG_REPO/codex/skills/alpha/SKILL.md"
git -C "$CONFIG_REPO" add codex/skills/alpha/SKILL.md
(cd "$CONFIG_REPO" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m paired") >/dev/null

PROJECT="$TMP/project"
mkdir -p -- "$PROJECT/.claude/skills/local" "$PROJECT/.codex/skills/local"
printf '# Local Skill\n' > "$PROJECT/.claude/skills/local/SKILL.md"
printf '# Local Skill\n' > "$PROJECT/.codex/skills/local/SKILL.md"
git -C "$PROJECT" init -q
git -C "$PROJECT" add .
git -C "$PROJECT" commit -q -m baseline

printf '\nOne-sided local edit.\n' >> "$PROJECT/.codex/skills/local/SKILL.md"
git -C "$PROJECT" add .codex/skills/local/SKILL.md
if (cd "$PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m one-sided") >/dev/null 2>&1; then
  fail "one-sided project-local skill edit was not blocked"
fi
if "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git -C $PROJECT commit -m one-sided" >/dev/null 2>&1; then
  fail "one-sided project-local skill edit was not blocked through git -C"
fi

printf '\nOne-sided local edit.\n' >> "$PROJECT/.claude/skills/local/SKILL.md"
git -C "$PROJECT" add .claude/skills/local/SKILL.md
(cd "$PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m paired") >/dev/null

printf '{"hooks": {}}\n' > "$PROJECT/.codex/hooks.json"
git -C "$PROJECT" add .codex/hooks.json
if (cd "$PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m one-sided-hooks") >/dev/null 2>&1; then
  fail "one-sided project-local hook registration was not blocked"
fi

printf '{"hooks": {}}\n' > "$PROJECT/.claude/settings.json"
git -C "$PROJECT" add -f .claude/settings.json
(cd "$PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m paired-hooks") >/dev/null

printf 'smoke-test: ok\n'
