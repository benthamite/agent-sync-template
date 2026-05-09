# Global Codex conventions

- Keep Claude Code and Codex counterparts synchronized when editing global instructions, skills, hooks, or project-local agent files.
- When changing a paired artifact, update the counterpart in the same session.
- Run `~/.agent-sync-template/bin/ai-config-sync audit` before committing global agent configuration changes.
- Prefer root-cause fixes over local workarounds, and verify changes before calling them done.
- State uncertainty plainly when assumptions are weak or when tool behavior may have changed.
