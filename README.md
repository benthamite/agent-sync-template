# Agent Sync Template

This is a small toolkit for keeping Claude Code and Codex configuration in sync without requiring a particular directory layout.

You tell the toolkit where your Claude files live and where your Codex files live. It then audits the mapped pairs and provides hook commands that remind or block an agent when it edits only one side.

It does not install sample skills. It does not require symlinks. It does not assume that your configuration lives inside this repository.

## Try It

Run the smoke test first:

```sh
./smoke-test.sh
```

The smoke test creates temporary Claude/Codex instruction files, skills, hooks, and project-local files. It then verifies that one-sided edits are blocked and paired edits are accepted.

## Configure Your Paths

Copy the example config:

```sh
cp ai-config-sync.example.json ai-config-sync.json
```

Then edit `ai-config-sync.json` so it points at your real files:

```json
{
  "global": {
    "file_pairs": [
      {
        "name": "global instructions",
        "claude": "~/.claude/CLAUDE.md",
        "codex": "~/.codex/AGENTS.md",
        "normalizer": "instructions"
      }
    ],
    "skill_roots": [
      {
        "name": "global skills",
        "claude": "~/.claude/skills",
        "codex": "~/.codex/skills"
      }
    ],
    "hook_roots": [
      {
        "name": "global hooks",
        "claude": "~/.claude/hooks",
        "codex": "~/.codex/hooks"
      }
    ]
  }
}
```

Those paths are examples. Use whatever paths your setup already uses.

The `global` section points to specific files and directories on your machine. Fill those in with your actual global Claude and Codex configuration paths.

The `project_local` section is different. It defines conventions relative to whatever git repository the agent is currently editing. The default means:

```text
PROJECT/.claude/skills/      <-> PROJECT/.codex/skills/
PROJECT/.claude/hooks/       <-> PROJECT/.codex/hooks/
PROJECT/.claude/settings.json <-> PROJECT/.codex/hooks.json
```

You do not need to create those directories in every project. They matter only in projects that already have project-local agent files, or in projects where you decide to add them. If an agent edits `PROJECT/.claude/skills/foo/SKILL.md`, the guard expects the corresponding `PROJECT/.codex/skills/foo/SKILL.md` to be edited too. If your projects use different local paths, change the `project_local` paths. If you do not want project-local enforcement, set those arrays to `[]`.

## Port Your Existing Files

After the paths are configured, port your existing skills and hooks so both tools have counterparts:

```text
Claude skill root / NAME / SKILL.md  <->  Codex skill root / NAME / SKILL.md
Claude hook root / HOOK              <->  Codex hook root / HOOK
Claude instructions                  <->  Codex instructions
```

The two sides do not need to be byte-for-byte identical. Claude and Codex may need different frontmatter, hook payload parsing, or registration syntax. They should implement the same behavior.

For an agent-assisted setup, open this repository in Claude Code or Codex and ask the agent to follow `BOOTSTRAP.md`. That prompt tells the agent to inventory your real files, create missing counterparts, preserve mutable settings, and run the audit.

## Audit

Run:

```sh
bin/ai-config-sync audit
```

Use `--config` if your mapping file lives elsewhere:

```sh
bin/ai-config-sync --config /path/to/ai-config-sync.json audit
```

The audit checks global instruction pairs, skill roots, hook roots, and registration pairs from the config. It reports missing counterparts and content drift after basic tool-specific normalization.

## Hook Commands

Register these commands in your existing Claude and Codex hook configuration:

```sh
/path/to/agent-sync-template/hooks/require-commit-sync.sh
/path/to/agent-sync-template/hooks/remind-claude.sh
/path/to/agent-sync-template/hooks/remind-codex.sh
```

If your `ai-config-sync.json` is not in the toolkit repo, set `AGENT_SYNC_CONFIG` in the hook command:

```sh
AGENT_SYNC_CONFIG=/path/to/ai-config-sync.json /path/to/agent-sync-template/hooks/require-commit-sync.sh
```

The reminder hooks run after edits. The commit guard runs before `git commit` and blocks staged one-sided changes. The same guard also handles project-local files using the `project_local` section of the config, such as:

```text
.claude/skills/      <-> .codex/skills/
.claude/hooks/       <-> .codex/hooks/
.claude/settings.json <-> .codex/hooks.json
```

Project-local paths are resolved inside the git repository being committed. They are not global paths and they are not scanned across your whole filesystem.

## Commands

```sh
bin/ai-config-sync audit
bin/ai-config-sync inventory
bin/ai-config-sync guard-commit "git commit -m message"
bin/ai-config-sync remind --agent claude
bin/ai-config-sync remind --agent codex
```

`inventory` prints the same missing or drifting pairs as the audit, but without framing it as a pass/fail check.
