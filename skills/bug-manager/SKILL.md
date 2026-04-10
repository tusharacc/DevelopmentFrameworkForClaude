---
name: bug-manager
description: Bug tracking operations - create, index, update, query bugs
tools: Read, Write, Bash
---

# Bug Manager Skill

Manages the centralized bug tracking system with indexed database and detailed bug artifacts.

## Bug Storage Structure

```
/.dev-framework/bugs/
├── bugs.json          # Centralized index
└── bug-{id}.md        # Individual bug details
```

## Core Functions

### Initialize Bugs Index

```bash
init_bugs_index() {
  local bugs_dir=".dev-framework/bugs"
  
  if [ ! -f "$bugs_dir/bugs.json" ]; then
    cat > "$bugs_dir/bugs.json" << 'EOF'
{
  "version": "1.0",
  "total": 0,
  "bugs": []
}
EOF
  fi
}
```

### Create Bug

```bash
create_bug() {
  local title=$1
  local description=$2
  local severity=${3:-medium}  # critical|high|medium|low
  local version=${4:-current}
  
  # Generate bug ID
  local bug_count=$(jq '.total' .dev-framework/bugs/bugs.json)
  local next_id=$((bug_count + 1))
  local bug_id=$(printf "BUG-%03d" "$next_id")
  
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Create bug detail artifact
  cat > ".dev-framework/bugs/bug-${next_id}.md" << EOF
---
id: $bug_id
title: $title
severity: $severity
status: open
version: $version
created: $timestamp
assigned: null
workspace: null
---

# $title

**ID**: $bug_id  
**Severity**: $severity  
**Status**: open  
**Created**: $timestamp  
**Assigned**: [unassigned]  

## Description
$description

## Reproduction Steps
1. [Step 1]
2. [Step 2]

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Error Messages / Logs
[If applicable]

## Environment
- OS/Browser: [User's environment]
- Version: $version

## Related Issues
[Links to related bugs or features]

## Workaround
[Temporary workaround if available]

---
*Created: $timestamp*
EOF

  # Add to index
  local index=$(cat .dev-framework/bugs/bugs.json)
  index=$(echo "$index" | jq \
    --arg id "$bug_id" \
    --arg title "$title" \
    --arg severity "$severity" \
    --arg created "$timestamp" \
    '.bugs += [{id: $id, title: $title, severity: $severity, status: "open", created: $created, workspace: null}] |
     .total += 1')
  
  echo "$index" > .dev-framework/bugs/bugs.json
  
  echo "✓ Bug created: $bug_id - $title"
  echo "Severity: $severity"
  echo ""
  echo "To start fix: /dev bugfix $bug_id"
}
```

### Link Bug to Workspace

```bash
link_bug_to_workspace() {
  local bug_id=$1
  local workspace=$2
  
  # Update bugs.json
  local index=$(cat .dev-framework/bugs/bugs.json)
  index=$(echo "$index" | jq \
    --arg bug_id "$bug_id" \
    --arg workspace "$workspace" \
    '.bugs[] |= if .id == $bug_id then .workspace = $workspace else . end')
  
  echo "$index" > .dev-framework/bugs/bugs.json
  
  echo "✓ Bug $bug_id linked to workspace $workspace"
}
```

### Update Bug Status

```bash
update_bug_status() {
  local bug_id=$1
  local status=$2  # open|in-progress|fixed|closed
  
  # Find bug file
  local bug_num=$(echo "$bug_id" | sed 's/BUG-0*//')
  local bug_file=".dev-framework/bugs/bug-${bug_num}.md"
  
  if [ ! -f "$bug_file" ]; then
    echo "ERROR: Bug not found: $bug_id"
    return 1
  fi
  
  # Update artifact
  sed -i.bak "s/status: .*/status: $status/" "$bug_file"
  rm "$bug_file.bak"
  
  # Update index
  local index=$(cat .dev-framework/bugs/bugs.json)
  index=$(echo "$index" | jq \
    --arg bug_id "$bug_id" \
    --arg status "$status" \
    '.bugs[] |= if .id == $bug_id then .status = $status else . end')
  
  echo "$index" > .dev-framework/bugs/bugs.json
  
  echo "✓ Bug $bug_id status updated to: $status"
}
```

### List Bugs

```bash
list_bugs() {
  local filter=${1:-open}  # open|in-progress|fixed|closed|all
  
  local index=$(cat .dev-framework/bugs/bugs.json)
  
  echo "════════════════════════════════════════════════════"
  echo "  BUG LIST - $filter"
  echo "════════════════════════════════════════════════════"
  echo ""
  
  if [ "$filter" = "all" ]; then
    echo "$index" | jq -r '.bugs[] | 
      "\(.id) | \(.title) | Severity: \(.severity) | Status: \(.status)"'
  else
    echo "$index" | jq -r \
      --arg filter "$filter" \
      '.bugs[] | 
      select(.status == $filter) | 
      "\(.id) | \(.title) | Severity: \(.severity) | Status: \(.status)"'
  fi
  
  echo ""
  echo "════════════════════════════════════════════════════"
}
```

### Get Bug Details

```bash
get_bug_details() {
  local bug_id=$1
  
  # Find bug file
  local bug_num=$(echo "$bug_id" | sed 's/BUG-0*//')
  local bug_file=".dev-framework/bugs/bug-${bug_num}.md"
  
  if [ ! -f "$bug_file" ]; then
    echo "ERROR: Bug not found: $bug_id"
    return 1
  fi
  
  cat "$bug_file"
}
```

### Find Bugs by Severity

```bash
find_bugs_by_severity() {
  local severity=$1  # critical|high|medium|low
  
  local index=$(cat .dev-framework/bugs/bugs.json)
  
  echo "════════════════════════════════════════════════════"
  echo "  $severity SEVERITY BUGS"
  echo "════════════════════════════════════════════════════"
  echo ""
  
  echo "$index" | jq -r \
    --arg severity "$severity" \
    '.bugs[] | 
    select(.severity == $severity) | 
    "\(.id) | \(.title) | Status: \(.status) | Workspace: \(.workspace // "unassigned")"'
  
  echo ""
}
```

### Search Bugs

```bash
search_bugs() {
  local query=$1
  
  local index=$(cat .dev-framework/bugs/bugs.json)
  
  echo "════════════════════════════════════════════════════"
  echo "  SEARCH RESULTS: $query"
  echo "════════════════════════════════════════════════════"
  echo ""
  
  echo "$index" | jq -r \
    --arg query "$query" \
    '.bugs[] | 
    select(.title | contains($query) or .id | contains($query)) | 
    "\(.id) | \(.title) | Severity: \(.severity) | Status: \(.status)"'
  
  echo ""
}
```

### Get Bug Statistics

```bash
get_bug_statistics() {
  local index=$(cat .dev-framework/bugs/bugs.json)
  
  echo "════════════════════════════════════════════════════"
  echo "  BUG STATISTICS"
  echo "════════════════════════════════════════════════════"
  echo ""
  
  local total=$(echo "$index" | jq '.total')
  local open=$(echo "$index" | jq '[.bugs[] | select(.status == "open")] | length')
  local in_progress=$(echo "$index" | jq '[.bugs[] | select(.status == "in-progress")] | length')
  local fixed=$(echo "$index" | jq '[.bugs[] | select(.status == "fixed")] | length')
  local closed=$(echo "$index" | jq '[.bugs[] | select(.status == "closed")] | length')
  
  local critical=$(echo "$index" | jq '[.bugs[] | select(.severity == "critical")] | length')
  local high=$(echo "$index" | jq '[.bugs[] | select(.severity == "high")] | length')
  local medium=$(echo "$index" | jq '[.bugs[] | select(.severity == "medium")] | length')
  local low=$(echo "$index" | jq '[.bugs[] | select(.severity == "low")] | length')
  
  echo "Total Bugs: $total"
  echo ""
  echo "By Status:"
  echo "  Open: $open"
  echo "  In Progress: $in_progress"
  echo "  Fixed: $fixed"
  echo "  Closed: $closed"
  echo ""
  echo "By Severity:"
  echo "  Critical: $critical"
  echo "  High: $high"
  echo "  Medium: $medium"
  echo "  Low: $low"
  echo ""
}
```

## Bugs JSON Schema

```json
{
  "version": "1.0",
  "total": 5,
  "bugs": [
    {
      "id": "BUG-001",
      "title": "Login fails on Safari",
      "severity": "high",
      "status": "in-progress",
      "created": "2026-04-10T10:00:00Z",
      "workspace": "bugfix-bug-001",
      "assignee": "developer@example.com"
    }
  ]
}
```

## Bug Details Artifact Schema

```markdown
---
id: BUG-001
title: Login fails on Safari
severity: high|medium|low|critical
status: open|in-progress|fixed|closed
version: 1.0
created: 2026-04-10T10:00:00Z
assigned: developer@example.com
workspace: bugfix-bug-001
---

# Title

**ID**: BUG-001
**Severity**: high
**Status**: open

## Description
[Bug description]

## Reproduction Steps
[How to reproduce]

## Expected vs Actual
[What should happen vs what does]

## Root Cause
[Once identified]

## Fix
[Once implemented]

## Testing
[Test results]
```

## Usage Integration

**In `/dev create-bug` command**:
```bash
create_bug "Login fails on Safari" \
  "Users cannot login on Safari browser. Works on Chrome/Firefox." \
  "high" \
  "1.0.0"
```

**In `/dev bugfix` command**:
```bash
bug_details=$(get_bug_details "BUG-001")
workspace_name="bugfix-BUG-001"
link_bug_to_workspace "BUG-001" "$workspace_name"
```

**In `/dev list-bugs` command**:
```bash
list_bugs "open"    # Show open bugs
list_bugs "all"     # Show all bugs
```

**In `/dev close-bug` command**:
```bash
update_bug_status "BUG-001" "closed"
```

## Severity Levels

- **Critical**: System down, data loss, security breach
- **High**: Major feature broken, workaround unavailable
- **Medium**: Feature partially broken, has workaround
- **Low**: Minor issue, cosmetic problem, low impact

## Status Lifecycle

```
open → in-progress → fixed → closed

or

open → in-progress → fixed (marked in workspace)
```

Status changes:
- `open`: Created, not yet being worked on
- `in-progress`: Active bugfix workspace created
- `fixed`: Developer completed fix
- `closed`: Tester validated fix, workflow complete

## Bug Metadata Retention

Bugs are never deleted, just closed:
- Preserved for history
- Can search closed bugs
- Reference for similar issues
- Audit trail of problems fixed

## Tips

1. **Clear Titles**: "Login fails on Safari" not "Can't login"
2. **Detailed Description**: Include steps to reproduce
3. **Severity Honestly**: Assess actual impact
4. **Link to Workspace**: Creates traceability
5. **Update Status**: Keep metadata current
6. **Close When Done**: Mark fixed after validation

This skill provides comprehensive bug tracking and lifecycle management!
