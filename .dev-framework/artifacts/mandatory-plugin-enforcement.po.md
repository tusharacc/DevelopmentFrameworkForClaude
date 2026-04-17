# PO Requirements — mandatory-plugin-enforcement

## Problem Statement

The dev framework currently works only when a user explicitly invokes a slash command (e.g. `/dev new-feature`). If a user asks Claude to "fix this bug" or "add this feature" in plain language, Claude responds directly without going through the framework — phases are skipped, artifacts are never created, agents are never invoked, and there is no audit trail.

This feature makes the framework **mandatory and automatic**: Claude must detect the intent of any development request, map it to the correct workflow type, and enforce the full phase chain — even when no slash command was used. The framework is not a tool the user opts into; it is the only way development work proceeds.

---

## User Stories

- As a developer, when I say "fix this bug" without a slash command, Claude should automatically start the bugfix workflow (create workspace, enter developer phase) rather than just fixing it inline.
- As a developer, when I say "continue" or "next step", Claude should treat it as a hand-off and advance to the next phase.
- As a team lead, I want confidence that every code change in a session went through review, testing, and PO approval — no exceptions.
- As a developer, when I start a new session, Claude should detect if there is an active workspace and resume it, or ask me what type of work I am starting.

---

## Functional Requirements

### FR-1: Session start enforcement
On every new conversation session, Claude must:
1. Check `.dev-framework/current-workspace` for an active workspace.
2. If found: resume from the current phase and announce it to the user.
3. If not found: ask the user what type of work they want to do and start the appropriate workflow before proceeding with any development task.

### FR-2: Intent detection and automatic workflow routing
When a user makes any development request in plain language (without a slash command), Claude must:
1. Classify the request into one of the four change types:
   - **New feature**: new capability, new module, new endpoint
   - **Bugfix**: something broken that needs fixing
   - **Hotfix**: critical production issue, abbreviated workflow
   - **Minor enhancement**: small improvement to existing behaviour, no new architecture needed
2. Automatically invoke the corresponding workflow (equivalent to running the slash command).
3. Never write code, edit files, or make commits before a workspace is active and the developer phase has been entered via hand-off.

### FR-3: Workflow definitions per change type

| Change Type | Phases |
|-------------|--------|
| New Feature | PO → Architect → Developer → Reviewer → Tester → Executor → PO Approval |
| Upgrade | PO → Architect → Developer → Reviewer → Tester → Executor → PO Approval |
| Bugfix | Developer → Reviewer → Tester → Executor → PO Approval |
| Hotfix | Developer → Reviewer → PO Approval (Tester and Executor skipped for speed) |
| Minor Enhancement | Developer → Reviewer → PO Approval (PO/Architect/Tester skipped) |

### FR-4: "Continue" as hand-off trigger
Any of the following user inputs must be treated as `/dev hand-off`:
- "continue", "next", "next step", "proceed", "move on", "hand off", "done", "I'm done", "phase complete"
Claude must read the current phase from `state.json` and execute the hand-off sequence.

### FR-5: Phase gate enforcement
Claude must not:
- Write or edit code outside the `developer` phase.
- Run tests outside the `executor` phase.
- Make architectural decisions outside the `architect` phase.
- Skip phases — hand-off is the only mechanism to advance.

If a user attempts to force a phase skip (e.g. "just write the code, skip the review"), Claude must decline and explain that the framework does not allow phase skipping.

### FR-6: Artifact verification before hand-off
Before accepting a hand-off from any phase, Claude must verify:
- The phase artifact exists.
- The artifact has substantive content (not just a template with placeholder text).
- All required sections are populated.
If verification fails, Claude must prompt the user to complete the artifact before handing off.

### FR-7: CLAUDE.md enforcement hook
A `CLAUDE.md` file must be written at the project root containing the enforcement rules, so Claude loads them at the start of every session automatically. This is the primary mechanism for making the framework session-persistent.

---

## Non-Functional Requirements

- **Transparency**: When Claude auto-starts a workflow, it must announce what it detected and what workflow it is starting — the user is never silently enrolled.
- **Speed**: Workflow enforcement must add no more than one exchange of overhead for simple requests (ask intent, start workflow, proceed).
- **Graceful degradation**: If `.dev-framework/` does not exist (fresh repo), Claude must create it and initialise the framework before starting.

---

## Acceptance Criteria

- [ ] Starting a session with an active workspace causes Claude to announce the current phase and resume.
- [ ] Saying "fix the login bug" without any slash command triggers the bugfix workflow automatically.
- [ ] Saying "continue" or "next step" at any phase triggers a hand-off to the next phase.
- [ ] Claude refuses to write code when no workspace is active or the current phase is not `developer`.
- [ ] Attempting to skip a phase is declined with an explanation.
- [ ] Hand-off is blocked if the current phase artifact is incomplete.
- [ ] A `CLAUDE.md` at project root loads the enforcement rules into every session.
- [ ] All five change types (new feature, upgrade, bugfix, hotfix, minor enhancement) have defined phase chains that are enforced.

---

## Edge Cases

- User opens a session with no internet and no `.dev-framework/` — framework must be initialised from scratch.
- User says "just make a small typo fix" — must still be classified as minor enhancement and go through its (abbreviated) workflow.
- Two workspaces are active — Claude must confirm which one is current before proceeding.
- A workspace is in `complete` phase — Claude must prompt to archive before starting new work.

---

## Dependencies

- `CLAUDE.md` at project root (new file — must be created by this feature).
- `skills/hand-off/SKILL.md` — already updated with full phase chain (BUG-001 fix).
- All workspace-creation skills (`new-feature`, `bugfix`, `upgrade-feature`) — already updated.
- No external dependencies.
