#!/usr/bin/env bash
# starter.sh — launch Claude Code or OpenCode with zero token overlap.
#
# Each tool sees only its own files. Skills are moved to the native path
# of the chosen tool and restored on exit (even on crash / Ctrl+C).
#
# Usage:
#   ./starter.sh                          # interactive prompt
#   ./starter.sh claude                   # direct launch
#   ./starter.sh opencode                 # direct launch
#   ./starter.sh opencode run "..."       # pass args to the tool
#   ./starter.sh claude --resume          # pass args to the tool
#   ./starter.sh --keep-only claude       # permanently remove all OpenCode files, then remove this script
#   ./starter.sh --keep-only opencode     # permanently remove all Claude files, then remove this script
#
# Optional — both tools work without this script.
# Recommended when a single tool is used consistently, to prevent
# duplicate context files from burning tokens on every invocation.

set -euo pipefail

# ── keep-only: permanent specialization ──────────────────────────────────────
if [ "${1:-}" = "--keep-only" ]; then
  KEEP="${2:-}"
  if [ "$KEEP" != "claude" ] && [ "$KEEP" != "opencode" ]; then
    echo "Usage: ./starter.sh --keep-only claude|opencode" >&2; exit 1
  fi

  echo "→ Specializing project for $KEEP (permanent, irreversible)..."
  read -r -p "  Confirm? This deletes the other tool's files. [y/N] " confirm
  [ "$confirm" = "y" ] || { echo "Aborted."; exit 0; }

  if [ "$KEEP" = "claude" ]; then
    rm -rf AGENTS.md .opencode/agents opencode.json
    # skills stay in .claude/skills/ — their canonical home for Claude
    echo "  removed  AGENTS.md  .opencode/agents/  opencode.json"
  else
    # move skills out first, then remove entire .claude/ directory
    [ -d .claude/skills ] && mv .claude/skills .opencode/skills
    rm -rf CLAUDE.md .claude
    echo "  removed  CLAUDE.md  .claude/"
    echo "  moved    .claude/skills/ → .opencode/skills/"
  fi

  rm -f "$0"
  echo "  removed  starter.sh"
  echo "✓ Project is now $KEEP-only. starter.sh self-destructed."
  exit 0
fi

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
