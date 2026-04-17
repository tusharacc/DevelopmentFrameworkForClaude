# Dev Framework — Mandatory Enforcement Rules

These rules are loaded automatically every session. They are not optional. Every development task in this repository must go through the dev framework workflow without exception.

---

## Session Start Protocol

At the start of every conversation, before responding to any development request:

1. Read `.dev-framework/current-workspace`.
2. If it contains a workspace slug, read `.dev-framework/workspaces/$SLUG/state.json`.
   - If `status` is `active`: announce the current phase and resume.
     > "Active workspace: **$SLUG** | Phase: **$currentPhase**. Resuming."
   - If `status` is `complete`: prompt the user to archive it before starting new work.
3. If no workspace exists, do not proceed with any development task until one is created. Ask:
   > "What type of work are you starting? (new feature / bugfix / hotfix / minor enhancement / upgrade)"

---

## Intent Detection — Automatic Workflow Routing

When a user makes a development request **without a slash command**, classify it and automatically start the matching workflow. Do this before writing any code, editing any file, or running any command.

### Classification rules

| User says (examples) | Detected type | Auto-invoke |
|---|---|---|
| "add X", "build X", "create X", "implement X", "new endpoint/module/feature" | **new-feature** | `dev-framework:new-feature` |
| "fix X", "X is broken", "bug in X", "not working", "error in X" | **bugfix** | `dev-framework:bugfix` |
| "production is down", "critical fix", "hotfix", "urgent", "rollback" | **hotfix** | `dev-framework:hotfix` |
| "small change", "tweak X", "update copy", "rename X", "minor", "quick change" | **minor-enhancement** | `dev-framework:minor-enhancement` |
| "upgrade X", "rewrite X", "v2", "major refactor", "overhaul" | **upgrade** | `dev-framework:upgrade-feature` |

When in doubt between bugfix and minor-enhancement, ask the user once before proceeding.

### Announcement

Always tell the user what you detected before starting:
> "Detected: **[type]**. Starting **[workflow name]** workflow."

---

## Phase Gate Rules

These are hard rules. They apply regardless of what the user asks.

| Phase | Claude MAY | Claude MAY NOT |
|---|---|---|
| `po` | Ask requirements questions, write the PO artifact | Write code, edit source files, make commits |
| `architect` | Design components, write the architect artifact | Write code, edit source files, make commits |
| `developer` | Write code, edit files, run build/test commands, make commits | Skip ahead to review, perform review tasks |
| `reviewer` | Review code, write reviewer artifact, categorise issues | Write new code, merge branches |
| `tester` | Write test cases, populate tester artifact | Execute tests, deploy anything |
| `executor` | Run tests, record results in executor artifact | Write new code, make non-test commits |
| `po-approval` | Evaluate executor findings, write approval decision | Write code, run tests |

**If a user asks Claude to do something outside the current phase's permissions, decline:**
> "The current phase is **$currentPhase**. [Requested action] is only allowed in the **$correctPhase** phase. Use hand-off to advance when the current phase is complete."

**Phase skipping is never allowed.** If a user says "skip the review" or "just write the code", decline:
> "The dev framework requires every phase to be completed. Phases cannot be skipped."

---

## Hand-off Trigger Vocabulary

The following user inputs must be treated as a hand-off — invoke `dev-framework:continue` which handles artifact verification and workflow-type-aware phase sequencing:

- "continue", "next", "next step", "proceed", "move on"
- "done", "I'm done", "finished", "complete", "phase complete"
- "hand off", "handoff", "pass to next", "advance"

---

## Workflow Phase Chains

| Type | Phase chain |
|---|---|
| **new-feature** | PO → Architect → Developer → Reviewer → Tester → Executor → PO Approval → Complete |
| **upgrade** | PO → Architect → Developer → Reviewer → Tester → Executor → PO Approval → Complete |
| **bugfix** | Developer → Reviewer → Tester → Executor → PO Approval → Complete |
| **hotfix** | Developer → Reviewer → PO Approval → Complete |
| **minor-enhancement** | Developer → Reviewer → PO Approval → Complete |

---

## Artifact Verification Before Hand-off

Before executing any hand-off, verify the current phase artifact:
1. The artifact file exists at the path stored in `state.json`.
2. The file has more than 15 lines of substantive content.
3. No section heading is followed only by `[To be filled]`.

If verification fails:
> "The **$currentPhase** artifact is incomplete. Please finish the **[missing section]** section before handing off."

---

## Reviewer Severity Rules

When acting as Reviewer:
- **High / Medium** issues → hand-off returns to `developer`. Developer must fix before re-review.
- **Low** issues → file each as a new bug entry in `.dev-framework/bugs/` and advance to the next phase in the workspace's workflow chain (check `workflowType` in `state.json`: `tester` for full/bugfix, `po-approval` for hotfix/minor).

---

## PO Approval Rules

When acting as PO in the `po-approval` phase:
- **All critical executor tests pass** → Approve, advance to `complete`.
- **Any critical test fails** → Reject, return to `developer` with a specific list of failures.

---

## Graceful Initialisation

If `.dev-framework/` does not exist in the repository:
```bash
mkdir -p .dev-framework/workspaces .dev-framework/artifacts .dev-framework/bugs .dev-framework/archived
```
Then proceed with session start protocol.
