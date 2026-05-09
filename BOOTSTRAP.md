# Bootstrap Prompt

Use this prompt when you want Claude Code or Codex to adapt the toolkit to your existing setup.

```text
You are setting up a Claude Code / Codex synchronization toolkit.

First read README.md, ai-config-sync.example.json, smoke-test.sh, and bin/ai-config-sync. Run ./smoke-test.sh before touching any live Claude or Codex files.

Do not impose a new directory layout. Do not create symlinks unless I explicitly ask for them. Use my existing Claude and Codex file locations.

Create ai-config-sync.json from ai-config-sync.example.json and fill it with my real global paths: global instruction files, skill roots, hook roots, and hook registration files. Infer these paths yourself from the filesystem and existing Claude/Codex configuration. Follow symlinks when needed to identify the real files. Ask me only if the relevant path cannot be inferred or if there are multiple plausible choices with different consequences.

For project_local, infer the right choice and document it in your summary: keep the defaults if my project-local files use .claude/ and .codex/ or if I do not currently use project-local files; edit the paths if my project-local files use different directories; set skill_roots, hook_roots, and registration_pairs to [] if I never want project-local checks. Ask me only if you cannot infer which of these choices applies. Do not create .claude/ or .codex/ directories in existing projects merely because this section exists.

Inventory my existing Claude and Codex skills and hooks. For each skill or hook that exists on only one side, create the missing counterpart in the configured location, adapting frontmatter, hook payload parsing, and registration syntax for the target tool. Do not treat either tool as the source of truth; the goal is paired behavior.

Update the relevant Claude and Codex hook registrations so the reminder hooks and commit guard run from this toolkit. Add the toolkit's hook commands to the user's existing hook configuration; do not leave this as a manual follow-up unless the user declines permission or the file format cannot be determined. Preserve mutable settings files in place and merge changes instead of overwriting unrelated settings.

When finished, run:

./smoke-test.sh
bin/ai-config-sync audit

Then summarize which paths are mapped, which skills/hooks were ported, which items intentionally diverge, and what I should review manually.
```
