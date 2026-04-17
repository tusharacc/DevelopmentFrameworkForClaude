---
name: start-of-day
description: Resume from the last session checkpoint. Reads the end-of-day checkpoint, presents pending decisions and next action, then asks whether to continue or start something new. Run this at the start of every session.
arguments: ""
examples:
  - /dev-framework:start-of-day
---

Resume from last session.

## Step 1: Read checkpoint

Read `.dev-framework/checkpoint.md`.

**If checkpoint does not exist**: fall back to session start protocol —
- Read `.dev-framework/current-workspace`
- If active workspace found: announce "Active workspace: **$SLUG** | Phase: **$phase**. Resuming."
- If none: ask "What type of work are you starting? (new feature / bugfix / hotfix / minor enhancement / upgrade)"
- Stop here.

**If checkpoint exists**: continue to Step 2.

## Step 2: Check checkpoint age

Parse the **Date** line from checkpoint.md. If the checkpoint is older than 3 days, note:
> "Note: This checkpoint is from $DATE ($N days ago)."

## Step 3: Present checkpoint to user

Output the checkpoint clearly:

```
--- Last Session Checkpoint ($DATE) ---

Workspace : $SLUG
Phase     : $currentPhase
Branch    : $branch

Done last session:
$done_bullets

Where things stand:
$where_things_stand

Pending decisions:
$pending_decisions

Next action:
$next_action
----------------------------------------
```

Then ask:
> "Ready to continue **$SLUG** (phase: **$currentPhase**)? Or start something new?"

## Step 4: Handle response

**If user says continue / yes / resume (or similar)**:
1. Read `.dev-framework/workspaces/$SLUG/state.json` to confirm current state
2. Read the current phase artifact
3. Announce: "Resuming **$SLUG** | Phase: **$currentPhase**"
4. Briefly summarise what needs to happen next based on the artifact
5. Archive the checkpoint:
   ```bash
   mv .dev-framework/checkpoint.md .dev-framework/checkpoint.prev.md
   git add .dev-framework/
   git commit -m "checkpoint: start-of-day resume $(date +%Y-%m-%d)"
   ```
6. Continue the current phase work

**If user says new / something new / different**:
1. Archive the checkpoint (same mv + commit as above)
2. Ask: "What type of work are you starting? (new feature / bugfix / hotfix / minor enhancement / upgrade)"
3. Proceed with the chosen workflow — the active workspace check in Step 0 of the workflow skill will catch any conflict
