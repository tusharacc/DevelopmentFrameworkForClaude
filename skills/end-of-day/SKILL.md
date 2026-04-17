---
name: end-of-day
description: Save a session checkpoint capturing current workspace, phase, decisions made, and pending items. Run this at the end of every session. The checkpoint is read by start-of-day to resume instantly next session.
arguments: ""
examples:
  - /dev-framework:end-of-day
---

Save a checkpoint for this session and prepare for tomorrow.

## Step 1: Read current workspace state

Read `.dev-framework/current-workspace`. If absent or empty, set $SLUG to "(none)".

If $SLUG is set, read `.dev-framework/workspaces/$SLUG/state.json`:
- $currentPhase
- $workflowType
- $branch
- $status

## Step 2: Read current phase artifact

If $SLUG is set and status is `active`, read the current phase artifact path from `state.json` under `artifacts[$currentPhase]`. Scan it for:
- Key decisions made (look for bolded items, completed checkboxes, "Decision:" labels)
- Open questions / pending decisions (look for "?", "TBD", "open", "pending", incomplete sections)
- What was most recently worked on

## Step 3: Collect today's commits

```bash
git log --since="6am today" --format="%s" 2>/dev/null || echo "(no git history)"
```

Use the output as the "Done this session" list. If empty, write "No commits recorded this session."

## Step 4: Write checkpoint file

Write `.dev-framework/checkpoint.md`:

```markdown
# Dev Framework Checkpoint
**Date**: $DATE $TIME
**Workspace**: $SLUG
**Phase**: $currentPhase
**Branch**: $branch
**Workflow**: $workflowType

## Done this session
$git_log_bullets

## Where things stand
$one_paragraph_summary_from_phase_artifact

## Pending decisions
$extracted_open_questions (one per line, prefixed with "- [ ]")

## Next action
$concrete_next_step
(Example: "Run hand-off to advance to reviewer" or "Complete the Implementation Plan section in developer artifact")
```

Keep the total file under 80 lines. Be concise — this file will be read cold next session.

If no active workspace: write "No active workspace at end of session. Nothing in progress." and skip steps 5–6.

## Step 5: Commit checkpoint

```bash
git add .dev-framework/checkpoint.md
git commit -m "checkpoint: end-of-day $(date +%Y-%m-%d)"
```

## Step 6: Push if remote exists

```bash
git remote 2>/dev/null | grep -q . && git push 2>/dev/null || true
```

## Step 7: Output summary

```
✓ Checkpoint saved: .dev-framework/checkpoint.md
✓ Workspace: $SLUG | Phase: $currentPhase
✓ Committed and pushed

See you next session. Run /dev-framework:start-of-day to resume.
```
