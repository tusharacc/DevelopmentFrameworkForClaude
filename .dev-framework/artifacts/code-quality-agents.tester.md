# Tester Artifact — code-quality-agents

## Test Plan

Tests cover four areas:
1. **pre-commit hook** (`pre-commit.sh`) — detection correctness, portability, allowlist, blocking behaviour
2. **Simplify agent** (`simplify.md`) — rule application, TDD gate, output format, edge cases
3. **Secure coding agent** (`secure-coding.md`) — checklist mode, review mode, severity blocking
4. **code-quality orchestrator** (`code-quality.md`) — sequencing, report generation, state.json merge, hook installation

All tests are **manual verification** or **scripted simulation** — no automated test runner exists for skill markdown files. The executor will verify by inspection and by running the hook script against crafted inputs.

---

## Test Cases

### Group 1 — pre-commit.sh Hook

---

**TC-01: AWS key detection blocks commit**
- **Input:** Stage a file containing `AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE123"` (19 chars after AKIA — note: this is a known example and won't trip real AWS, but the regex `AKIA[0-9A-Z]{16}` matches)
- **Expected:** Hook prints `SECRET DETECTED`, `Pattern: AWS_ACCESS_KEY_ID`, exits 1
- **AC covered:** AC-4

---

**TC-02: Private key PEM detection blocks commit**
- **Input:** Stage a file with line `-----BEGIN RSA PRIVATE KEY-----`
- **Expected:** Hook prints `SECRET DETECTED`, `Pattern: PRIVATE_KEY_PEM`, exits 1
- **AC covered:** AC-4

---

**TC-03: GitHub PAT detection blocks commit**
- **Input:** Stage a file with `token = "ghp_abcdefghijklmnopqrstuvwxyz123456789012"` (40 chars after ghp_)
- **Expected:** Hook prints `SECRET DETECTED`, `Pattern: GITHUB_PAT`, exits 1
- **AC covered:** AC-4

---

**TC-04: DB connection string with embedded credentials blocks commit**
- **Input:** Stage a file with `DATABASE_URL = "postgres://user:hunter2@localhost:5432/mydb"`
- **Expected:** Hook prints `SECRET DETECTED`, `Pattern: DB_CONN_WITH_CREDS`, exits 1
- **AC covered:** AC-4

---

**TC-05: Hardcoded password blocks commit**
- **Input:** Stage a file with `password = "mysecretpass"`
- **Expected:** Hook prints `SECRET DETECTED`, `Pattern: HARDCODED_PASSWORD`, exits 1
- **AC covered:** AC-4

---

**TC-06: Clean file passes commit**
- **Input:** Stage a file with no secret patterns
- **Expected:** Hook prints `Secret detection: PASSED (0 findings in staged changes)`, exits 0
- **AC covered:** AC-4

---

**TC-07: Inline `# noqa: secret` suppresses detection**
- **Input:** Stage a file with `EXAMPLE_KEY = "AKIAIOSFODNN7EXAMPLE123"  # noqa: secret — documented example`
- **Expected:** Hook does NOT print `SECRET DETECTED`, exits 0
- **AC covered:** AC-5

---

**TC-08: `.code-quality-ignore` glob suppresses file**
- **Setup:** Create `.code-quality-ignore`:
  ```
  # Justification: test fixtures contain dummy credentials
  tests/fixtures/*.json
  ```
- **Input:** Stage `tests/fixtures/sample.json` containing a fake AWS key
- **Expected:** Hook exits 0, no SECRET DETECTED output
- **AC covered:** AC-5

---

**TC-09: Allowlist entry without justification comment is ignored**
- **Setup:** Create `.code-quality-ignore` with:
  ```
  tests/fixtures/*.json
  ```
  (no preceding justification comment)
- **Input:** Stage `tests/fixtures/sample.json` containing a fake AWS key
- **Expected:** Hook prints `SECRET DETECTED`, exits 1 (allowlist entry invalid)
- **AC covered:** AC-5

---

**TC-10: Hook is compatible with Bash 3.2 (no `declare -A`)**
- **Setup:** Run hook explicitly with `bash --version` < 4 environment, or inspect script for absence of `declare -A`
- **Expected:** Script runs without "declare: -A: invalid option" error; indexed arrays used throughout
- **AC covered:** AC-4 (portability prerequisite)

---

**TC-11: Hook uses `grep -E` not `grep -P`**
- **Setup:** Inspect `pre-commit.sh` source
- **Expected:** Zero occurrences of `grep -P` or `grep -oP`; `grep -E` and `grep -oE` present
- **AC covered:** AC-4 (portability prerequisite)

---

**TC-12: Match value is redacted in output**
- **Input:** Stage a file with a real-looking AWS key
- **Expected:** Output shows `AKIA****` (first 4 chars + `****`), not the full key
- **AC covered:** (security of the hook output itself)

---

**TC-13: Hook prepend does not destroy existing hook content**
- **Setup:** Create `.git/hooks/pre-commit` with content `echo "existing hook ran"`
- **Run:** Hook installation from `code-quality.md` Step 2
- **Expected:** Resulting `.git/hooks/pre-commit` contains both the new secret detection logic AND `echo "existing hook ran"`, in that order
- **AC covered:** AC-8

---

### Group 2 — Simplify Agent

---

**TC-14: SIM-01 duplicate logic detected and reported**
- **Input:** Branch diff containing two Python functions with identical structure differing only in variable name
- **Expected:** Simplify agent output contains `SIMPLIFY FINDING`, `ID: SIM-01`, file and line range, current snippet, proposed consolidation
- **AC covered:** AC-1 (auto-run in reviewer phase)

---

**TC-15: SIM-04 loop-to-functional replacement reported**
- **Input:** Branch diff with Python `for` loop appending to a list
- **Expected:** Finding `SIM-04` with proposed list comprehension replacement
- **AC covered:** AC-1

---

**TC-16: SIM-04 rejected when replacement is longer**
- **Input:** Branch diff with a complex multi-condition `for` loop where functional replacement would be >80 chars
- **Expected:** No SIM-04 finding (rejection criterion applied)
- **AC covered:** EC-4

---

**TC-17: No test suite → findings marked ADVISORY**
- **Input:** Repo with no `test_*.py` / `*.test.ts` / `*.spec.js` files; branch diff with simplifiable code
- **Expected:** All findings have `Status: ADVISORY`, not `ACTIONABLE`
- **AC covered:** EC-1

---

**TC-18: Test files skipped**
- **Input:** Branch diff that only modifies `test_utils.py`
- **Expected:** No simplify findings (test files are excluded)
- **AC covered:** (simplify rule: test clarity > brevity)

---

**TC-19: Python proposal without type annotations is invalid**
- **Input:** Branch diff where a simplification opportunity exists but the proposed replacement would require an untyped parameter
- **Expected:** No finding generated for that candidate (invalid proposal)
- **AC covered:** AC-6 (Python strict typing)

---

### Group 3 — Secure Coding Agent

---

**TC-20: Checklist mode produces stack-aware output**
- **Input:** Repo with `.py` files only, no JS/TS
- **Expected:** Checklist output includes SC-01 through SC-11; SC-03, SC-12 (JS/TS-only rules) are absent
- **AC covered:** (FR-2.1)

---

**TC-21: SC-01 SQL injection detected (Python)**
- **Input:** Branch diff with `cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")`
- **Expected:** Finding `SC-01`, severity CRITICAL, file and line, recommended fix (parameterised query)
- **AC covered:** AC-3

---

**TC-22: SC-01 NOT flagged when safe pattern present**
- **Input:** Branch diff with `cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))`
- **Expected:** No SC-01 finding
- **AC covered:** AC-3 (no false positive for safe usage)

---

**TC-23: SC-03 XSS detected (TypeScript)**
- **Input:** Branch diff with `element.innerHTML = req.body.content`
- **Expected:** Finding `SC-03`, severity HIGH
- **AC covered:** AC-3

---

**TC-24: CRITICAL/HIGH finding blocks reviewer hand-off**
- **Input:** Reviewer phase with a CRITICAL finding in the secure coding results
- **Expected:** code-quality reports BLOCKED, workflow returns to developer, reviewer artifact not completed
- **AC covered:** AC-3

---

**TC-25: LOW finding filed as bug, does not block**
- **Input:** Reviewer phase with only LOW secure coding findings
- **Expected:** Finding filed in `.dev-framework/bugs/`, reviewer hand-off proceeds to tester
- **AC covered:** (FR-2.3)

---

**TC-26: SC-11 Python typing flags untyped function**
- **Input:** Branch diff with `def process(data, config):` (no type annotations)
- **Expected:** Finding `SC-11`, severity MEDIUM
- **AC covered:** AC-6

---

### Group 4 — Orchestrator and Report

---

**TC-27: code-quality report is written to correct path**
- **Input:** Run code-quality in reviewer context for workspace slug `my-feature`
- **Expected:** File `.dev-framework/artifacts/my-feature.code-quality-report.md` is created with all four sections (Summary, Simplify Findings, Secure Coding Findings, Secret Detection Findings)
- **AC covered:** AC-1

---

**TC-28: state.json `artifacts` object is merged, not replaced**
- **Input:** Run code-quality after po/architect/developer artifacts are already set in state.json
- **Expected:** After run, state.json still contains `artifacts.po`, `artifacts.architect`, `artifacts.developer` — plus the new `artifacts.code-quality-report`
- **AC covered:** MEDIUM-01 fix verification

---

**TC-29: All three sub-agents run without manual invocation in reviewer phase**
- **Input:** Advance a workspace to reviewer phase
- **Expected:** All three sections (Simplify, Secure Coding, Secret Detection) are populated in the code-quality report without the user invoking anything extra
- **AC covered:** AC-1

---

**TC-30: Standalone observe invocation does not block**
- **Input:** Run `/dev-framework:observe` with CRITICAL findings present
- **Expected:** Report is written, findings are summarised, but no hand-off is blocked (observe mode is advisory only)
- **AC covered:** (FR-4.5)

---

## Edge Cases

**EC-01:** Repo has no Python/JS/TS files → Secure Coding and Simplify agents return "no applicable files in diff"; Secret Detection still scans all file types in diff.

**EC-02:** `.code-quality-ignore` file does not exist → allowlist is empty, all patterns applied; no error.

**EC-03:** Branch diff is empty (no staged changes) → Secret detection reports "no changes to scan" and passes; hook exits 0.

**EC-04:** `git merge-base` fails (no `origin/main`) → agents fall back to `HEAD~1`, scan proceeds with warning.

---

## Acceptance Criteria Coverage

| AC | Test Cases |
|---|---|
| AC-1 (all three agents run automatically) | TC-29 |
| AC-2 (simplify regression = not applied) | TC-17 (advisory path); note: TDD gate is developer-enforced, not executor-verifiable |
| AC-3 (CRITICAL/HIGH blocks hand-off) | TC-24 |
| AC-4 (pre-commit blocks secret commit) | TC-01 through TC-06, TC-10, TC-11 |
| AC-5 (allowlist suppresses) | TC-07, TC-08, TC-09 |
| AC-6 (Python mypy --strict) | TC-19, TC-26 |
| AC-7 (skill discoverable) | Verified by skill index — `code-quality.md` exists at expected path |
| AC-8 (hook install preserves existing hook) | TC-13 |
