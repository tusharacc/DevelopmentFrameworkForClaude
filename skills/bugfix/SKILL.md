---
name: bugfix
description: Start an abbreviated bug fix workflow (skips PO and Architect phases, starts at Developer)
arguments: bug-id
examples:
  - /dev bugfix BUG-001
  - /dev bugfix login-safari-issue
---

Start a bug fix workflow for: **$ARGUMENTS**

## Step 1: Look up bug details

Check if `.dev-framework/bugs/bug-$ARGUMENTS.md` exists and read it.
If it doesn't exist, check `.dev-framework/bugs/bugs.json` to find the bug by ID or name.
If not found anywhere, ask the user to briefly describe the bug before proceeding.

## Step 2: Create workspace slug

Convert "$ARGUMENTS" to a slug: lowercase, replace spaces/underscores with hyphens, remove special characters. Prefix with `bugfix-` if not already present.
Example: `BUG-001` → `bugfix-bug-001`

## Step 3: Create workspace directories

```bash
mkdir -p .dev-framework/workspaces/$SLUG
mkdir -p .dev-framework/artifacts
```

## Step 4: Write state.json

Create `.dev-framework/workspaces/$SLUG/state.json`:
```json
{
  "name": "$SLUG",
  "type": "bugfix",
  "bugId": "$ARGUMENTS",
  "created": "<current ISO timestamp>",
  "currentPhase": "developer",
  "status": "active",
  "branch": "bugfix/$SLUG",
  "roles": {
    "developer": { "status": "in-progress", "completed": null },
    "reviewer": { "status": "pending", "completed": null },
    "tester": { "status": "pending", "completed": null }
  },
  "artifacts": {
    "developer": "artifacts/$SLUG.developer.md",
    "reviewer": null,
    "tester": null
  },
  "timelines": {}
}
```

## Step 5: Create developer artifact

Create `.dev-framework/artifacts/$SLUG.developer.md` with sections: Bug Summary, Root Cause Analysis, Fix Implementation, Files Changed, Testing Notes.

## Step 6: Set as current workspace and create branch

```bash
echo "$SLUG" > .dev-framework/current-workspace
git checkout -b bugfix/$SLUG 2>/dev/null || git checkout bugfix/$SLUG
git add .dev-framework/
git commit -m "fix(framework): bugfix workspace $SLUG"
```

## Step 7: Confirm and begin Developer phase

Output:
```
✓ Bugfix workspace: $SLUG
✓ Branch: bugfix/$SLUG
✓ Starting at Developer phase (PO and Architect skipped)
```

Then immediately act as the **Developer agent**: investigate the bug "$ARGUMENTS", identify the root cause, and implement a fix. Update `.dev-framework/artifacts/$SLUG.developer.md` with findings and changes.

When done, tell the user to run `/dev hand-off` to advance to Reviewer.
