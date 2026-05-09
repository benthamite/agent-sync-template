# Agent Sync Template

This is a starter kit for keeping Claude Code and Codex on equal footing. It gives both agents the same global instructions, equivalent skills, and equivalent hooks, while accounting for the fact that the two tools read different filenames and different hook registration formats.

The system has three parts:

1. A small source repository that stores the canonical Claude and Codex files side by side.
2. Symlinks from each tool's live config directory into that repository.
3. Audit and hook scripts that remind or block you when you edit only one side of a paired Claude/Codex artifact.

The template is intentionally small. It is meant to be copied, tested, and then expanded with your real instructions, skills, hooks, and project-local conventions.

## Layout

```text
agent-sync-template/
├── ai-config-sync.json
├── bin/
│   └── ai-config-sync
├── claude/
│   ├── CLAUDE.md
│   ├── hooks/
│   └── skills/
└── codex/
    ├── AGENTS.md
    ├── config.toml
    ├── hooks.json
    ├── hooks/
    ├── rules/
    └── skills/
```

`claude/` contains the files Claude Code should see. `codex/` contains the files Codex should see. The files are not always byte-for-byte identical, because the tools use different formats, but the audit script checks that paired files stay semantically synchronized.

## Install

Run this from the template checkout:

```sh
./install.sh
```

The installer creates a stable symlink at `~/.agent-sync-template`, then links the global Claude and Codex files into the live locations each tool reads:

```text
~/.claude/CLAUDE.md  -> ~/.agent-sync-template/claude/CLAUDE.md
~/.claude/skills     -> ~/.agent-sync-template/claude/skills
~/.codex/AGENTS.md   -> ~/.agent-sync-template/codex/AGENTS.md
~/.codex/config.toml -> ~/.agent-sync-template/codex/config.toml
~/.codex/hooks.json  -> ~/.agent-sync-template/codex/hooks.json
~/.codex/rules       -> ~/.agent-sync-template/codex/rules
~/.codex/skills      -> ~/.agent-sync-template/codex/skills
```

Claude Code stores some mutable settings in `~/.claude/settings.json`, so this template does not symlink that file. Instead, the installer backs it up and merges in hook registrations that point to `~/.agent-sync-template/claude/hooks/`.

Codex keeps hook registrations in `~/.codex/hooks.json` and global config in `~/.codex/config.toml`. Those are symlinked because this template expects them to be managed as source-controlled configuration.

## Verify

Before installing, run:

```sh
./smoke-test.sh
```

After installing, run:

```sh
bin/ai-config-sync audit-live
```

`audit` checks the template repository itself. `audit-live` also checks that the live `~/.claude` and `~/.codex` symlinks point where the template expects.

## Daily Use

When you edit a global Claude artifact, edit the corresponding Codex artifact in the same session, and vice versa. For example:

```text
claude/CLAUDE.md                 <-> codex/AGENTS.md
claude/skills/example/SKILL.md   <-> codex/skills/example/SKILL.md
claude/hooks/remind-*.sh         <-> codex/hooks/remind-*.sh
```

Project-local files are treated the same way. If a project contains `.claude/skills/foo/SKILL.md` and `.codex/skills/foo/SKILL.md`, the guard treats those as a paired local skill. The same applies to `.claude/hooks/` and `.codex/hooks/`, and to Claude/Codex hook registration files such as `.claude/settings.json` and `.codex/hooks.json`.

The hooks are a safety net, not the source of truth. The source of truth is the paired file layout plus the manifest in `ai-config-sync.json`.

## Adapting This Template

Start by editing:

```text
claude/CLAUDE.md
codex/AGENTS.md
claude/skills/example/SKILL.md
codex/skills/example/SKILL.md
ai-config-sync.json
```

Then run:

```sh
bin/ai-config-sync audit
./smoke-test.sh
```

If you add a new global skill, add both sides and record the pair in `ai-config-sync.json`. If you add a hook, add the Claude and Codex wrappers and update the relevant hook registration format for each tool.

For a reliable assisted setup, give `BOOTSTRAP.md` to Claude Code or Codex in a fresh session and ask it to adapt the template to your machine.
