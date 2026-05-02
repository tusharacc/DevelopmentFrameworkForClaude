# Architect Design — code-quality-agents

## Overview

`code-quality` is a composable Claude Code skill bundling three analysis sub-agents: **Simplify**, **Secure Coding**, and **Secret Detection**. It runs automatically during the reviewer phase (producing a combined output document the developer uses to implement changes via TDD) and as a pre-commit hook (secret detection only). All agents are analysis-only — they never modify source files directly.

---

## Component Breakdown

### `skills/code-quality/code-quality.md`
Entry point skill. Invoked by the reviewer phase and by `/dev-framework:observe`. Orchestrates the three sub-agents in sequence, then aggregates their output into a single `code-quality-report.md` document written to the workspace artifacts directory.

### `skills/code-quality/agents/simplify.md`
Simplify sub-agent. Analyses the branch diff for:
- Duplicate logic across functions/modules/classes
- Logic candidates for class/method consolidation
- Duck-typed patterns suited to a formal interface or abstract class
- Explicit loops replaceable with functional constructs

Output: annotated suggestion entries with file, line range, issue type, current snippet, and proposed replacement. Does **not** apply changes. Findings become developer implementation tasks.

### `skills/code-quality/agents/secure-coding.md`
Secure Coding sub-agent. Two modes:
- **Checklist mode** (developer phase): surfaces a stack-aware secure coding checklist as a structured prompt. Advisory, non-blocking.
- **Review mode** (reviewer phase): analyses the branch diff against `rules/owasp-rules.md`. Assigns severity (CRITICAL / HIGH / MEDIUM / LOW). CRITICAL/HIGH/MEDIUM findings block the hand-off and return to developer.

### `skills/code-quality/agents/secret-detection.md`
Secret Detection sub-agent. Two modes:
- **Hook mode** (pre-commit): scans staged diff, exits non-zero on match.
- **Review mode** (reviewer phase): scans full branch diff since base branch.

Uses regex patterns from `rules/secret-patterns.md` combined with Shannon entropy scoring for high-entropy strings adjacent to sensitive variable names.

### `skills/code-quality/rules/simplify-rules.md`
Structured definitions for each simplification check. Written as LLM-readable rule specifications with examples in both Python and TypeScript. The Simplify agent reads this file as its rule source.

### `skills/code-quality/rules/owasp-rules.md`
LLM-readable rule specifications for OWASP Top 10 (2021) plus additional secure coding rules. Each rule has: ID, name, severity, description, detection heuristic, language-specific patterns (Python / JS / TS), and recommended fix template.

### `skills/code-quality/rules/secret-patterns.md`
Regex patterns and entropy thresholds for secret detection. Structured as a table: pattern name, regex, entropy threshold (bits), file scope, and example match. Also defines the allowlist format for `.code-quality-ignore`.

### `skills/code-quality/hooks/pre-commit.sh`
Shell script installed to `.git/hooks/pre-commit`. Invokes the secret-detection agent in hook mode against `git diff --cached`. Prepends to any existing hook content — does not overwrite. Exits 0 (pass) or 1 (blocked).

---

## Directory Structure

```
skills/
└── code-quality/
    ├── code-quality.md
    ├── agents/
    │   ├── simplify.md
    │   ├── secure-coding.md
    │   └── secret-detection.md
    ├── rules/
    │   ├── simplify-rules.md
    │   ├── owasp-rules.md
    │   └── secret-patterns.md
    └── hooks/
        └── pre-commit.sh

.dev-framework/
└── artifacts/
    └── $SLUG.code-quality-report.md   ← generated per workspace run
```

The hook installation writes to `.git/hooks/pre-commit` (not tracked in git, but `pre-commit.sh` itself is tracked as the template).

---

## Data Flow

### Reviewer Phase

```
reviewer phase starts
  │
  ├─→ secure-coding.md [checklist mode already ran in developer phase]
  │
  ├─→ code-quality.md invoked
  │     │
  │     ├─→ simplify.md
  │     │     reads: rules/simplify-rules.md
  │     │     input: branch diff (Python + JS/TS files only)
  │     │     output: List<SimplifyFinding>
  │     │
  │     ├─→ secure-coding.md [review mode]
  │     │     reads: rules/owasp-rules.md
  │     │     input: branch diff
  │     │     output: List<SecureFinding{severity, rule, file, line, fix}>
  │     │
  │     └─→ secret-detection.md [review mode]
  │           reads: rules/secret-patterns.md
  │           input: full branch diff since base branch
  │           reads: .code-quality-ignore (if exists)
  │           output: List<SecretFinding{pattern, file, line, entropy}>
  │
  ├─→ aggregate all findings
  ├─→ write $SLUG.code-quality-report.md
  │
  ├─→ CRITICAL/HIGH/MEDIUM secure finding? → block, return to developer
  ├─→ CRITICAL secret finding?             → block, return to developer
  └─→ no blockers → reviewer artifact gets report path → advance to tester
```

### Developer Phase (Secure Coding Checklist)

```
developer phase starts
  │
  └─→ secure-coding.md [checklist mode]
        detect stack from repo files
        load relevant OWASP rules from owasp-rules.md
        output: structured checklist surfaced as developer prompt
        (advisory, non-blocking)
```

### Pre-commit Hook

```
git commit
  │
  └─→ .git/hooks/pre-commit
        │
        └─→ secret-detection.md [hook mode]
              input: git diff --cached (staged diff only)
              reads: rules/secret-patterns.md
              reads: .code-quality-ignore (if exists)
              match found → print file:line:pattern → exit 1
              no match    → exit 0 → commit proceeds
```

### Developer Implements code-quality-report

```
developer receives $SLUG.code-quality-report.md
  │
  ├─→ for each SimplifyFinding marked actionable:
  │     implement change → run full test suite
  │     zero regressions → keep change
  │     any failure      → revert, mark finding as "not applied — regression"
  │
  ├─→ for each SecureFinding (CRITICAL/HIGH/MEDIUM):
  │     implement recommended fix
  │
  └─→ all secrets resolved before re-commit (pre-commit hook enforces)
```

---

## Interface Contracts

### SimplifyFinding

```typescript
interface SimplifyFinding {
  file: string;
  lineRange: [number, number];
  issueType: "duplicate-logic" | "consolidate-class" | "interface-opportunity" | "loop-to-functional";
  currentSnippet: string;
  proposedReplacement: string;
  language: "python" | "javascript" | "typescript";
  notes: string;           // human-readable rationale
}
```

### SecureFinding

```typescript
interface SecureFinding {
  file: string;
  line: number;
  severity: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW";
  ruleId: string;          // e.g. "OWASP-A03-2021"
  ruleName: string;
  description: string;
  recommendedFix: string;
  language: "python" | "javascript" | "typescript";
}
```

### SecretFinding

```typescript
interface SecretFinding {
  file: string;
  line: number;
  patternName: string;     // e.g. "AWS_ACCESS_KEY", "GENERIC_HIGH_ENTROPY"
  matchedValue: string;    // redacted in output, shown as "****"
  entropyBits: number;     // Shannon entropy of matched string
  suppressed: boolean;     // true if matched by .code-quality-ignore
}
```

### CodeQualityReport structure

The generated `$SLUG.code-quality-report.md` has four sections:

```markdown
# Code Quality Report — $SLUG

## Summary
Pass/block status per sub-agent. Counts by severity.

## Simplify Agent Findings
One entry per SimplifyFinding. Actionable items marked with [ ] checkbox for developer.

## Secure Coding Findings
One entry per SecureFinding. Blocking findings (CRITICAL/HIGH/MEDIUM) highlighted.

## Secret Detection Findings
One entry per SecretFinding. Matched value redacted. Suppressed entries noted.
```

---

## Integration Points

### Reviewer phase (`skills/reviewer-quality/`)
Add a single invocation step at the start of the reviewer agent:
> "Before writing reviewer findings, invoke code-quality in review mode. Attach the generated report path to the reviewer artifact. If any blocking findings exist, reject hand-off and return to developer with the report."

### Developer phase (`skills/developer-executor/`)
Add a single step at developer phase start:
> "Invoke secure-coding in checklist mode. Surface the checklist to the developer before implementation begins."

### Pre-commit hook installation
`code-quality.md` includes an installation section. When a user runs `/dev-framework:observe` for the first time in a repo, the skill checks whether `.git/hooks/pre-commit` already invokes secret detection; if not, it prepends `pre-commit.sh` content to the existing hook (or creates it).

### `.code-quality-ignore`
Repo-root file. Format:
```
# Justification: dummy credentials used only in unit test fixtures
tests/fixtures/sample_config.json

# Justification: example .env file for documentation, no real secrets
docs/example.env
```
Glob patterns and directory paths supported. Inline `# noqa: secret` comment on a source line also suppresses that line.

---

## Implementation Map

Files to create (in order):

1. `skills/code-quality/rules/secret-patterns.md` — no dependencies
2. `skills/code-quality/rules/owasp-rules.md` — no dependencies
3. `skills/code-quality/rules/simplify-rules.md` — no dependencies
4. `skills/code-quality/agents/secret-detection.md` — depends on secret-patterns.md
5. `skills/code-quality/agents/secure-coding.md` — depends on owasp-rules.md
6. `skills/code-quality/agents/simplify.md` — depends on simplify-rules.md
7. `skills/code-quality/hooks/pre-commit.sh` — depends on secret-detection.md interface
8. `skills/code-quality/code-quality.md` — depends on all three agents
9. Modify `skills/reviewer-quality/` — add code-quality invocation step
10. Modify `skills/developer-executor/` — add secure-coding checklist step

---

## Technical Decisions & Trade-offs

| Decision | Choice | Rationale |
|---|---|---|
| Simplify output | Document with annotated suggestions | Developer implements via TDD — no risk of agent-introduced regressions. Simpler, safer. |
| Secure coding analysis | LLM prompt against rule definitions | No external tool dependency (NFR-5). Rules are readable and maintainable as markdown. |
| Secret detection | Regex + Shannon entropy | Regex catches known patterns; entropy catches novel high-randomness strings near sensitive variable names without a known pattern. |
| Reviewer integration | Composable invocation | Keeps code-quality self-contained. Reviewer skill gains one line, not a rewrite. |
| Python typing | `mypy --strict` enforced | All Python in this feature and all Python suggestions must be fully typed. Untyped suggestions are invalid. |
| Hook installation | Prepend, never overwrite | Existing hooks may contain critical CI logic; overwriting would silently break them. |
| Report format | Markdown with checkboxes | Developer can work through the report linearly. Actionable items are visually distinct. Version-controlled as an artifact. |
