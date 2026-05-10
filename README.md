# Agent Sync Template

This is a small toolkit for keeping Claude Code and Codex configuration in sync without requiring a particular directory layout. It is a companion to my note [How I keep Claude Code and Codex in sync](https://stafforini.com/notes/how-i-keep-claude-code-and-codex-in-sync/).

The setup agent infers where your Claude files live and where your Codex files live, records those paths in a small config file, ports missing counterparts, and registers hook commands that remind or block an agent when it edits only one side.

It does not install sample skills. It does not require symlinks. It does not assume that your configuration lives inside this repository.

## Quick start

Give Claude Code or Codex this prompt:

```text
Set up Claude Code <> Codex synchronization using https://github.com/benthamite/agent-sync-template.

- Clone the repository to a sensible local location if it is not already available.
- Run its smoke test before touching my live Claude or Codex configuration.
- Then follow BOOTSTRAP.md exactly.
```

## What the agent writes

The generated `ai-config-sync.json` maps your real Claude and Codex files. It will look roughly like this, but with paths inferred from your machine:

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
  },
  "project_local": {
    "instruction_pairs": [
      {
        "name": "project-local instructions",
        "claude": "CLAUDE.md",
        "codex": "AGENTS.md",
        "mode": "sibling",
        "normalizer": "instructions"
      }
    ],
    "skill_roots": [
      {
        "name": "project-local skills",
        "claude": ".claude/skills",
        "codex": ".codex/skills"
      }
    ],
    "hook_roots": [
      {
        "name": "project-local hooks",
        "claude": ".claude/hooks",
        "codex": ".codex/hooks"
      }
    ],
    "registration_pairs": [
      {
        "name": "project-local hook registrations",
        "claude": ".claude/settings.json",
        "codex": ".codex/hooks.json"
      }
    ]
  }
}
```

The `global` section points to specific files and directories on your machine.

For `project_local`, the agent should make one of these choices and explain it in its summary:

```text
Keep the defaults   if project-local files use sibling CLAUDE.md/AGENTS.md
                    and .claude/ / .codex/,
                    or if you do not currently use project-local files.
Edit the paths      if your project-local files use different directories.
Set arrays to []    if you never want project-local checks.
```

Keeping the defaults does not create any directories and does not require you to change existing projects. It just says what the guard should do if a future edit or commit touches one of those paths inside the current git repository.

The default convention means:

```text
PROJECT/CLAUDE.md             <-> PROJECT/AGENTS.md
PROJECT/path/CLAUDE.md        <-> PROJECT/path/AGENTS.md
PROJECT/.claude/skills/      <-> PROJECT/.codex/skills/
PROJECT/.claude/hooks/       <-> PROJECT/.codex/hooks/
PROJECT/.claude/settings.json <-> PROJECT/.codex/hooks.json
```

That means: if an agent edits `PROJECT/CLAUDE.md`, the guard expects `PROJECT/AGENTS.md` to be edited too; if it edits `PROJECT/docs/CLAUDE.md`, the guard expects `PROJECT/docs/AGENTS.md`. Likewise, if an agent edits `PROJECT/.claude/skills/foo/SKILL.md`, the guard expects the corresponding `PROJECT/.codex/skills/foo/SKILL.md` to be edited too. If the project has no local agent files, nothing happens. If the project has only one side and you edit it, the guard will ask you to port the counterpart or disable/change the `project_local` rule.

## Ported files

The setup agent should port your existing skills and hooks so both tools have counterparts:

```text
Claude skill root / NAME / SKILL.md  <->  Codex skill root / NAME / SKILL.md
Claude hook root / HOOK              <->  Codex hook root / HOOK
Claude instructions                  <->  Codex instructions
Project CLAUDE.md                    <->  sibling AGENTS.md
```

The two sides do not need to be byte-for-byte identical. Claude and Codex may need different frontmatter, hook payload parsing, or registration syntax. They should implement the same behavior.

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

## Hook commands

`BOOTSTRAP.md` asks the setup agent to register the hooks for you. This section shows the commands that need to end up in your Claude and Codex hook configuration:

```sh
/path/to/agent-sync-template/hooks/require-commit-sync.sh
/path/to/agent-sync-template/hooks/remind-claude.sh
/path/to/agent-sync-template/hooks/remind-codex.sh
```

If your `ai-config-sync.json` is not in the toolkit repo, the registered hook command should set `AGENT_SYNC_CONFIG`:

```sh
AGENT_SYNC_CONFIG=/path/to/ai-config-sync.json /path/to/agent-sync-template/hooks/require-commit-sync.sh
```

The reminder hooks run after edits. The commit guard runs before `git commit` and blocks staged one-sided changes. The same guard can also handle optional project-local files using the `project_local` section of the config, such as:

```text
CLAUDE.md              <-> AGENTS.md
path/CLAUDE.md         <-> path/AGENTS.md
.claude/skills/      <-> .codex/skills/
.claude/hooks/       <-> .codex/hooks/
.claude/settings.json <-> .codex/hooks.json
```

Project-local paths are resolved inside the git repository being committed. They are not global paths, they are not scanned across your whole filesystem, and they do not require changing projects that do not use project-local agent configuration.

## Commands

```sh
bin/ai-config-sync audit
bin/ai-config-sync inventory
bin/ai-config-sync guard-commit "git commit -m message"
bin/ai-config-sync remind --agent claude
bin/ai-config-sync remind --agent codex
```

`inventory` prints the same missing or drifting pairs as the audit, but without framing it as a pass/fail check.
