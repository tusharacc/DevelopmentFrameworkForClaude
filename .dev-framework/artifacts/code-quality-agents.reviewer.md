# Reviewer Artifact — code-quality-agents

## Review Summary

Code quality pre-checks: PASSED (no Python/JS/TS source files in diff; 3 false-positive secret matches in rule definition files — all suppressed or self-referential).

Reviewer findings: **BLOCKED** — 2 HIGH issues found in `pre-commit.sh`. Both issues render the pre-commit hook non-functional on macOS (the primary target platform). Returning to developer.

---

## Issues by Severity

### High

#### HIGH-01 — `grep -P` portability: silent security bypass on macOS
**File:** `skills/code-quality/hooks/pre-commit.sh` lines 100–101
**Severity:** HIGH

macOS ships BSD grep which does not support the `-P` (Perl-compatible regex) flag. When invoked, BSD grep returns exit code 2 ("invalid option"). With `2>/dev/null` suppressing the error message, the `if echo "$CONTENT" | grep -qP ...` condition silently evaluates to false for every line. As a result, no pattern ever matches and the hook always exits 0 — secrets are never detected or blocked. On macOS (the documented target platform), the hook is a complete no-op.

All current patterns use only POSIX ERE syntax (quantifiers, alternation, character classes). No PCRE-specific features (lookahead, lookbehind, `\K`, etc.) are required.

**Fix:** Replace all `grep -qP` and `grep -oP` calls with `grep -qE` and `grep -oE`.

```bash
# Before
if echo "$CONTENT" | grep -qP "$REGEX" 2>/dev/null; then
  MATCH=$(echo "$CONTENT" | grep -oP "$REGEX" | head -1)

# After
if echo "$CONTENT" | grep -qE "$REGEX" 2>/dev/null; then
  MATCH=$(echo "$CONTENT" | grep -oE "$REGEX" | head -1)
```

---

#### HIGH-02 — `declare -A` requires Bash 4+: macOS ships Bash 3.2
**File:** `skills/code-quality/hooks/pre-commit.sh` line 14
**Severity:** HIGH

`declare -A` (associative arrays) is a Bash 4+ feature. macOS ships `/bin/bash` at version 3.2. The shebang `#!/usr/bin/env bash` uses whatever `bash` appears first in PATH — on a stock macOS system without Homebrew, this is Bash 3.2. With `set -euo pipefail` active, the `declare -A` call fails immediately, the script exits non-zero, and **every commit is blocked** regardless of content. The hook is completely unusable on default macOS.

**Fix:** Replace the associative array with two parallel indexed arrays, compatible with Bash 3.2+.

```bash
# Before
declare -A PATTERNS=(
  [AWS_ACCESS_KEY_ID]="AKIA[0-9A-Z]{16}"
  [PRIVATE_KEY_PEM]="-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"
  ...
)
# Iteration:
for PATTERN_NAME in "${!PATTERNS[@]}"; do
  REGEX="${PATTERNS[$PATTERN_NAME]}"
  ...
done

# After
PATTERN_NAMES=(
  AWS_ACCESS_KEY_ID
  PRIVATE_KEY_PEM
  ...
)
PATTERN_REGEXES=(
  "AKIA[0-9A-Z]{16}"
  "-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"
  ...
)
# Iteration:
for i in "${!PATTERN_NAMES[@]}"; do
  PATTERN_NAME="${PATTERN_NAMES[$i]}"
  REGEX="${PATTERN_REGEXES[$i]}"
  ...
done
```

Indexed arrays (`declare -a` or plain assignment) are supported from Bash 2+.

---

### Medium

#### MEDIUM-01 — `code-quality.md` state.json update replaces entire `artifacts` object
**File:** `skills/code-quality/code-quality.md` line 128
**Severity:** MEDIUM

Step 4 instructs the agent to update `state.json` with:
```json
"artifacts": { "code-quality-report": "artifacts/$SLUG.code-quality-report.md" }
```
This replaces the entire `artifacts` object, destroying all other phase artifact paths (po, architect, developer, reviewer, etc.) that have already been written. State would be corrupted after any code-quality run.

**Fix:** The instruction must specify merging a new key into the existing artifacts object, not replacing the object:
> "Update `state.json`: add key `artifacts.code-quality-report` = `"artifacts/$SLUG.code-quality-report.md"` while preserving all existing `artifacts.*` keys."

---

### Low

*(Filed as bugs — not blocking)*

#### LOW-01 — `build_allowlist` called per-line (performance)
**File:** `skills/code-quality/hooks/pre-commit.sh` line 53
`is_allowlisted()` invokes `build_allowlist` which rereads and parses `.code-quality-ignore` on every call. On a diff with hundreds of added lines, the file is read hundreds of times. Cache the allowlist in an indexed array once before the main loop.

#### LOW-02 — Typo in `simplify.md` edge case label
**File:** `skills/code-quality/agents/simplify.md` line 99
Edge case reads: `No .py/.js/.TS files in diff` — should be `.ts` (lowercase).

#### LOW-03 — No default `.code-quality-ignore` for rules files
The `skills/code-quality/rules/` and `skills/code-quality/hooks/` directories contain regex pattern strings that match the scanner's own patterns (e.g., `-----BEGIN ... PRIVATE KEY-----` as documentation). No default `.code-quality-ignore` is provided, so every scan of this repo flags false positives until the file is manually created. A default `.code-quality-ignore` should be committed with the feature.

#### LOW-04 — 4 patterns in `secret-patterns.md` absent from hook
**File:** `skills/code-quality/hooks/pre-commit.sh` vs `skills/code-quality/rules/secret-patterns.md`
Patterns `AWS_SECRET_ACCESS_KEY`, `GCP_SERVICE_ACCOUNT_KEY`, `AZURE_CLIENT_SECRET`, and `TWILIO_KEY` appear in `secret-patterns.md` but are absent from the hook's pattern list. The gap is undocumented. Either add them to the hook or document explicitly which patterns are hook-only vs. LLM-agent-only.

---

## Approval Status

**REJECTED — returning to Developer**

Required fixes before re-review:
1. HIGH-01: Replace `grep -P`/`-oP` with `grep -E`/`-oE` in `pre-commit.sh`
2. HIGH-02: Replace `declare -A` with parallel indexed arrays in `pre-commit.sh`
3. MEDIUM-01: Fix state.json update instruction in `code-quality.md` Step 4

LOW findings filed as bugs (see `.dev-framework/bugs/`).
