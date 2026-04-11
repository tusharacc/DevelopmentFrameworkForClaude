---
name: status
description: Show current workspace status, phase progress, and next action
arguments: ""
examples:
  - /dev status
---

Display the current development workflow status.

## Step 1: Read current workspace

Read `.dev-framework/current-workspace` to get the active workspace slug.

If the file doesn't exist or is empty, check if any workspaces exist:
```bash
ls .dev-framework/workspaces/ 2>/dev/null
```
If none exist, output "No active workspace. Create one with /dev new-feature." and stop.

## Step 2: Read state.json

Read `.dev-framework/workspaces/$SLUG/state.json`.

## Step 3: Display status

Format and output a status summary like this:

```
═══════════════════════════════════════════════════════════════
  WORKSPACE: $name ($type)
═══════════════════════════════════════════════════════════════

Status:  $status
Branch:  $branch
Created: $created

WORKFLOW PROGRESS:
  [✓/→/○] PO Requirements    [$status] $completedTime
  [✓/→/○] Architect Design   [$status] $completedTime
  [✓/→/○] Developer          [$status] $completedTime
  [✓/→/○] Reviewer           [$status] $completedTime
  [✓/→/○] Tester             [$status] $completedTime

ARTIFACTS:
  [✓/○] $SLUG.po.md
  [✓/○] $SLUG.architect.md
  [✓/○] $SLUG.developer.md
  [✓/○] $SLUG.reviewer.md
  [✓/○] $SLUG.tester.md

NEXT ACTION:
  $actionText

═══════════════════════════════════════════════════════════════
```

Legend: ✓ = complete, → = in progress, ○ = pending

Next action text based on phase:
- `po` → "Gather requirements, then run: /dev hand-off"
- `architect` → "Complete design, then run: /dev hand-off"
- `developer` → "Complete implementation, then run: /dev hand-off"
- `reviewer` → "Complete review, then run: /dev hand-off"
- `tester` → "Complete testing, then run: /dev hand-off"
- `complete` → "Workflow complete! Run: /dev archive-feature $SLUG"
