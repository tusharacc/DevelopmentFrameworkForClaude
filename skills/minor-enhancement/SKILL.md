---
name: minor-enhancement
description: Start a minor enhancement workflow for small improvements to existing behaviour — tweaks, renames, copy changes, config updates. Abbreviated chain — Developer → Reviewer → PO Approval. Use when no new architecture or testing infrastructure is needed.
arguments: description
examples:
  - /dev-framework:minor-enhancement "rename config key from timeout to request_timeout"
  - /dev-framework:minor-enhancement "update error message wording on login page"
---

Start a minor enhancement workflow for: **$ARGUMENTS**

Minor enhancement is an abbreviated workflow. PO, Architect, Tester, and Executor phases are skipped.
Phase chain: **Developer → Reviewer → PO Approval → Complete**

## Step 0: Check for existing active workspace

Scan `.dev-framework/workspaces/*/state.json` for any workspace with `"status": "active"`.
If one is found, output:

```
STOP: Active workspace found — $existing_name (phase: $phase).
Finish or archive it before starting a new minor enhancement.
  → To resume:  say "continue"
  → To archive: /dev archive-feature $existing_name
  → To switch:  /dev switch-workspace $existing_name
```

Output this message and stop. Do not execute any further steps in this skill.

## Step 1: Create workspace slug

Convert "$ARGUMENTS" to a slug: lowercase, hyphens for spaces, remove special characters.
Prefix with `minor-`. Example: "rename config key" → `minor-rename-config-key`

## Step 2: Create workspace directories

```bash
mkdir -p .dev-framework/workspaces/$SLUG
mkdir -p .dev-framework/artifacts
```

## Step 3: Write state.json

```json
{
  "name": "$SLUG",
  "type": "minor",
  "workflowType": "minor",
  "created": "<current ISO timestamp>",
  "currentPhase": "developer",
  "status": "active",
  "branch": "minor/$SLUG",
  "roles": {
    "developer": { "status": "in-progress", "completed": null },
    "reviewer": { "status": "pending", "completed": null },
    "po-approval": { "status": "pending", "completed": null }
  },
  "artifacts": {
    "developer": "artifacts/$SLUG.developer.md",
    "reviewer": null,
    "po-approval": null
  },
  "timelines": {}
}
```

## Step 4: Create developer artifact

Create `.dev-framework/artifacts/$SLUG.developer.md` with sections:
- Change Description
- Files Changed
- Before / After (show the diff inline)
- Reason

## Step 5: Set as current workspace and ensure git repo

```bash
echo "$SLUG" > .dev-framework/current-workspace
git status 2>/dev/null || git init
git checkout -b minor/$SLUG 2>/dev/null || git checkout minor/$SLUG
git add .dev-framework/
git commit -m "minor(framework): workspace $SLUG"
```

## Step 6: Confirm and begin

Output:
```
✓ Minor enhancement workspace: $SLUG
✓ Branch: minor/$SLUG
✓ Phases: Developer → Reviewer → PO Approval

Implementing change...
```

Immediately act as **Developer**: implement "$ARGUMENTS" and populate `.dev-framework/artifacts/$SLUG.developer.md`.

When done, say **continue** to advance to Reviewer.
