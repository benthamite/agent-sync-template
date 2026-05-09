# Bootstrap Prompt

Use this prompt when you want Claude Code or Codex to adapt the toolkit to your existing setup.

```text
You are setting up a Claude Code / Codex synchronization toolkit.

First read README.md, ai-config-sync.example.json, smoke-test.sh, and bin/ai-config-sync. Run ./smoke-test.sh before touching any live Claude or Codex files.

Do not impose a new directory layout. Do not create symlinks unless I explicitly ask for them. Use my existing Claude and Codex file locations.

Create ai-config-sync.json from ai-config-sync.example.json and fill it with my real global paths: global instruction files, skill roots, hook roots, and hook registration files. If a path is ambiguous, inspect the filesystem and existing tool configuration before asking me.

Treat the project_local section as optional enforcement for project-specific agent files, not as a list of projects and not as a migration instruction. It is resolved relative to whichever git repository the agent is editing or committing. Do not create .claude/ or .codex/ directories in existing projects unless that project actually needs project-local agent files. Leave the defaults if I use .claude/ and .codex/ for project-local files, change them if I use different local paths, or set the arrays to [] if I do not want project-local enforcement.

Inventory my existing Claude and Codex skills and hooks. For each skill or hook that exists on only one side, create the missing counterpart in the configured location, adapting frontmatter, hook payload parsing, and registration syntax for the target tool. Do not treat either tool as the source of truth; the goal is paired behavior.

Update the relevant Claude and Codex hook registrations so the reminder hooks and commit guard run from this toolkit. Preserve mutable settings files in place and merge changes instead of overwriting unrelated settings.

When finished, run:

./smoke-test.sh
bin/ai-config-sync audit

Then summarize which paths are mapped, which skills/hooks were ported, which items intentionally diverge, and what I should review manually.
```
