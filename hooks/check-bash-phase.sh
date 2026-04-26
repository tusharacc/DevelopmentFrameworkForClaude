#!/bin/bash
# Dev Framework — Bash Phase Gate Hook
# Blocks Bash commands that write to source files outside the developer phase.
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

if [ "$CURRENT_PHASE" = "developer" ] || [ -z "$CURRENT_PHASE" ]; then
    exit 0
fi

COMMAND=$(python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

# Only intercept commands with file-writing patterns
if echo "$COMMAND" | grep -qE '>\s*[^&]|tee |sed -i|awk.*>|cp |mv |rm |chmod |install '; then
    # Allow writes targeting the framework project's own directories
    if echo "$COMMAND" | grep -qF "$FRAMEWORK_ROOT/.dev-framework/" || \
       echo "$COMMAND" | grep -qF "$FRAMEWORK_ROOT/hooks/" || \
       echo "$COMMAND" | grep -qF "$FRAMEWORK_ROOT/skills/" || \
       echo "$COMMAND" | grep -qF "$FRAMEWORK_ROOT/agents/" || \
       echo "$COMMAND" | grep -qF "$FRAMEWORK_ROOT/CLAUDE.md" || \
       echo "$COMMAND" | grep -qE '\.dev-framework/'; then
        exit 0
    fi
    echo "[dev-framework] BLOCKED: File-writing shell commands are only allowed in the developer phase."
    echo "Current phase: $CURRENT_PHASE | Workspace: $SLUG"
    echo "Complete the $CURRENT_PHASE phase and hand off to reach the developer phase."
    exit 2
fi

exit 0
