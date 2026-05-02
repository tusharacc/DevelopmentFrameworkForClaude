# Developer Artifact — code-quality-agents

## Implementation Notes

All files are skill definitions (markdown). No executable source code was produced — the framework is LLM-driven. All agents read rule definitions from `skills/code-quality/rules/` and operate via LLM analysis. The one exception is `hooks/pre-commit.sh`, which is a bash script run natively by git.

Python strict typing constraint applies to any Python code introduced in future phases. All skill files are language-agnostic markdown. The pre-commit hook is bash.

## Files Created

| File | Purpose |
|---|---|
| `skills/code-quality/rules/secret-patterns.md` | Regex patterns + entropy thresholds for secret detection |
| `skills/code-quality/rules/owasp-rules.md` | 12 secure coding rules (OWASP Top 10 + SC extras) with Python/JS/TS specifics |
| `skills/code-quality/rules/simplify-rules.md` | 4 simplification check definitions (SIM-01 through SIM-04) with before/after examples |
| `skills/code-quality/agents/secret-detection.md` | Secret Detection sub-agent (hook mode + review mode) |
| `skills/code-quality/agents/secure-coding.md` | Secure Coding sub-agent (checklist mode + review mode) |
| `skills/code-quality/agents/simplify.md` | Simplify sub-agent (outputs suggestion document, no code changes) |
| `skills/code-quality/hooks/pre-commit.sh` | Git pre-commit hook template installed to `.git/hooks/pre-commit` |
| `skills/code-quality/code-quality.md` | Orchestrator skill — chains all three agents, writes report, applies blocking logic |

## Files Modified

| File | Change |
|---|---|
| `skills/hand-off/SKILL.md` | Added code-quality invocation to reviewer phase entry; added secure-coding checklist to developer phase entry |
| `skills/observe/SKILL.md` | Added code-quality observe-mode invocation as a check step |

## Test Coverage

No executable test suite applicable to skill markdown files. Validation is via the reviewer and tester phases of this workflow. The pre-commit hook (`pre-commit.sh`) should be manually tested with a file containing a known pattern to verify detection and blocking.

## Secure Coding Checklist

- No `eval()`/`exec()` in any skill file
- No user input reaches shell commands (hook reads only `git diff --cached` output)
- Pre-commit hook uses `set -euo pipefail` — no silent failures
- Secret patterns in `secret-patterns.md` are read-only data, never executed
- No credentials, tokens, or keys in any committed file
- Hook installation prepends to existing hooks — no destructive overwrites

## Known Limitations / Follow-ups

- Shannon entropy calculation in `pre-commit.sh` is approximated using grep+awk patterns; a more precise implementation would use a Python helper script for entropy scoring (filed as future improvement)
- `GENERIC_HIGH_ENTROPY` pattern in the bash hook is simplified to variable name proximity matching; the full entropy scoring algorithm described in `secret-patterns.md` requires a Python/Node helper for production use
- Secure coding rules (SC-01 through SC-12) are LLM-applied — no deterministic AST-level analysis; for high-assurance environments, complement with `semgrep` or `bandit`
