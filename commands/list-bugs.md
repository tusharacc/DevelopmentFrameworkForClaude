---
name: list-bugs
description: List all bugs, filtered by status or severity
arguments: "[--open|--in-progress|--fixed|--closed|--all] [--critical|--high|--medium|--low]"
examples:
  - /dev list-bugs
  - /dev list-bugs --open
  - /dev list-bugs --open --critical
---

List bugs from the bug index. Filter: **$ARGUMENTS** (default: open only)

## Step 1: Read bugs.json

Read `.dev-framework/bugs/bugs.json`.

If it doesn't exist or has no bugs, output:
```
No bugs found. Create one with /dev create-bug
```
and stop.

## Step 2: Apply filters from $ARGUMENTS

Status filters: `--open`, `--in-progress`, `--fixed`, `--closed`, `--all`
Severity filters: `--critical`, `--high`, `--medium`, `--low`

Default (no argument): show `--open` only.
Multiple flags: apply all (AND logic for status+severity, OR logic between severities).

## Step 3: Display filtered results

Group by status. For each bug output:
```
$ID | $TITLE
  Severity: $severity | Status: $status | Workspace: $workspace (or -)
```

## Step 4: Show summary counts

```
Total shown: N  (Open: N | In Progress: N | Fixed: N | Closed: N)
```
