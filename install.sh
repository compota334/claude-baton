#!/usr/bin/env bash
# claude-baton installer
# Installs the sessions-and-handoffs methodology for Claude Code into the
# CURRENT directory (your project root).
#
# Usage:
#   cd /path/to/your/project
#   curl -fsSL https://raw.githubusercontent.com/compota334/claude-baton/main/install.sh | bash
#   # or, from a local clone:
#   bash /path/to/claude-baton/install.sh
#
# Re-run to update. Files you have modified are never overwritten unless you
# pass --force:
#   curl -fsSL .../install.sh | bash -s -- --force
set -euo pipefail

VERSION="0.1.0"
REPO_RAW="https://raw.githubusercontent.com/compota334/claude-baton/main"
TEMPLATES=(context-warn.sh handoff.md CLAUDE.md.section)
MARK_START="<!-- claude-baton:start -->"
MARK_END="<!-- claude-baton:end -->"

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h|--help)
      sed -n '2,14p' "$0" 2>/dev/null || true
      exit 0 ;;
    *) echo "ERROR: unknown argument: $arg (only --force is supported)" >&2; exit 1 ;;
  esac
done

fail() { echo "ERROR: $*" >&2; exit 1; }
info() { echo "  $*"; }

echo "claude-baton v${VERSION} installer"
echo "Target project: $(pwd)"
echo

# --- Preconditions (fail loud, never install half-broken) -------------------
command -v jq >/dev/null 2>&1 || fail "jq is required (the context hook parses transcripts with it).
       Install it first: sudo apt install jq   |   brew install jq"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "this directory is not a git repository.
       The methodology relies on commits, pushes and handoff history.
       cd into your project, or run 'git init' first."

# --- Locate templates: local clone, or fetch from GitHub --------------------
SRC="${BASH_SOURCE[0]:-}"
if [ -n "$SRC" ] && [ -f "$(dirname "$SRC")/templates/context-warn.sh" ]; then
  TPL="$(cd "$(dirname "$SRC")/templates" && pwd)"
  [ "$(dirname "$TPL")" = "$(pwd)" ] && fail "you are running the installer inside the claude-baton repo itself.
       cd into YOUR project first, then run: bash $(pwd)/install.sh"
  info "using local templates: $TPL"
else
  command -v curl >/dev/null 2>&1 || fail "curl is required for the remote install."
  TPL="$(mktemp -d)"
  trap 'rm -rf "$TPL"' EXIT
  for f in "${TEMPLATES[@]}"; do
    curl -fsSL "$REPO_RAW/templates/$f" -o "$TPL/$f" \
      || fail "could not download $f from $REPO_RAW"
  done
  info "downloaded templates from GitHub"
fi
echo

# --- Helper: copy a template, refusing to clobber local edits ---------------
install_file() {
  local src="$1" dest="$2" mode="$3"
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    info "unchanged: $dest"
    return 0
  fi
  if [ -f "$dest" ] && [ "$FORCE" -ne 1 ]; then
    fail "$dest already exists and differs from the template.
       Re-run with --force to overwrite it (your local edits will be lost)."
  fi
  cp "$src" "$dest"
  chmod "$mode" "$dest"
  info "installed: $dest"
}

# --- 1. Hook + slash command ------------------------------------------------
mkdir -p .claude/hooks .claude/commands
install_file "$TPL/context-warn.sh" .claude/hooks/context-warn.sh 755
install_file "$TPL/handoff.md" .claude/commands/handoff.md 644

# --- 2. Register the hook in .claude/settings.json (merge, don't clobber) ---
SETTINGS=".claude/settings.json"
HOOK_ENTRY='{"matcher":"*","hooks":[{"type":"command","command":"\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/context-warn.sh"}]}'
if [ ! -f "$SETTINGS" ]; then
  jq -n --argjson e "$HOOK_ENTRY" '{"hooks":{"PostToolUse":[$e]}}' > "$SETTINGS"
  info "installed: $SETTINGS"
elif jq -e '.hooks.PostToolUse[]?.hooks[]?.command // empty | select(contains("context-warn.sh"))' \
       "$SETTINGS" >/dev/null 2>&1; then
  info "unchanged: $SETTINGS (hook already registered)"
else
  jq -e . "$SETTINGS" >/dev/null 2>&1 || fail "$SETTINGS exists but is not valid JSON. Fix it, then re-run."
  TMP="$(mktemp)"
  jq --argjson e "$HOOK_ENTRY" \
     '.hooks.PostToolUse = ((.hooks.PostToolUse // []) + [$e])' \
     "$SETTINGS" > "$TMP"
  mv "$TMP" "$SETTINGS"
  info "updated: $SETTINGS (hook registered, existing settings preserved)"
fi

# --- 3. CLAUDE.md methodology section (marker-delimited, idempotent) --------
if [ ! -f CLAUDE.md ]; then
  { echo "# Instructions for agents"; echo; cat "$TPL/CLAUDE.md.section"; } > CLAUDE.md
  info "installed: CLAUDE.md"
elif grep -qF "$MARK_START" CLAUDE.md; then
  if [ "$FORCE" -eq 1 ]; then
    awk -v s="$MARK_START" -v e="$MARK_END" \
      'index($0,s){skip=1} !skip{print} index($0,e){skip=0}' CLAUDE.md > CLAUDE.md.tmp
    { echo; cat "$TPL/CLAUDE.md.section"; } >> CLAUDE.md.tmp
    mv CLAUDE.md.tmp CLAUDE.md
    info "updated: CLAUDE.md (claude-baton section refreshed, moved to the end)"
  else
    info "unchanged: CLAUDE.md (claude-baton section already present; --force refreshes it)"
  fi
else
  { echo; cat "$TPL/CLAUDE.md.section"; } >> CLAUDE.md
  info "updated: CLAUDE.md (claude-baton section appended)"
fi

# --- 4. Handoff folder ------------------------------------------------------
mkdir -p docs/handoff
touch docs/handoff/.gitkeep
info "ready: docs/handoff/"

# --- Done -------------------------------------------------------------------
cat <<'EOF'

Done. Next steps:

  1. The hook loads when a session STARTS: restart Claude Code (or open a new
     session) in this project.
  2. Per dev, once:
       - claude update            (old versions do not support the hook)
       - /statusline              (see your own context % as the human)
       - 1M window? Add "env": {"CLAUDE_CONTEXT_LIMIT": "1000000"}
         to your .claude/settings.local.json
  3. Decide with your team whether CLAUDE.md, .claude/settings.json,
     .claude/commands/ and .claude/hooks/ get COMMITTED (shared methodology,
     recommended for teams) or gitignored (personal setup). docs/handoff/ can
     be committed as shared history or ignored as private notes.

Start your next session with: "read the latest handoff in docs/handoff/ and
let's continue" (the first session has none: just start working, the first
handoff will be written when the session closes).
EOF