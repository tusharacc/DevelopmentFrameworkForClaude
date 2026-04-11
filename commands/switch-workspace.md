---
name: switch-workspace
description: Switch to a different active workspace and check out its git branch
arguments: workspace-name
examples:
  - /dev switch-workspace user-authentication
  - /dev switch-workspace auth-v2
---

Switch to workspace: **$ARGUMENTS**

## Step 1: Validate workspace exists

Check that `.dev-framework/workspaces/$ARGUMENTS/state.json` exists and read it.

If not found, run `ls .dev-framework/workspaces/` and output:
```
ERROR: Workspace not found: $ARGUMENTS

Available workspaces:
  [list them]

Usage: /dev switch-workspace <workspace-name>
```
Then stop.

If `status` is `"archived"`, output: "ERROR: Cannot switch to archived workspace. Use /dev list-workspaces --archived to view it." and stop.

## Step 2: Update current workspace

```bash
echo "$ARGUMENTS" > .dev-framework/current-workspace
```

## Step 3: Check out git branch

Read `branch` from state.json, then:
```bash
git checkout $BRANCH 2>/dev/null || echo "Warning: branch $BRANCH not found, workspace context updated only"
```

## Step 4: Display new workspace status

Output:
```
✓ Switched to: $ARGUMENTS
✓ Branch: $BRANCH
✓ Phase: $currentPhase ($status)

Next action: [/dev hand-off if in-progress | /dev status for details]
```
