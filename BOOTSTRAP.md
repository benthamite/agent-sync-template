# Bootstrap Prompt

Use this prompt when you want Claude Code or Codex to adapt the toolkit to your existing setup.

```text
You are setting up a Claude Code / Codex synchronization toolkit.

Do the setup yourself. Do not ask the user to clone the repository, run tests, locate config files, port skills/hooks, or register hooks if you can do those steps locally.

If this repository is not already cloned locally, clone https://github.com/benthamite/agent-sync-template.git first and work from that clone.

First read README.md, ai-config-sync.example.json, smoke-test.sh, and bin/ai-config-sync. Run ./smoke-test.sh before touching any live Claude or Codex files.

Implement the synchronization contract from https://stafforini.com/notes/how-i-keep-claude-code-and-codex-in-sync/ without copying any particular machine's directory layout. Infer and use my existing Claude and Codex file locations. Do not impose a new directory layout. Do not create symlinks unless I explicitly ask for them.

The required contract is: Claude and Codex artifacts are peer implementations of the same agent behavior; neither side is canonical; every paired instruction file, skill, hook, hook registration, and configured MCP server must have a counterpart unless the setup records an explicit intentional divergence in the summary and leaves it out of enforcement; hooks must remind immediately after one-sided edits; commit hooks must block one-sided commits, including `git add ... && git commit ...`, `git -C ... commit ...`, and `git commit -a`; and the final audit must fail if any inventoried paired artifact is missing or drifting.

Create ai-config-sync.json from ai-config-sync.example.json and fill it with my real global paths: global instruction files, skill roots, hook roots, and hook registration files. Infer these paths yourself from the filesystem and existing Claude/Codex configuration. Follow symlinks when needed to identify the real files. Ask me only if the relevant path cannot be inferred or if there are multiple plausible choices with different consequences.

For project_local, infer the right choice and document it in your summary: keep the defaults if my project-local files use sibling CLAUDE.md/AGENTS.md plus .claude/ and .codex/, or if I do not currently use project-local files; edit the paths if my project-local files use different directories; set instruction_pairs, skill_roots, hook_roots, registration_pairs, and project_roots to [] if I never want project-local checks. Add project_roots for repositories or parent directories whose existing project-local files you inventory during bootstrap, so the final audit can verify that the counterpart creation actually happened. Ask me only if you cannot infer which of these choices applies. Do not create .claude/ or .codex/ directories in existing projects merely because this section exists.

Inventory existing project-local instruction files in the target project areas. For every project-local CLAUDE.md that is not the configured global Claude instruction file, create or update a sibling AGENTS.md counterpart, adapting Claude-only syntax such as standalone @file imports into Codex-safe path references. Do not rely on Codex reading CLAUDE.md as a project-doc fallback unless the user explicitly wants that older model.

Inventory my existing Claude and Codex skills and hooks. For each skill or hook that exists on only one side, create the missing counterpart in the configured location, adapting frontmatter, hook payload parsing, and registration syntax for the target tool. Do not treat either tool as the source of truth; the goal is paired behavior.

Inventory my existing MCP server configuration. Claude Code and Codex do not automatically share MCP servers. If both tools should expose the same service, add an `mcp_servers` entry to `ai-config-sync.json` with the Claude config path, Codex config path, server names, required environment-variable names, and an identity-check command when one exists. Never print or diff secret values. If an MCP server intentionally exists on only one side, leave it out of `mcp_servers` and mention the divergence in your summary.

Update the relevant Claude and Codex hook registrations so the reminder hooks and commit guard run from this toolkit. Add the toolkit's hook commands to the user's existing hook configuration; do not leave this as a manual follow-up unless the user declines permission or the file format cannot be determined. Preserve mutable settings files in place and merge changes instead of overwriting unrelated settings.

When finished, run:

./smoke-test.sh
bin/ai-config-sync audit

Also run a live enforcement check in a temporary git repository or safe throwaway project: verify that a one-sided staged commit is blocked and that a one-sided `git add ... && git commit ...` command is blocked. Do not call setup complete if either command is allowed through.

Then summarize which paths are mapped, which skills/hooks were ported, which items intentionally diverge, and what I should review manually.
```
