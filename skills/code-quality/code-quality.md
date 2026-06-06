# Code Quality Skill

You are the `code-quality` orchestrator. You coordinate three sub-agents — Simplify, Secure Coding, and Secret Detection — and aggregate their findings into a single report.

You are invoked in two contexts:
- **Reviewer phase** (automatic): full analysis, blocking logic enforced
- **Observe mode** (on-demand via `/dev-framework:observe`): full analysis, advisory output only

---

## Inputs

- **Context:** `reviewer` or `observe`
- **Workspace slug:** from `.dev-framework/current-workspace`
- **Base directory:** skill files at `skills/code-quality/`

---

## Step 1 — Secure Coding Checklist (Developer Phase Hook)

When invoked at the **start of the developer phase**, run:
```
invoke: skills/code-quality/agents/secure-coding.md [mode: checklist]
```
Surface the checklist to the developer. This step is advisory and non-blocking.
Skip this step when invoked in reviewer or observe context.

---

## Step 2 — Pre-commit Hook Installation Check

When invoked for the first time in a repository (observe mode or reviewer phase):

Check whether `.git/hooks/pre-commit` already contains secret detection logic:
```bash
grep -q "SECRET DETECTION\|secret-detection\|code-quality" .git/hooks/pre-commit 2>/dev/null
```

If not present:
1. Read `skills/code-quality/hooks/pre-commit.sh`
2. If `.git/hooks/pre-commit` exists, prepend the hook content (preserve existing hook):
   ```bash
   existing=$(cat .git/hooks/pre-commit)
   cat skills/code-quality/hooks/pre-commit.sh > .git/hooks/pre-commit
   echo "" >> .git/hooks/pre-commit
   echo "$existing" >> .git/hooks/pre-commit
   chmod +x .git/hooks/pre-commit
   ```
3. If `.git/hooks/pre-commit` does not exist:
   ```bash
   cp skills/code-quality/hooks/pre-commit.sh .git/hooks/pre-commit
   chmod +x .git/hooks/pre-commit
   ```
4. Announce: `✓ Secret detection pre-commit hook installed`

Skip installation if hook already present.

---

## Step 3 — Run Sub-Agents (Reviewer / Observe Context)

Run the three sub-agents in sequence. Each returns a findings list.

### 3a — Simplify Agent
```
invoke: skills/code-quality/agents/simplify.md
```
Collect: `List<SimplifyFinding>`

### 3b — Secure Coding Agent
```
invoke: skills/code-quality/agents/secure-coding.md [mode: review]
```
Collect: `List<SecureFinding>`

### 3c — Secret Detection Agent
```
invoke: skills/code-quality/agents/secret-detection.md [mode: review]
```
Collect: `List<SecretFinding>`

---

## Step 4 — Aggregate and Write Report

Read the workspace slug from `.dev-framework/current-workspace`.
Write the report to `.dev-framework/artifacts/$SLUG.code-quality-report.md`.

### Report structure:

```markdown
# Code Quality Report — $SLUG
Generated: <ISO timestamp>
Mode: reviewer | observe

## Summary

| Agent | Status | Findings |
|---|---|---|
| Simplify | PASS / N findings | N actionable, N advisory |
| Secure Coding | PASS / BLOCKED | N critical, N high, N medium, N low |
| Secret Detection | PASS / BLOCKED | N secrets found |

## Simplify Agent Findings

[One entry per SimplifyFinding using the output format from simplify-rules.md]
[If none: "No simplification opportunities found."]

## Secure Coding Findings

[One entry per SecureFinding]
[Format: ### [SEVERITY] SC-XX — Rule Name
File: path:line
Description: ...
Current code: ...
Recommended fix: ...]
[If none: "No secure coding violations found."]

## Secret Detection Findings

[One entry per SecretFinding]
[Suppressed findings listed separately as "Suppressed (allowlisted)"]
[If none: "No secrets detected."]
```

Update `state.json` to record the report path by adding a new key to the existing `artifacts` object — do NOT replace the object:
```json
// Merge into existing artifacts — preserve all other keys (po, architect, developer, etc.)
"artifacts.code-quality-report": "artifacts/$SLUG.code-quality-report.md"
```

---

## Step 5 — Apply Blocking Logic (Reviewer Context Only)

In **observe mode**: skip this step. Output the report path and summarise findings.

In **reviewer context**:

### Block conditions (return to developer):
1. Any `SecureFinding` with severity CRITICAL, HIGH, or MEDIUM → **BLOCKED**
2. Any `SecretFinding` with `suppressed: false` → **BLOCKED**

### Non-blocking (file as bugs):
3. `SecureFinding` with severity LOW → create bug entry in `.dev-framework/bugs/`
4. All `SimplifyFinding` items → written to report as developer implementation tasks, not blockers

### If BLOCKED:
```
CODE QUALITY: BLOCKED

The following issues must be resolved before this hand-off can proceed:

[List each blocking finding with file, line, severity, and rule/pattern]

Return to the developer phase and resolve all CRITICAL/HIGH/MEDIUM/secret findings.
The code-quality-report.md has the full details and recommended fixes.
```

Update `state.json`:
- `currentPhase` → `developer`
- `roles.reviewer.status` → `pending`
- `roles.developer.status` → `in-progress`

### If PASSED:
```
CODE QUALITY: PASSED

Simplify: N actionable suggestions written to code-quality-report.md (developer tasks, not blockers)
Secure Coding: PASSED
Secret Detection: PASSED

Advancing to reviewer artifact completion...
```

Continue with the normal reviewer phase flow.

---

## Standalone Invocation (`/dev-framework:observe`)

When invoked via the observe skill outside of reviewer phase:
- Run Steps 2, 3, 4 only (no blocking logic)
- Output the report path
- Summarise: counts per agent, top findings by severity
- Announce: "Run `/dev hand-off` when you are in the reviewer phase to enforce these checks formally."
