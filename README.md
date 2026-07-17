# claude-baton

Pass the baton between Claude Code sessions instead of running them into the
ground. One command installs a complete session methodology into any project:
short sessions, written handoffs, and context-window warnings injected straight
into the agent.

## The problem

Two things silently degrade long Claude Code sessions:

1. **Auto-compact loses the detail.** When the context window fills up, the
   conversation is summarized and the fine-grained state of your work (what was
   tried, what failed, what is half-done) is gone.
2. **The agent is blind to its own context usage.** You can see the percentage
   in your statusline; the model cannot. It will happily start a large refactor
   at 85% of the window and hit the wall in the middle of it.

claude-baton replaces "one endless session" with a relay: every session starts
by reading a handoff, works with fresh context, and closes by writing the next
handoff. A hook warns the agent at 70% and 80% of the window so the close-out
happens in an orderly way, never mid-task.

## What gets installed (into your project)

| File | Purpose |
|------|---------|
| `.claude/hooks/context-warn.sh` | PostToolUse hook: reads token usage from the transcript and injects a warning to the agent at 70% and 80% of the window (once per threshold per session). |
| `.claude/settings.json` | Hook registration (merged into your existing settings, never clobbered). |
| `.claude/commands/handoff.md` | The `/handoff` slash command: writes a dated, accumulating handoff document. |
| `CLAUDE.md` | The "Sessions and handoffs" methodology section (appended between markers if you already have a CLAUDE.md). |
| `docs/handoff/` | Where handoffs live. They accumulate; the newest one is the next session's starting point. |

## Install

From your project root (must be a git repository; requires `jq`):

```bash
cd /path/to/your/project
curl -fsSL https://raw.githubusercontent.com/compota334/claude-baton/main/install.sh | bash
```

Or from a local clone:

```bash
git clone https://github.com/compota334/claude-baton.git
cd /path/to/your/project
bash /path/to/claude-baton/install.sh
```

The installer is idempotent: re-run it any time to update. It never overwrites
a file you have edited unless you pass `--force`:

```bash
curl -fsSL https://raw.githubusercontent.com/compota334/claude-baton/main/install.sh | bash -s -- --force
```

### After installing

- Restart Claude Code in the project (hooks load when a session starts).
- Per dev, once: run `claude update` (old versions do not support the hook) and
  `/statusline` (so the human sees the context % too). If you use a 1M-token
  window, add `"env": {"CLAUDE_CONTEXT_LIMIT": "1000000"}` to your
  `.claude/settings.local.json`; the hook default is 200k.
- Decide with your team whether the installed files get **committed** (shared
  methodology, recommended for teams: everyone's agent follows the same rules)
  or **gitignored** (personal setup). Same for `docs/handoff/`: commit it as
  shared team history, or ignore it as private notes.

## The cycle

```
new session
  -> agent reads the latest handoff in docs/handoff/
  -> agent checks git state (branch, remote, uncommitted work)
  -> work
  -> hook warns at 70%: finish what is open, no new large tasks
  -> hook warns at 80%: write the handoff NOW
  -> agent writes docs/handoff/YYYY-MM-DD_NAME_handoff.md, commits, pushes
  -> you rename the session (/rename DD-MM-YY short-title) and open a new one
  -> repeat
```

Handoff rules (the agent gets them from CLAUDE.md and `/handoff`):

- **Funnel structure**: general context, then what was done (with commit
  hashes), files touched, lessons learned (only real ones), pending work in
  order, and any operational state git does not capture (running services,
  which environment is the source of truth, resumable long jobs).
- **Handoffs accumulate**: never delete or overwrite old ones; that is why they
  carry dates. The newest is the starting point, the rest is history.
- **Close-out is literal**: the agent ends every session with copy-paste
  instructions for the human (rename the session, open a new one, first
  message: "read the handoff X and let's continue").

## How the hook works

Claude Code emits a JSONL transcript per session that includes per-message
token usage. On every tool call (PostToolUse, matcher `*`), the hook reads the
most recent usage entry, computes the percentage against
`CLAUDE_CONTEXT_LIMIT` (default 200000), and if it crossed 70% or 80% it
injects a warning into the agent's context via `additionalContext`. A marker
file in `/tmp` guarantees each threshold fires only once per session, so the
agent is nudged, not spammed.

## Uninstall

Delete `.claude/hooks/context-warn.sh` and `.claude/commands/handoff.md`,
remove the PostToolUse entry that references `context-warn.sh` from
`.claude/settings.json`, and delete the marker-delimited claude-baton section
from `CLAUDE.md`. Keep `docs/handoff/`: it is your project's history.

## License

[MIT](LICENSE)