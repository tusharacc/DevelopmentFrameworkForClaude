#!/bin/bash
# Dev Framework — Phase Gate Hook
# Called before Write/Edit tool use. Blocks file edits outside the developer phase.
# Exit 0 = allow. Exit 2 = block with message.

FRAMEWORK_DIR=".dev-framework"
CURRENT_WS_FILE="$FRAMEWORK_DIR/current-workspace"

# No framework directory — not initialised yet, allow (CLAUDE.md handles conversationally)
if [ ! -d "$FRAMEWORK_DIR" ]; then
  exit 0
fi

# No current workspace — allow (CLAUDE.md handles conversationally)
if [ ! -f "$CURRENT_WS_FILE" ]; then
  exit 0
fi

SLUG=$(cat "$CURRENT_WS_FILE" | tr -d '[:space:]')
if [ -z "$SLUG" ]; then
  exit 0
fi

STATE_FILE="$FRAMEWORK_DIR/workspaces/$SLUG/state.json"
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Extract currentPhase from state.json (no jq dependency)
CURRENT_PHASE=$(python3 -c "
import json, sys
try:
    data = json.load(open('$STATE_FILE'))
    print(data.get('currentPhase', ''))
except:
    print('')
" 2>/dev/null)

# Read the tool input from stdin to check the file being written
INPUT=$(cat)

# Extract file_path from tool input
FILE_PATH=$(python3 -c "
import json, sys
try:
    data = json.loads('''$INPUT''')
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

# Don't block writes to .dev-framework/ itself (artifacts, state, bugs)
if echo "$FILE_PATH" | grep -q "^\.dev-framework/\|^\.dev-framework\\\\"; then
  exit 0
fi

# Don't block writes to CLAUDE.md, hooks/, skills/, agents/ (framework files)
if echo "$FILE_PATH" | grep -qE "^CLAUDE\.md$|^hooks/|^skills/|^agents/|^\.claude"; then
  exit 0
fi

# Block source file edits outside developer phase
if [ "$CURRENT_PHASE" != "developer" ] && [ -n "$CURRENT_PHASE" ]; then
  echo "[dev-framework] BLOCKED: File edits are only allowed in the developer phase."
  echo "Current phase: $CURRENT_PHASE | Workspace: $SLUG"
  echo "Complete the $CURRENT_PHASE phase and run hand-off to reach the developer phase."
  exit 2
fi

exit 0
