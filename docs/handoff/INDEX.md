# Handoff library index

The catalog of every session in this project. Each row links the three records
a session leaves behind: the **handoff file** in this folder (the written
summary), the **conversation** in the Claude Code session list (renamed with
`/rename` to the same date and title, kept un-compacted, reopenable at any
time with its full context intact), and the **commit range** in git history
(the code the session actually produced, with the commit messages as
line-by-line summaries of what was done).

How to find something:
1. Scan this table (dates, titles, topics, summaries).
2. Full-text search the handoffs: `grep -ri "<topic>" docs/handoff/`.
3. Want the code trail? `git log <first>..<last>` with the row's commit range:
   the commit messages narrate the session step by step.
4. Need the full reasoning? Reopen the matching conversation from your Claude
   Code session list: it has everything the handoff summarized.

Rows are append-only: never edit or delete existing rows.

| Date | Session (conversation name) | Handoff file | Dev | Commits | Topics | Summary |
|------|-----------------------------|--------------|-----|---------|--------|---------|
| 2026-07-22 | 22-07-26 relevio hasta v0.10 | 2026-07-22_relevio-hasta-v0.10.md | NICO | d85b8eb..2952789 | relevio, plugin, marketplace, hooks, contexto, worktrees | De claude-baton v0.2 a relevio v0.10: rename, plugin+marketplace, submission, checkpoints, reconciliacion de rama, detach de worktrees, ventana por modelo; desplegado en POLY y ARROTRACK |
