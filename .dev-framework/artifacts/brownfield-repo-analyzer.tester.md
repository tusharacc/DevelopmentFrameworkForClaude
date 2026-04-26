# Tester Artifact — brownfield-repo-analyzer

## Test Cases

The skill (`skills/init-brownfield/SKILL.md`) is a prompt file with no automated test suite. All tests are manual: invoke `/dev-framework:init-brownfield` in a controlled repo scenario and verify the described behaviour.

### TC-01 — Case A: clean repo, no CLAUDE.md
**Setup:** Repo with `package.json` at root containing `name`, `scripts.build`, `scripts.test`, `scripts.dev`, and `dependencies`. No `CLAUDE.md` present.
**Steps:** Run `/dev-framework:init-brownfield`. Confirm summary. Type "yes".
**Expected:**
- Discovery summary shows correct stack, commands, structure
- CLAUDE.md is created at repo root
- CLAUDE.md contains all 6 sections (Overview, Stack, Structure, Commands, Conventions, Key Files)
- Commands section uses detected values, not "not detected"
- Post-write confirmation shows path and line count
**Critical:** Yes

### TC-02 — Case B: existing CLAUDE.md with stale content
**Setup:** Repo with `package.json` (React 19, `npm test`). Existing `CLAUDE.md` (10+ lines) that says React 16 and has no test command entry.
**Steps:** Run `/dev-framework:init-brownfield`. Confirm summary. Type "yes" at diff approval.
**Expected:**
- Discovery summary shows React 19, `npm test`
- Change list shows `~ Updating: Framework — React 16 → React 19` and `+ Adding: test command (npm test)`
- After approval, CLAUDE.md is updated with correct values
- Existing sections not touched by analysis are preserved verbatim
**Critical:** Yes

### TC-03 — Idempotency: second run on unchanged repo
**Setup:** Repo from TC-02 after CLAUDE.md has been correctly updated.
**Steps:** Run `/dev-framework:init-brownfield` again. Confirm summary.
**Expected:**
- Change list has zero `+` and zero `~` entries
- Output: "CLAUDE.md is already up to date — no changes needed."
- CLAUDE.md is not modified
**Critical:** Yes

### TC-04 — Ambiguity: multiple test runners
**Setup:** Repo with both `jest.config.js` and `vitest.config.ts` at root.
**Steps:** Run `/dev-framework:init-brownfield`.
**Expected:**
- Before showing discovery summary, skill pauses and asks user to pick the active test runner
- Summary and write proceed only after user responds
- Chosen test runner is reflected in the Commands section
**Critical:** Yes

### TC-05 — Ambiguity: monorepo with multiple package roots
**Setup:** Repo with `package.json` at root AND `packages/core/package.json`.
**Steps:** Run `/dev-framework:init-brownfield`.
**Expected:**
- Skill detects both roots and asks: canonical or document all?
- Summary and write reflect the user's answer
**Critical:** Yes

### TC-06 — Non-git directory
**Setup:** Plain directory with `package.json` but no `.git/`.
**Steps:** Run `/dev-framework:init-brownfield`.
**Expected:**
- Warning shown: "this directory does not appear to be a git repository"
- Analysis continues and produces CLAUDE.md
- No crash or error
**Critical:** No

### TC-07 — No README.md
**Setup:** Repo with only `package.json`. No `README.md`.
**Steps:** Run `/dev-framework:init-brownfield`. Confirm summary. Type "yes".
**Expected:**
- Discovery summary shows `README: not found`
- CLAUDE.md Project Overview section uses the fallback placeholder
- No error
**Critical:** No

### TC-08 — CLAUDE.md exists but is nearly empty (< 5 non-empty lines)
**Setup:** Repo with a `CLAUDE.md` containing only 3 lines of content.
**Steps:** Run `/dev-framework:init-brownfield`. Confirm. Type "yes".
**Expected:**
- Skill treats existing CLAUDE.md as absent (Case A)
- New CLAUDE.md generated from scratch, replacing the thin file
- Approval still required before write
**Critical:** Yes

### TC-09 — Go repository
**Setup:** Repo with `go.mod` at root, no `package.json`. Module: `github.com/foo/bar`. Go 1.22.
**Steps:** Run `/dev-framework:init-brownfield`. Confirm. Type "yes".
**Expected:**
- Stack shows Language: Go, no JavaScript entries
- Test command detected as `go test ./...`
- Key Files includes `go.mod`
**Critical:** No

### TC-10 — Python repo with ruff linter
**Setup:** Repo with `pyproject.toml` (project name, dependencies) and `ruff.toml`.
**Steps:** Run `/dev-framework:init-brownfield`. Confirm. Type "yes".
**Expected:**
- Stack: Python
- Conventions: Ruff (see ruff.toml)
- CLAUDE.md Coding Conventions section is populated
**Critical:** No

### TC-11 — User correction at Step 4
**Setup:** Repo where auto-detected test command is `npm test` but correct command is `npm run test:unit`.
**Steps:** Run `/dev-framework:init-brownfield`. At confirmation step, type "test command should be `npm run test:unit`".
**Expected:**
- Skill acknowledges correction: "Updated: test command is `npm run test:unit`"
- Proceeds to write without asking again
- CLAUDE.md contains the corrected command
**Critical:** Yes

### TC-12 — User declines Case B approval
**Setup:** Repo with existing CLAUDE.md that has differences from current signals.
**Steps:** Run `/dev-framework:init-brownfield`. At diff approval step, type "no".
**Expected:**
- Write is aborted
- CLAUDE.md is unchanged
- Skill exits cleanly
**Critical:** Yes

### TC-13 — No .dev-framework/ state created
**Setup:** Any repo (use TC-01 setup).
**Steps:** Run `/dev-framework:init-brownfield` on a repo with no `.dev-framework/` directory.
**Expected:**
- No `.dev-framework/` directory is created
- No `current-workspace` file is created
- Only `CLAUDE.md` is written
**Critical:** Yes

---

## Coverage Assessment

| Requirement | Test Coverage |
|---|---|
| FR-1: Command invocable | TC-01 |
| FR-2: Signal detection (all signals) | TC-01, TC-09, TC-10 |
| FR-3: Ambiguity resolution | TC-04, TC-05 |
| FR-4: Discovery summary + confirmation | TC-01, TC-11 |
| FR-5: Case A (create) | TC-01, TC-07, TC-08 |
| FR-5: Case B (diff + approval) | TC-02, TC-12 |
| FR-5: Case B idempotency | TC-03 |
| FR-6: Post-write confirmation | TC-01 |
| NFR-2: Safety (no silent write) | TC-02, TC-08, TC-12 |
| NFR-4: Idempotent | TC-03 |
| Edge: Non-git | TC-06 |
| Edge: No README | TC-07 |
| Edge: Thin CLAUDE.md | TC-08 |
| Edge: Monorepo | TC-05 |
| Edge: No .dev-framework/ created | TC-13 |

All critical acceptance criteria from the PO artifact are covered by at least one critical test case.

---

## Sign-off

Test plan covers all 7 acceptance criteria from the PO artifact and all 4 NFRs. 13 test cases defined: 8 critical, 5 non-critical. Ready for Executor to run.
