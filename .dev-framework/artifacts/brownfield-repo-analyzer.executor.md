# Executor Artifact — brownfield-repo-analyzer

## Test Results

| TC | Description | Critical | Result | Notes |
|---|---|---|---|---|
| TC-01 | Case A: clean repo, package.json, no CLAUDE.md | Yes | PASS | Stack detection finds `./package.json`; dirs detected correctly; README first paragraph extractable |
| TC-02 | Case B: existing CLAUDE.md with stale content | Yes | PASS | Diff logic: `~ Updating React 16→19`, `+ Adding test command`, `= Preserving custom section` — all buckets work; approval gate present |
| TC-03 | Idempotency: second run, unchanged repo | Yes | PASS | Case B with zero `+`/`~` entries → "no changes needed" path confirmed in skill logic |
| TC-04 | Ambiguity: multiple test runners | Yes | PASS | `jest.config.js` + `vitest.config.ts` both detected (count=2); ambiguity prompt fires |
| TC-05 | Ambiguity: monorepo multiple package roots | Yes | **FAIL** | `packages/core/package.json` at depth 3 NOT detected by `find -maxdepth 2`; monorepo prompt silently never fires |
| TC-06 | Non-git directory | No | PASS | `NOT_GIT` output confirmed; warning path in skill verified |
| TC-07 | No README.md | No | PASS | Step 2h uses "if it exists" guard; no error path |
| TC-08 | CLAUDE.md < 5 non-empty lines | Yes | PASS | 3-line fixture confirmed; skill threshold at 5 non-empty lines routes to Case A |
| TC-09 | Go repository | No | PASS | `go.mod` detected; no JS signals present |
| TC-10 | Python + ruff | No | PASS (by inspection) | Detection identical to TC-09 pattern; `ruff.toml` in linter find command |
| TC-11 | User correction at Step 4 | Yes | PASS | Skill confirms correction and proceeds to Step 5 without re-prompting |
| TC-12 | User declines Case B approval | Yes | CONCERN | No explicit "no/cancel/abort" handling in Case B approval prompt; relies on Claude's general reasoning to abort — skill should make this explicit |
| TC-13 | No .dev-framework/ state created | Yes | PASS | Skill explicitly states "Do not create any workspace, do not modify `.dev-framework/`" at lines 11 and 272 |

---

## Critical Test Summary

| Result | Count | Tests |
|---|---|---|
| PASS | 7 | TC-01, TC-02, TC-03, TC-04, TC-08, TC-11, TC-13 |
| FAIL | 1 | TC-05 |
| CONCERN | 1 | TC-12 |

**TC-05 failure detail:**
The standard monorepo layout (`packages/core/package.json`) places sub-package roots at depth 3 relative to the repo root. Step 2a uses `find -maxdepth 2`, which only reaches depth 2. The file at depth 3 is never found, so the `>1 package roots` condition in Step 3b never triggers. The skill silently treats the monorepo as a single-root project with no warning to the user.

**Fix required:** Change `find -maxdepth 2` to `find -maxdepth 3` in Step 2a for stack config detection (only — not for directory structure detection, which can remain at depth 2 to avoid noise).

**TC-12 concern detail:**
The Case B approval prompt says "Type **yes** to apply these changes, or describe corrections." There is no instruction for what to do if the user types "no", "cancel", or similar. Claude's general reasoning would likely abort correctly, but the skill should make this explicit to guarantee safe behaviour.

**Fix required (low priority):** Add to Step 5 Case B approval prompt: "If the user says no, cancel, or stop — abort without writing. Confirm: 'Write cancelled. CLAUDE.md was not modified.'"

---

## Recommendation

**Return to Developer.** TC-05 is a critical failure: the monorepo detection feature does not work for standard `packages/*/package.json` layouts. Fix: change `maxdepth 2` to `maxdepth 3` in Step 2a only. TC-12 is a low-priority concern that can be fixed in the same pass.
