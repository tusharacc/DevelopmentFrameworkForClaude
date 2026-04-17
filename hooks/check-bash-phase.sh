#!/bin/bash
# Dev Framework — Bash Phase Gate Hook
# Blocks Bash commands that write to source files outside the developer phase.
# Only intercepts commands that contain file-writing patterns (>, tee, sed -i, etc.)
# Exit 0 = allow. Exit 2 = block with message.

FRAMEWORK_DIR=".dev-framework"
CURRENT_WS_FILE="$FRAMEWORK_DIR/current-workspace"

# No framework or no workspace — allow
if [ ! -d "$FRAMEWORK_DIR" ] || [ ! -f "$CURRENT_WS_FILE" ]; then
  exit 0
fi

SLUG=$(tr -d '[:space:]' < "$CURRENT_WS_FILE")
[ -z "$SLUG" ] && exit 0

STATE_FILE="$FRAMEWORK_DIR/workspaces/$SLUG/state.json"
[ ! -f "$STATE_FILE" ] && exit 0

CURRENT_PHASE=$(python3 -c "
import json, sys
try:
    data = json.load(open('$STATE_FILE'))
    print(data.get('currentPhase', ''))
except:
    print('')
" 2>/dev/null)

# Only gate when not in developer phase
if [ "$CURRENT_PHASE" = "developer" ] || [ -z "$CURRENT_PHASE" ]; then
  exit 0
fi

# Extract the command string from stdin
COMMAND=$(python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

# Check if the command contains file-writing patterns
if echo "$COMMAND" | grep -qE '>\s*[^&]|tee |sed -i|awk.*>|cp |mv |rm |chmod |install '; then
  # Allow writes to .dev-framework/ and framework files
  if echo "$COMMAND" | grep -qE '\.dev-framework/|CLAUDE\.md|hooks/|skills/|agents/'; then
    exit 0
  fi
  echo "[dev-framework] BLOCKED: File-writing shell commands are only allowed in the developer phase."
  echo "Current phase: $CURRENT_PHASE | Workspace: $SLUG"
  echo "Complete the $CURRENT_PHASE phase and hand off to reach the developer phase."
  exit 2
fi

exit 0
