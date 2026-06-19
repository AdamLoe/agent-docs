# Codex Adapter

- Keep the working tree serial for mutating work unless the user explicitly
  assigns separate worktrees.
- Use commentary updates while working and final only after verification is
  complete.
- Stage by filename and never push unless the user asks.
- If generated context cannot be rendered, report the failing command and the
  missing repo setup instead of falling back to broad v1 discovery.
