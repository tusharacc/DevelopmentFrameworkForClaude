#!/bin/bash
# Dev Framework — Phase Gate Hook
# Called before Write/Edit tool use. Blocks file edits outside the developer phase.
# Exit 0 = allow. Exit 2 = block with message.

# Self-locate: resolve project root from this script's own path — no hardcoded paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FRAMEWORK_DIR="$FRAMEWORK_ROOT/.dev-framework"
CURRENT_WS_FILE="$FRAMEWORK_DIR/current-workspace"

[ ! -d "$FRAMEWORK_DIR" ] || [ ! -f "$CURRENT_WS_FILE" ] && exit 0

SLUG=$(tr -d '[:space:]' < "$CURRENT_WS_FILE")
[ -z "$SLUG" ] && exit 0

STATE_FILE="$FRAMEWORK_DIR/workspaces/$SLUG/state.json"
[ ! -f "$STATE_FILE" ] && exit 0

CURRENT_PHASE=$(python3 -c "
import json
try:
    data = json.load(open('$STATE_FILE'))
    print(data.get('currentPhase', ''))
except:
    print('')
" 2>/dev/null)

FILE_PATH=$(python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

# Allow writes to framework-owned directories — exact prefix match against absolute root
# This avoids false positives from paths like /src/cool-hooks/ or /my-skills/
for prefix in \
    "$FRAMEWORK_ROOT/.dev-framework/" \
    "$FRAMEWORK_ROOT/hooks/" \
    "$FRAMEWORK_ROOT/skills/" \
    "$FRAMEWORK_ROOT/agents/" \
    "$FRAMEWORK_ROOT/.claude/"; do
    case "$FILE_PATH" in
        "$prefix"*) exit 0 ;;
    esac
done
[ "$FILE_PATH" = "$FRAMEWORK_ROOT/CLAUDE.md" ] && exit 0

# Block source file edits outside developer phase
if [ "$CURRENT_PHASE" != "developer" ] && [ -n "$CURRENT_PHASE" ]; then
    echo "[dev-framework] BLOCKED: File edits are only allowed in the developer phase."
    echo "Current phase: $CURRENT_PHASE | Workspace: $SLUG"
    echo "Complete the $CURRENT_PHASE phase and run hand-off to reach the developer phase."
    exit 2
fi

exit 0
