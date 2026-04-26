# Reviewer Artifact — brownfield-repo-analyzer

## Summary

Reviewed `skills/init-brownfield/SKILL.md` (272 lines) against the PO requirements artifact, architect design, and general correctness. All six phases are implemented. All FR and NFR requirements are satisfied. All edge cases from the PO artifact are handled. No high or medium severity issues were found.

Five low-severity issues were identified and filed as bugs BUG-011 through BUG-015. None block the feature from shipping; all are display/cosmetic or affect informational-only signals.

## Requirements Coverage

| Requirement | Status | Notes |
|---|---|---|
| FR-1: /dev-framework:init-brownfield command | PASS | Frontmatter name matches |
| FR-2: Stack, structure, commands, linters, docs detection | PASS | 8 targeted bash commands cover all required signals |
| FR-3: Ambiguity resolution (multiple test runners, monorepo) | PASS | Steps 3a–3c handle all cases |
| FR-4: Discovery summary with user confirmation | PASS | Structured format, confirmation gate before any write |
| FR-5: CLAUDE.md Case A (create) + Case B (diff + approval) | PASS | Both cases implemented; idempotency handled |
| FR-6: Post-write confirmation with path and line count | PASS | Step 6 outputs path, count, and next-step hint |
| NFR-1: Speed (find -maxdepth 2, no full-tree scans) | PASS | All find commands capped at depth 2 |
| NFR-2: Safety (never silent overwrites) | PASS | Two explicit approval gates |
| NFR-3: Portability (unknown stacks produce partial output) | PASS | "not detected" placeholders throughout |
| NFR-4: Idempotency (no changes if already up to date) | PASS | Case B checks for zero +/~ entries |
| Edge: Non-git directory | PASS | Pre-flight warns, continues |
| Edge: No README.md | PASS | Step 2h: "if it exists" |
| Edge: CLAUDE.md < 5 lines | PASS | Treated as Case A |
| Edge: Conflicting README vs config commands | PASS | Step 3c: prefer config, flag discrepancy |
| Edge: Monorepo multiple roots | PASS | Step 3b: cap at 5, ask user |

## Issues

### BUG-011 (Low) — find -o precedence bug in CI detection
Step 2f second `find` command uses `-o` without parentheses, so `-maxdepth 2` only applies to `Jenkinsfile`, not `.circleci` or `.travis.yml`. Low impact: CI row is informational only. Filed as BUG-011.

### BUG-012 (Low) — Library sort heuristic misleading
Step 2g sorts libraries by shortest name first. This may surface minor utility packages over important long-named dependencies. Low impact: user can correct at confirmation step. Filed as BUG-012.

### BUG-013 (Low) — Commands template formatting ambiguity
The `[command]` placeholder and `*(not detected)*` annotation co-existing in the template creates ambiguity about the final format when a command is unknown. Low impact: formatting only. Filed as BUG-013.

### BUG-014 (Low) — setup.cfg false positive for pytest
`setup.cfg` is a general Python config file; its presence does not reliably indicate pytest. Could trigger a spurious ambiguity prompt. Filed as BUG-014.

### BUG-015 (Low) — README badge lines captured as Project Overview
Many READMEs open with badge/shield image lines before prose. Step 2h's "first non-empty paragraph" heuristic would capture these as the Project Overview. Low impact: user corrects at confirmation step. Filed as BUG-015.

## Recommendation

**Advance to Tester.** All issues are low severity and do not affect correctness of CLAUDE.md writes or safety of the approval gates. The five bugs are filed for a future fix cycle.

---

## Re-review (post-executor fix cycle)

**Changes reviewed:** Two targeted edits to `skills/init-brownfield/SKILL.md`.

| Change | Assessment |
|---|---|
| Step 2a: `maxdepth 2 → maxdepth 3` for stack config detection | Correct and precisely scoped. Directory structure scan (`2b`) unchanged at depth 2. Exclusions (`node_modules`, `.git`, `vendor`) still apply. |
| Step 5 Case B: explicit no/cancel abort path | Correct. Abort message is clear; redirect to Step 6 ensures graceful exit. |

**No new issues.** Advance to executor re-run.
