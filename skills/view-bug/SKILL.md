---
name: view-bug
description: View full details of a bug report
arguments: bug-id
examples:
  - /dev view-bug BUG-001
  - /dev view-bug login-safari
---

Display full details for bug: **$ARGUMENTS**

## Step 1: Find the bug file

Check for `.dev-framework/bugs/bug-$ARGUMENTS.md` (try both as-is and lowercased).

If not found, read `.dev-framework/bugs/bugs.json` to search by ID or partial title match. If still not found, output:
```
ERROR: Bug not found: $ARGUMENTS
Use /dev list-bugs to see available bugs.
```
and stop.

## Step 2: Read and display

Read the bug file and display its full contents in a formatted block:

```
════════════════════════════════════════════════
  $ID: $TITLE
════════════════════════════════════════════════

Severity:  $severity
Status:    $status
Created:   $created
Workspace: $workspace (or "not started")

[full file contents]

════════════════════════════════════════════════
```

## Step 3: Show available actions

Based on the bug's current status, suggest next steps:
- `open` → `To start fixing: /dev bugfix $ID`
- `in-progress` → `Fix in progress. Workspace: $workspace`
- `fixed` → `Fix implemented, awaiting verification.`
- `closed` → `This bug is resolved.`
