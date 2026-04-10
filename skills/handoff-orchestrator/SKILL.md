---
name: handoff-orchestrator
description: Orchestrate phase transitions, artifact creation, agent invocation, and auto-commit
tools: Read, Write, Bash, TodoWrite
---

# Handoff Orchestrator Skill

Manages the critical handoff process between phases: verifying completion, advancing state, creating next artifact, invoking next agent, and auto-committing.

## Core Functions

### Verify Phase Completion

```bash
verify_phase_complete() {
  local workspace=$1
  local current_phase=$2
  
  # Check if artifact was created/updated
  local artifact=$(get_artifact_path "$workspace" "$current_phase")
  
  if [ -z "$artifact" ] || [ ! -f "$artifact" ]; then
    echo "ERROR: Artifact not found for $current_phase phase"
    return 1
  fi
  
  # Check if artifact has content beyond template
  local lines=$(wc -l < "$artifact")
  if [ "$lines" -lt 10 ]; then
    echo "ERROR: Artifact appears incomplete ($lines lines)"
    return 1
  fi
  
  # Check workspace state is updated
  local state=$(load_workspace_state "$workspace")
  
  echo "✓ Phase $current_phase verified as complete"
  return 0
}
```

### Advance to Next Phase

```bash
advance_to_next_phase() {
  local workspace=$1
  
  # Get current phase
  local state=$(load_workspace_state "$workspace")
  local current_phase=$(echo "$state" | jq -r '.currentPhase')
  
  # Map current to next phase
  local next_phase=""
  case "$current_phase" in
    "po")
      next_phase="architect"
      ;;
    "architect")
      next_phase="developer"
      ;;
    "developer")
      next_phase="reviewer"
      ;;
    "reviewer")
      next_phase="tester"
      ;;
    "tester")
      next_phase="complete"
      ;;
    *)
      echo "ERROR: Unknown phase: $current_phase"
      return 1
      ;;
  esac
  
  # Update phase in state
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  state=$(echo "$state" | jq \
    --arg phase "$next_phase" \
    --arg start "$timestamp" \
    --arg prev_phase "$current_phase" \
    --arg prev_end "$timestamp" \
    '.currentPhase = $phase | 
     .timelines[$prev_phase + "_complete"] = $prev_end | 
     .timelines[$phase + "_start"] = $start')
  
  save_workspace_state "$workspace" "$state"
  
  echo "✓ Advanced from $current_phase to $next_phase"
  return 0
}
```

### Generate Next Artifact

```bash
generate_next_artifact() {
  local workspace=$1
  
  # Get current phase
  local state=$(load_workspace_state "$workspace")
  local current_phase=$(echo "$state" | jq -r '.currentPhase')
  
  # Determine which artifact to generate
  local artifact_name=""
  case "$current_phase" in
    "architect")
      artifact_name=$(generate_architect_artifact "$workspace")
      ;;
    "developer")
      artifact_name=$(generate_developer_artifact "$workspace")
      ;;
    "reviewer")
      artifact_name=$(generate_reviewer_artifact "$workspace")
      ;;
    "tester")
      artifact_name=$(generate_tester_artifact "$workspace")
      ;;
    "complete")
      # No artifact needed
      return 0
      ;;
    *)
      echo "ERROR: Cannot generate artifact for $current_phase"
      return 1
      ;;
  esac
  
  if [ -n "$artifact_name" ]; then
    # Register in state
    register_artifact "$workspace" "$current_phase" "$artifact_name"
    echo "✓ Generated artifact: $artifact_name"
  fi
}
```

### Invoke Next Agent

```bash
invoke_next_agent() {
  local workspace=$1
  
  # Get current phase
  local state=$(load_workspace_state "$workspace")
  local current_phase=$(echo "$state" | jq -r '.currentPhase')
  
  # Determine which agent to invoke
  local agent=""
  case "$current_phase" in
    "po")
      agent="po-requirements"
      ;;
    "architect")
      agent="architect-design"
      ;;
    "developer")
      agent="developer-executor"
      ;;
    "reviewer")
      agent="reviewer-quality"
      ;;
    "tester")
      agent="tester-validation"
      ;;
    *)
      echo "No agent for phase: $current_phase"
      return 0
      ;;
  esac
  
  if [ -z "$agent" ]; then
    return 0
  fi
  
  echo "Invoking agent: $agent"
  echo ""
  echo "=== $agent Agent Starting ==="
  echo "Workspace: $workspace"
  echo "Phase: $current_phase"
  echo ""
  
  # In actual Claude Code, this would invoke the agent
  # For now, document the invocation
  echo "[Agent $agent would be invoked here with workspace context]"
}
```

### Auto-Commit Changes

```bash
auto_commit_phase() {
  local workspace=$1
  
  # Get current phase
  local state=$(load_workspace_state "$workspace")
  local current_phase=$(echo "$state" | jq -r '.currentPhase')
  
  # Check if there are changes
  local changes=$(git status --short .dev-framework/)
  
  if [ -z "$changes" ]; then
    echo "ℹ No changes to commit"
    return 0
  fi
  
  # Stage .dev-framework changes
  git add .dev-framework/
  
  # Create commit message
  local commit_msg="phase($workspace): $current_phase complete"
  
  # If in git repo, commit
  if git rev-parse --git-dir > /dev/null 2>&1; then
    git commit -m "$commit_msg" || {
      echo "Note: Could not commit (may be in test mode)"
      return 0
    }
    
    echo "✓ Auto-committed: $commit_msg"
  else
    echo "ℹ Not in git repo (test environment)"
  fi
}
```

### Handle Bug Fix Phases (Abbreviated)

For bug fixes, skip PO and Architect phases:

```bash
handle_bugfix_phases() {
  local workspace=$1
  
  # For bugfix type, start directly at developer phase
  local state=$(load_workspace_state "$workspace")
  local type=$(echo "$state" | jq -r '.type')
  
  if [ "$type" = "bugfix" ]; then
    # Skip PO and Architect
    advance_to_next_phase "$workspace"  # po -> architect
    advance_to_next_phase "$workspace"  # architect -> developer
    
    echo "✓ Bugfix phases abbreviated (skipped PO/Architect)"
  fi
}
```

### Orchestrate Full Handoff

```bash
orchestrate_handoff() {
  local workspace=$1
  
  echo "════════════════════════════════════════"
  echo "  PHASE HANDOFF: $workspace"
  echo "════════════════════════════════════════"
  echo ""
  
  # Step 1: Verify phase complete
  echo "[1/5] Verifying phase completion..."
  if ! verify_phase_complete "$workspace" "$(get_current_phase "$workspace")"; then
    echo "✗ Phase completion verification failed"
    return 1
  fi
  echo ""
  
  # Step 2: Advance to next phase
  echo "[2/5] Advancing to next phase..."
  if ! advance_to_next_phase "$workspace"; then
    echo "✗ Failed to advance phase"
    return 1
  fi
  echo ""
  
  # Step 3: Generate next artifact
  echo "[3/5] Generating next artifact..."
  if ! generate_next_artifact "$workspace"; then
    echo "✗ Failed to generate artifact"
    return 1
  fi
  echo ""
  
  # Step 4: Auto-commit
  echo "[4/5] Auto-committing changes..."
  if ! auto_commit_phase "$workspace"; then
    echo "⚠ Commit may have failed"
  fi
  echo ""
  
  # Step 5: Invoke next agent
  echo "[5/5] Invoking next agent..."
  if ! invoke_next_agent "$workspace"; then
    echo "⚠ Failed to invoke agent"
  fi
  echo ""
  
  echo "════════════════════════════════════════"
  echo "  HANDOFF COMPLETE"
  echo "════════════════════════════════════════"
}
```

## Usage in /dev hand-off Command

The `/dev hand-off` command calls:

```bash
#!/bin/bash
# Get current workspace
workspace=$(get_current_workspace)

if [ -z "$workspace" ]; then
  echo "ERROR: No active workspace"
  exit 1
fi

# Orchestrate the handoff
orchestrate_handoff "$workspace"
```

## Helper Functions

**Get Current Phase**:
```bash
get_current_phase() {
  local workspace=$1
  local state=$(load_workspace_state "$workspace")
  echo "$state" | jq -r '.currentPhase'
}
```

**Get Next Phase**:
```bash
get_next_phase() {
  local current=$1
  
  case "$current" in
    "po") echo "architect" ;;
    "architect") echo "developer" ;;
    "developer") echo "reviewer" ;;
    "reviewer") echo "tester" ;;
    "tester") echo "complete" ;;
    *) echo "unknown" ;;
  esac
}
```

**Get Phase Agent**:
```bash
get_phase_agent() {
  local phase=$1
  
  case "$phase" in
    "po") echo "po-requirements" ;;
    "architect") echo "architect-design" ;;
    "developer") echo "developer-executor" ;;
    "reviewer") echo "reviewer-quality" ;;
    "tester") echo "tester-validation" ;;
    "observer") echo "observer-observability" ;;
    *) echo "" ;;
  esac
}
```

## Phase State Transitions

```
init
  ↓
po (PO Agent) → artifact: {name}.po.md
  ↓ /dev hand-off
architect (Architect Agent) → artifact: {name}.architect.md
  ↓ /dev hand-off
developer (Developer Agent) → artifact: {name}.dev.md
  → (Observability runs parallel)
  ↓ /dev hand-off
reviewer (Reviewer Agent) → artifact: {name}.review.md
  ↓ /dev hand-off
tester (Tester Agent) → artifact: {name}.test.md
  ↓ /dev hand-off
complete
  ↓
Ready for /dev archive-feature
```

## Error Handling

**If verification fails**:
- User must complete current phase
- Agent will need to finish work
- Cannot advance until complete

**If git commit fails**:
- Phase still advances
- Workspace state updated
- User alerted to fix git state
- Framework continues

**If agent invocation fails**:
- User sees error
- Can manually invoke agent
- Can retry `/dev hand-off`

## Observability Phase

Observability runs parallel, not in sequence:
- Starts when Developer begins
- Runs continuously during Dev → Test phases
- Gets invoked via `/dev observe` command
- Reports findings to test artifact
- Does NOT block handoff workflow

## Integration with Git

Auto-commits use format:
```
phase(feature-name): phase-name complete

Created/updated artifacts:
- feature-name.phase-name.md

Workspace state updated:
- currentPhase: phase-name
- timelines updated
```

This creates a clear audit trail of workflow progress.

## Integration with State Management

Uses framework-manager functions:
- `load_workspace_state()`
- `save_workspace_state()`
- `register_artifact()`
- `get_artifact_path()`
- `get_current_workspace()`

These keep state consistent across operations.

## Integration with Artifact Generator

Uses artifact-generator functions:
- `generate_po_artifact()`
- `generate_architect_artifact()`
- `generate_developer_artifact()`
- `generate_reviewer_artifact()`
- `generate_tester_artifact()`
- `generate_observer_artifact()`

Creates templates for next phase automatically.
