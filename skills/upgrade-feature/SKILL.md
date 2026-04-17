---
name: upgrade-feature
description: Start a major feature upgrade with a new workspace and full workflow
arguments: feature-name
examples:
  - /dev upgrade-feature "Authentication v2"
  - /dev upgrade-feature auth-major-revamp
---

Start a major feature upgrade for: **$ARGUMENTS**

This follows the same full workflow as new-feature (PO → Architect → Developer → Reviewer → Tester → Executor → PO Approval) but creates an isolated upgrade workspace so the original feature continues running in parallel.

## Step 0: Check for existing active workspace

Scan `.dev-framework/workspaces/*/state.json` for any workspace with `"status": "active"`.
If one is found, output:

```
STOP: Active workspace found — $existing_name (phase: $phase).
Finish or archive it before starting a new upgrade.
  → To resume:  say "continue"
  → To archive: /dev archive-feature $existing_name
  → To switch:  /dev switch-workspace $existing_name
```

Output this message and stop. Do not execute any further steps in this skill.

## Step 1: Create workspace slug

Convert "$ARGUMENTS" to a slug: lowercase, hyphens for spaces, remove special characters. Append `-upgrade` if not already present.
Example: "Authentication v2" → `authentication-v2-upgrade`

## Step 2: Create workspace directories

```bash
mkdir -p .dev-framework/workspaces/$SLUG
mkdir -p .dev-framework/artifacts
```

## Step 3: Write state.json

Create `.dev-framework/workspaces/$SLUG/state.json`:
```json
{
  "name": "$SLUG",
  "type": "upgrade",
  "workflowType": "full",
  "created": "<current ISO timestamp>",
  "currentPhase": "po",
  "status": "active",
  "branch": "upgrade/$SLUG",
  "roles": {
    "po": { "status": "in-progress", "completed": null },
    "architect": { "status": "pending", "completed": null },
    "developer": { "status": "pending", "completed": null },
    "reviewer": { "status": "pending", "completed": null },
    "tester": { "status": "pending", "completed": null },
    "executor": { "status": "pending", "completed": null },
    "po-approval": { "status": "pending", "completed": null }
  },
  "artifacts": {
    "po": "artifacts/$SLUG.po.md",
    "architect": null,
    "developer": null,
    "reviewer": null,
    "tester": null,
    "executor": null,
    "po-approval": null
  },
  "timelines": {}
}
```

## Step 4: Create PO artifact template

Create `.dev-framework/artifacts/$SLUG.po.md` with sections: Upgrade Rationale, Migration Strategy (v1 → v2), User Stories, Functional Requirements, Non-Functional Requirements, Backwards Compatibility, Acceptance Criteria.

## Step 5: Set as current workspace and ensure git repo

```bash
echo "$SLUG" > .dev-framework/current-workspace
git status 2>/dev/null || git init
git checkout -b upgrade/$SLUG 2>/dev/null || git checkout upgrade/$SLUG
git add .dev-framework/
git commit -m "feat(framework): upgrade workspace $SLUG"
```

## Step 6: Confirm and begin PO phase

Output:
```
✓ Upgrade workspace: $SLUG
✓ Branch: upgrade/$SLUG
✓ Original workspace preserved (switch with /dev switch-workspace)
✓ Starting PO phase

Gathering requirements for upgrade...
```

Then immediately act as the **Product Owner agent**: ask focused questions about the upgrade requirements for "$ARGUMENTS", including migration strategy, breaking changes, and backwards compatibility concerns. Populate `.dev-framework/artifacts/$SLUG.po.md`.

When requirements are complete, tell the user to run `/dev hand-off` to advance to Architect.
