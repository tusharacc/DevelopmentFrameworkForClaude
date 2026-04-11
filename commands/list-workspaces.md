---
name: list-workspaces
description: List all workspaces with their current phase and status
arguments: "[--all|--active|--archived]"
examples:
  - /dev list-workspaces
  - /dev list-workspaces --all
  - /dev list-workspaces --archived
---

List development workspaces. Filter: **$ARGUMENTS** (default: active only)

## Step 1: Read current workspace

Read `.dev-framework/current-workspace` to know which workspace is active.

## Step 2: Scan workspace directories

```bash
ls .dev-framework/workspaces/ 2>/dev/null
```

For each workspace directory, read its `state.json`.

## Step 3: Apply filter

- No argument or `--active`: show only workspaces where `status = "active"`
- `--archived`: show only workspaces where `status = "archived"`
- `--all`: show all workspaces

## Step 4: Display results

Format each workspace as:

```
[*] workspace-name          ← [*] if current, [ ] otherwise
    Type: feature|upgrade|bugfix | Phase: po|architect|developer|reviewer|tester|complete
    Branch: feature/workspace-name
    Progress: ✓ PO → ✓ Architect → Developer → ○ Reviewer → ○ Tester
```

Group by status (ACTIVE first, then ARCHIVED).

If no workspaces found, output:
```
No workspaces found. Create one with:
  /dev new-feature "feature name"
```

## Step 5: Show summary line

```
Active: N | Archived: N
```
