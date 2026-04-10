---
name: framework-manager
description: Core state management for development framework - workspace CRUD, state tracking, artifact management
tools: Read, Write, Glob, Bash
---

# Framework Manager Skill

Manages persistent state for the development framework including workspaces, state tracking, and artifact coordination.

## Key Functions

### Workspace Management

**Create Workspace**
```bash
create_workspace() {
  local name=$1
  local type=$2  # feature|upgrade|bugfix|minor
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Create workspace directory
  mkdir -p ".dev-framework/workspaces/${name}"
  
  # Initialize state.json
  cat > ".dev-framework/workspaces/${name}/state.json" << EOF
{
  "name": "${name}",
  "type": "${type}",
  "created": "${timestamp}",
  "currentPhase": "init",
  "status": "active",
  "branch": "feature/${name}",
  "roles": {
    "po": { "assigned": null, "status": "pending", "completed": null },
    "architect": { "assigned": null, "status": "pending", "completed": null },
    "developer": { "assigned": null, "status": "pending", "completed": null },
    "reviewer": { "assigned": null, "status": "pending", "completed": null },
    "tester": { "assigned": null, "status": "pending", "completed": null },
    "observer": { "assigned": null, "status": "pending", "completed": null }
  },
  "artifacts": {
    "po": null,
    "architect": null,
    "developer": null,
    "reviewer": null,
    "tester": null,
    "observer": null
  },
  "timelines": {},
  "archived": false,
  "archivedDate": null
}
EOF
  
  # Initialize context.md
  cat > ".dev-framework/workspaces/${name}/context.md" << EOF
# Workspace: ${name}

**Type**: ${type}  
**Created**: ${timestamp}  
**Branch**: feature/${name}  
**Status**: active  

## Current Phase
init → waiting for /dev hand-off

## Roles & Assignments
- Product Owner: [Not assigned]
- Architect: [Not assigned]
- Developer: [Not assigned]
- Reviewer: [Not assigned]
- Tester: [Not assigned]
- Observer: [Not assigned]

## Artifacts
- PO Requirements: [pending]
- Architecture Design: [pending]
- Implementation Plan: [pending]
- Code Review: [pending]
- Test Results: [pending]
- Observability Report: [pending]
EOF
  
  echo "Workspace created: ${name}"
}
```

**Load Workspace State**
```bash
load_workspace_state() {
  local name=$1
  local state_file=".dev-framework/workspaces/${name}/state.json"
  
  if [ -f "$state_file" ]; then
    cat "$state_file"
  else
    echo "ERROR: Workspace not found: ${name}"
    exit 1
  fi
}
```

**Save Workspace State**
```bash
save_workspace_state() {
  local name=$1
  local state_json=$2
  local state_file=".dev-framework/workspaces/${name}/state.json"
  
  echo "$state_json" > "$state_file"
}
```

**Update Phase**
```bash
update_phase() {
  local name=$1
  local phase=$2
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Load current state
  local state=$(load_workspace_state "$name")
  
  # Update phase and timeline
  state=$(echo "$state" | jq \
    --arg phase "$phase" \
    --arg timestamp "$timestamp" \
    '.currentPhase = $phase | 
     .timelines[$phase + "_start"] = $timestamp')
  
  # Save updated state
  save_workspace_state "$name" "$state"
}
```

**Archive Workspace**
```bash
archive_workspace() {
  local name=$1
  local timestamp=$(date +"%Y-%m-%d")
  
  # Create snapshot in archived/
  local snapshot_name="${name}-snapshot-${timestamp}"
  cp -r ".dev-framework/workspaces/${name}" \
        ".dev-framework/archived/${snapshot_name}"
  
  # Mark as archived in state
  local state=$(load_workspace_state "$name")
  state=$(echo "$state" | jq \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '.archived = true | 
     .archivedDate = $timestamp | 
     .status = "archived"')
  
  save_workspace_state "$name" "$state"
  
  echo "Workspace archived: ${snapshot_name}"
}
```

### Artifact Management

**Register Artifact**
```bash
register_artifact() {
  local workspace=$1
  local role=$2  # po|architect|developer|reviewer|tester|observer
  local artifact_name=$3
  
  # Load state
  local state=$(load_workspace_state "$workspace")
  
  # Register artifact path
  state=$(echo "$state" | jq \
    --arg role "$role" \
    --arg artifact "$artifact_name" \
    ".artifacts[$role] = \"artifacts/${artifact_name}\"")
  
  # Save updated state
  save_workspace_state "$workspace" "$state"
}
```

**Get Artifact Path**
```bash
get_artifact_path() {
  local workspace=$1
  local role=$2
  
  local state=$(load_workspace_state "$workspace")
  echo "$state" | jq -r ".artifacts[\"$role\"]"
}
```

### Workspace Querying

**List Active Workspaces**
```bash
list_workspaces() {
  local filter=${1:-active}  # active|archived|all
  
  for ws_dir in .dev-framework/workspaces/*/; do
    local name=$(basename "$ws_dir")
    local state=$(cat "$ws_dir/state.json" 2>/dev/null)
    local status=$(echo "$state" | jq -r '.status' 2>/dev/null)
    local phase=$(echo "$state" | jq -r '.currentPhase' 2>/dev/null)
    
    if [ "$filter" = "all" ] || [ "$status" = "$filter" ]; then
      echo "$name | Phase: $phase | Status: $status"
    fi
  done
}
```

**Get Current Workspace**
```bash
get_current_workspace() {
  # Check if context exists (for command context)
  if [ -f ".dev-framework/current-workspace" ]; then
    cat ".dev-framework/current-workspace"
  else
    # Default to most recent
    ls -t .dev-framework/workspaces/ | head -1
  fi
}
```

**Set Current Workspace**
```bash
set_current_workspace() {
  local name=$1
  echo "$name" > ".dev-framework/current-workspace"
}
```

## Usage in Commands

These functions are called by the command implementations:

1. **new-feature command** → `create_workspace(name, "feature")`
2. **hand-off command** → `update_phase()` → `register_artifact()` → `trigger_next_agent()`
3. **switch-workspace command** → `set_current_workspace(name)`
4. **status command** → `load_workspace_state()` → display
5. **archive-feature command** → `archive_workspace(name)`

## State File Structure

```json
{
  "name": "feature-name",
  "type": "feature|upgrade|bugfix|minor",
  "created": "ISO-8601",
  "currentPhase": "po|architect|developer|reviewer|tester|complete",
  "status": "active|archived",
  "branch": "feature/feature-name",
  "roles": {
    "role_name": {
      "assigned": "user@example.com",
      "status": "pending|in-progress|complete",
      "completed": "ISO-8601"
    }
  },
  "artifacts": {
    "po": "artifacts/feature-name.po.md",
    "architect": "artifacts/feature-name.architect.md"
  },
  "timelines": {
    "po_start": "ISO-8601",
    "po_complete": "ISO-8601"
  },
  "archived": false,
  "archivedDate": null
}
```

## Error Handling

- Missing workspace → Clear error message with available workspaces
- Invalid phase → Validate against allowed phases
- Corrupted state file → Backup and regenerate from context
