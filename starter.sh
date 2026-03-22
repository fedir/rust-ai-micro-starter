#!/usr/bin/env bash
# starter.sh — launch Claude Code or OpenCode with zero token overlap.
#
# Each tool sees only its own files. Skills are moved to the native path
# of the chosen tool and restored on exit (even on crash / Ctrl+C).
#
# Usage:
#   ./starter.sh                        # interactive prompt
#   ./starter.sh claude                 # direct launch
#   ./starter.sh opencode               # direct launch
#   ./starter.sh opencode run "..."     # pass args to the tool
#   ./starter.sh claude --resume        # pass args to the tool
#
# Optional — both tools work without this script.
# Recommended when a single tool is used consistently, to prevent
# duplicate context files from burning tokens on every invocation.

set -euo pipefail

# ── pick tool ────────────────────────────────────────────────────────────────
if   [ "${1:-}" = "claude" ];   then TOOL=claude;   shift
elif [ "${1:-}" = "opencode" ]; then TOOL=opencode; shift
else
  echo "Select AI tool:"
  select TOOL in claude opencode; do [ -n "$TOOL" ] && break; done
fi

echo "→ Activating for $TOOL..."

# ── helpers ──────────────────────────────────────────────────────────────────
hide()    { [ -e "$1" ] && mv "$1" "$1.off" && echo "  hide  $1"; }
restore() { [ -e "$1.off" ] && mv "$1.off" "$1" && echo "  restore  $1"; }

cleanup() {
  echo "→ Restoring workspace..."
  if [ "$TOOL" = "claude" ]; then
    restore AGENTS.md
    restore .opencode/agents
  else
    restore CLAUDE.md
    restore .claude/agents
    # move skills back to canonical claude path
    [ -d .opencode/skills ] && mv .opencode/skills .claude/skills
  fi
}
trap cleanup EXIT

# ── activate ─────────────────────────────────────────────────────────────────
if [ "$TOOL" = "claude" ]; then
  hide AGENTS.md
  hide .opencode/agents
  claude "$@"

else
  hide CLAUDE.md
  hide .claude/agents
  # move skills to opencode native path (.opencode/skills/<name>/SKILL.md)
  [ -d .claude/skills ] && mv .claude/skills .opencode/skills
  opencode "$@"
fi
