---
name: archive-feature
description: Archive a completed feature workspace, creating a snapshot
arguments: feature-name
examples:
  - /dev archive-feature user-authentication
  - /dev archive-feature auth-v2
---

Archive the workspace: **$ARGUMENTS**

## Step 1: Resolve workspace slug

Convert "$ARGUMENTS" to its slug form (lowercase, hyphens). If `$ARGUMENTS` is empty, read `.dev-framework/current-workspace`.

## Step 2: Read state.json

Read `.dev-framework/workspaces/$SLUG/state.json`.

If not found, output: "ERROR: Workspace not found: $SLUG. Check with /dev list-workspaces." and stop.

If `status` is already `"archived"`, output: "Workspace is already archived." and stop.

If `currentPhase` is not `"complete"`, output:
```
ERROR: Workflow not complete. Current phase: $currentPhase
Complete all phases first, then run /dev hand-off to reach complete.
```
and stop.

## Step 3: Create snapshot

```bash
SNAPSHOT="${SLUG}-snapshot-$(date +%Y-%m-%d)"
mkdir -p .dev-framework/archived
cp -r .dev-framework/workspaces/$SLUG .dev-framework/archived/$SNAPSHOT
```

## Step 4: Update state.json

Update `.dev-framework/workspaces/$SLUG/state.json`:
- Set `status` to `"archived"`
- Set `archivedDate` to current ISO timestamp

## Step 5: Create git tag and commit

```bash
git add .dev-framework/
git commit -m "archive($SLUG): feature workflow complete"
git tag -a "release/$SLUG" -m "Feature archived: $(date +%Y-%m-%d)" 2>/dev/null || true
```

## Step 6: Clear current workspace if this was active

If `.dev-framework/current-workspace` contains `$SLUG`, clear it:
```bash
echo "" > .dev-framework/current-workspace
```

## Step 7: Output result

```
✓ Workflow verified complete
✓ Snapshot: .dev-framework/archived/$SNAPSHOT
✓ Workspace archived
✓ Git tag: release/$SLUG

Use /dev list-workspaces to see remaining active workspaces.
Use /dev new-feature to start the next feature.
```
