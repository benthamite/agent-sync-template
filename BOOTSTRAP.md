# Bootstrap Prompt

Use this prompt when you want Claude Code or Codex to adapt the starter kit to a new machine.

```text
You are setting up my Claude Code and Codex synchronization repository.

First read README.md, ai-config-sync.json, install.sh, smoke-test.sh, and bin/ai-config-sync. Then run ./smoke-test.sh before touching my live ~/.claude or ~/.codex directories.

The goal is to keep Claude Code and Codex on equal footing. Do not treat either tool as the source and the other as a derived port. Maintain paired artifacts where the tools expose the same capability: global instructions, skills, hooks, and project-local counterparts.

Before changing live files under ~/.claude or ~/.codex, inspect what is already there. Do not overwrite real non-symlink files without explaining the conflict and asking me. If a file is mutable tool state, preserve it in place and merge the required configuration instead of symlinking it.

Adapt claude/CLAUDE.md and codex/AGENTS.md to my preferred agent rules. Adapt paired skills and hooks as needed. Keep ai-config-sync.json accurate. When you finish, run bin/ai-config-sync audit and ./smoke-test.sh, then explain what changed and what remains for me to review.
```
