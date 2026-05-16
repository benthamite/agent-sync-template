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
PROJECT="$TMP/project"
COMMIT_PROJECT="$TMP/commit-project"
mkdir -p \
  "$CONFIG_REPO/claude/skills/alpha" \
  "$CONFIG_REPO/codex/skills/alpha" \
  "$CONFIG_REPO/claude/hooks" \
  "$CONFIG_REPO/codex/hooks" \
  "$CONFIG_REPO/.codex"

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

cat > "$CONFIG_REPO/.mcp.json" <<'EOF'
{
  "mcpServers": {
    "sample": {
      "command": "/usr/bin/env",
      "args": ["npx", "-y", "sample-mcp"],
      "env": {
        "SAMPLE_TOKEN": "claude-secret"
      }
    }
  }
}
EOF

cat > "$CONFIG_REPO/.codex/config.toml" <<'EOF'
[mcp_servers.sample]
command = "/usr/bin/env"
args = ["npx", "-y", "sample-mcp"]

[mcp_servers.sample.env]
SAMPLE_TOKEN = "codex-secret"
EOF

mkdir -p -- "$PROJECT/.claude/skills/local" "$PROJECT/.codex/skills/local"
printf '# Project instructions\n' > "$PROJECT/CLAUDE.md"
printf '# Project instructions\n' > "$PROJECT/AGENTS.md"
printf '# Local Skill\n' > "$PROJECT/.claude/skills/local/SKILL.md"
printf '# Local Skill\n' > "$PROJECT/.codex/skills/local/SKILL.md"
git -C "$PROJECT" init -q
git -C "$PROJECT" add .
git -C "$PROJECT" commit -q -m baseline

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
    ],
    "mcp_servers": [
      {
        "name": "sample",
        "claude_config": "$CONFIG_REPO/.mcp.json",
        "codex_config": "$CONFIG_REPO/.codex/config.toml",
        "required_env": ["SAMPLE_TOKEN"]
      }
    ]
  },
  "project_local": {
    "project_roots": [
      "$TMP"
    ],
    "instruction_pairs": [
      {
        "claude": "CLAUDE.md",
        "codex": "AGENTS.md",
        "mode": "sibling",
        "normalizer": "instructions"
      }
    ],
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

mv "$PROJECT/AGENTS.md" "$PROJECT/AGENTS.md.bak"
if "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" audit >/dev/null 2>&1; then
  fail "project-local audit did not detect a missing AGENTS.md counterpart"
fi
mv "$PROJECT/AGENTS.md.bak" "$PROJECT/AGENTS.md"

mkdir -p -- "$COMMIT_PROJECT"
printf '# Commit Project\n' > "$COMMIT_PROJECT/CLAUDE.md"
printf '# Commit Project\n' > "$COMMIT_PROJECT/AGENTS.md"
git -C "$COMMIT_PROJECT" init -q
git -C "$COMMIT_PROJECT" add CLAUDE.md AGENTS.md
git -C "$COMMIT_PROJECT" commit -q -m baseline

printf '\nOne-sided combined edit.\n' >> "$COMMIT_PROJECT/CLAUDE.md"
if (cd "$COMMIT_PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git add CLAUDE.md && git commit -m one-sided-combined") >/dev/null 2>&1; then
  fail "one-sided project-local instruction edit was not blocked in git add && git commit"
fi
printf '\nOne-sided combined edit.\n' >> "$COMMIT_PROJECT/AGENTS.md"
if ! (cd "$COMMIT_PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git add CLAUDE.md AGENTS.md && git commit -m paired-combined") >/dev/null 2>&1; then
  fail "paired project-local instruction edit was blocked in git add && git commit"
fi
git -C "$COMMIT_PROJECT" add CLAUDE.md AGENTS.md
git -C "$COMMIT_PROJECT" commit -q -m paired-combined

printf '\nOne-sided commit-all edit.\n' >> "$COMMIT_PROJECT/AGENTS.md"
if (cd "$COMMIT_PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -am one-sided-commit-all") >/dev/null 2>&1; then
  fail "one-sided project-local instruction edit was not blocked in git commit -a"
fi
git -C "$COMMIT_PROJECT" show HEAD:AGENTS.md > "$COMMIT_PROJECT/AGENTS.md"

cp "$CONFIG_REPO/.codex/config.toml" "$CONFIG_REPO/.codex/config.toml.bak"
perl -0pi -e 's/sample-mcp/other-mcp/' "$CONFIG_REPO/.codex/config.toml"
if "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" audit >/dev/null 2>&1; then
  fail "MCP public config drift was not detected"
fi
mv "$CONFIG_REPO/.codex/config.toml.bak" "$CONFIG_REPO/.codex/config.toml"

printf '\nOne-sided global edit.\n' >> "$CONFIG_REPO/claude/skills/alpha/SKILL.md"
git -C "$CONFIG_REPO" add claude/skills/alpha/SKILL.md
if (cd "$CONFIG_REPO" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m one-sided") >/dev/null 2>&1; then
  fail "one-sided global skill edit was not blocked"
fi

printf '\nOne-sided global edit.\n' >> "$CONFIG_REPO/codex/skills/alpha/SKILL.md"
git -C "$CONFIG_REPO" add codex/skills/alpha/SKILL.md
(cd "$CONFIG_REPO" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m paired") >/dev/null

printf '\nOne-sided project instruction edit.\n' >> "$PROJECT/CLAUDE.md"
git -C "$PROJECT" add CLAUDE.md
if (cd "$PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m one-sided-instructions") >/dev/null 2>&1; then
  fail "one-sided project-local instruction edit was not blocked"
fi

printf '\nOne-sided project instruction edit.\n' >> "$PROJECT/AGENTS.md"
git -C "$PROJECT" add AGENTS.md
(cd "$PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m paired-instructions") >/dev/null

mkdir -p -- "$PROJECT/nested"
printf '# Nested instructions\n' > "$PROJECT/nested/CLAUDE.md"
printf '# Nested instructions\n' > "$PROJECT/nested/AGENTS.md"
git -C "$PROJECT" add nested/CLAUDE.md nested/AGENTS.md
git -C "$PROJECT" commit -q -m nested-baseline

printf '\nOne-sided nested instruction edit.\n' >> "$PROJECT/nested/AGENTS.md"
git -C "$PROJECT" add nested/AGENTS.md
if (cd "$PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m one-sided-nested-instructions") >/dev/null 2>&1; then
  fail "one-sided nested project-local instruction edit was not blocked"
fi

printf '\nOne-sided nested instruction edit.\n' >> "$PROJECT/nested/CLAUDE.md"
git -C "$PROJECT" add nested/CLAUDE.md
(cd "$PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m paired-nested-instructions") >/dev/null

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

REMINDER_OUTPUT=$(cd "$PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" remind --agent codex)
python3 - "$REMINDER_OUTPUT" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])
output = payload.get("hookSpecificOutput") or {}
if output.get("hookEventName") != "PostToolUse":
    raise SystemExit("Codex reminder is missing hookSpecificOutput.hookEventName")
if "additionalContext" not in output:
    raise SystemExit("Codex reminder is missing hookSpecificOutput.additionalContext")
PY

printf '{"hooks": {}}\n' > "$PROJECT/.codex/hooks.json"
git -C "$PROJECT" add .codex/hooks.json
if (cd "$PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m one-sided-hooks") >/dev/null 2>&1; then
  fail "one-sided project-local hook registration was not blocked"
fi

printf '{"hooks": {}}\n' > "$PROJECT/.claude/settings.json"
git -C "$PROJECT" add -f .claude/settings.json
(cd "$PROJECT" && "$ROOT/bin/ai-config-sync" --config "$CONFIG_REPO/ai-config-sync.json" guard-commit "git commit -m paired-hooks") >/dev/null

printf 'smoke-test: ok\n'
