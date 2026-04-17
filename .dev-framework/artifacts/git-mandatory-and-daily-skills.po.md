# PO Artifact — git-mandatory-and-daily-skills

## Problem Statement

Three gaps in the current dev framework:

1. **Git is optional** — all workflow skills silently skip git if the repo is not initialised, producing workspaces with no branch and no commit history.
2. **No end-of-session checkpoint** — when context compacts or a session ends, all in-progress context (phase, decisions, open questions) is lost. The next session starts cold.
3. **No single-feature focus enforcement** — the framework allows multiple concurrent active workspaces with no guardrails, leading to context scatter.

---

## User Stories

- As a developer, I want git to be initialised automatically if missing so I never lose workspace history due to a missing repo.
- As a developer, I want to end my session with a checkpoint that captures exactly where I am and what decisions are pending, so the next session can resume without re-reading all artifacts.
- As a developer, I want the start-of-day skill to present me with my checkpoint and ask if I want to continue, so I can pick up instantly.
- As a developer, I want the framework to remind me I'm already working on something before I start something new, so I focus on one feature at a time.

---

## Functional Requirements

### FR-1: Git Mandatory Enforcement

- All workflow creation skills (new-feature, upgrade, bugfix, hotfix, minor-enhancement) must check for a git repo before creating a workspace.
- Check by running `git status`.
  - If it succeeds: proceed normally.
  - If it fails (exit non-zero / not a git repo): run `git init`, then proceed.
- The "If git is not available or fails, skip silently" instruction must be removed from all skills.
- After `git init`, perform the initial commit of `.dev-framework/` as the first commit.

### FR-2: End-of-Day Skill (`end-of-day`)

- Reads the current active workspace and `state.json`.
- Reads the current phase artifact to extract recent decisions and open questions.
- Writes a checkpoint file at `.dev-framework/checkpoint.md` containing:
  - Date and time
  - Active workspace name and current phase
  - Summary of work done this session (phases completed, key decisions made)
  - Pending decisions / open questions that need resolution next session
  - Next action (what to do when resuming)
- Commits `.dev-framework/checkpoint.md` to git.
- Optionally pushes to remote if origin is configured.
- Outputs a brief "See you tomorrow" summary to the user.

### FR-3: Start-of-Day Skill (`start-of-day`)

- Reads `.dev-framework/checkpoint.md` if it exists.
- If checkpoint exists:
  - Presents the checkpoint to the user (workspace, phase, pending decisions, next action).
  - Asks: "Ready to continue **$workspace** (phase: **$phase**)? Or start something new?"
  - If user says continue: reads current workspace state and resumes — announces phase, loads relevant artifacts.
  - If user says new: proceeds with normal "What type of work are you starting?" flow.
- If no checkpoint exists:
  - Falls back to normal session start protocol (read current-workspace).
- Replaces (or supplements) the passive session start protocol in CLAUDE.md for explicit invocation.

### FR-4: One Feature at a Time

- When a new workspace is created (any workflow type), check if another workspace is already `active` in `.dev-framework/workspaces/`.
- If yes: warn the user — "You have an active workspace: **$existing**. Finish or archive it before starting new work."
- Do not block (the user can override), but always warn.

---

## Non-Functional Requirements

- Checkpoint file must be human-readable markdown — it will be read by Claude at session start to restore context without requiring Claude to re-read all artifacts.
- Checkpoint must be concise enough to fit in a single context load (target: under 80 lines).
- Git init must be idempotent — running it on an existing repo is a no-op.
- All skills must degrade gracefully if checkpoint.md is absent (first-time use).

---

## Acceptance Criteria

- [ ] `git status` check present in all 5 workflow creation skills; `git init` runs on failure
- [ ] "skip silently" instruction removed from all skills
- [ ] `end-of-day` skill creates `.dev-framework/checkpoint.md` with all required sections and commits it
- [ ] `start-of-day` skill reads checkpoint and presents it before asking to continue
- [ ] Starting a new workspace when one is active produces a warning (not a hard block)
- [ ] Checkpoint file is under 80 lines and fully self-contained (no artifact re-reading needed to resume)

---

## Edge Cases

- No active workspace at end-of-day → checkpoint records "no active workspace; nothing in progress"
- Checkpoint from multiple days ago → display age, still present it
- User ignores start-of-day warning and starts new work → allowed; old workspace remains active in state

---

## Dependencies

- Modifies: `skills/new-feature/SKILL.md`, `skills/upgrade-feature/SKILL.md`, `skills/bugfix/SKILL.md`, `skills/hotfix/SKILL.md`, `skills/minor-enhancement/SKILL.md`
- Creates: `skills/start-of-day/SKILL.md`, `skills/end-of-day/SKILL.md`
- No external dependencies
