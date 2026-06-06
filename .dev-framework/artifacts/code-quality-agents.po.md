# PO Requirements — code-quality-agents

## Problem Statement

The dev framework currently has no automated guardrails for code simplicity, secure coding, or accidental secret exposure. Developers may write correct but overly complex code, miss security vulnerabilities during review, or accidentally commit credentials. This feature introduces a bundled `code-quality` skill composed of three chained agents — Simplify, Secure Coding, and Secret Detection — integrated into the existing review phase and pre-commit hook system.

---

## User Stories

**US-1 (Simplify):** As a developer submitting code for review, I want an agent to automatically detect unnecessary complexity in my code and suggest equivalent simpler implementations, so that the codebase stays lean and maintainable.

**US-2 (Secure Coding — Developer Prompt):** As a developer implementing a feature, I want guidance on secure coding practices (OWASP Top 10, input sanitisation, parameterised queries, etc.) surfaced as a checklist or prompt before I submit for review, so I can self-correct early.

**US-3 (Secure Coding — Reviewer Agent):** As a reviewer, I want a dedicated agent that hard-blocks hand-off if any secure coding violation is found, so that no insecure code advances through the pipeline.

**US-4 (Secret Detection):** As a developer, I want a pre-commit hook that scans staged changes for secrets, credentials, and tokens before they are committed, so that no sensitive data ever enters the git history.

**US-5 (Bundling):** As a framework user, I want all three capabilities available as a single `code-quality` skill with clearly named sub-agents, chained automatically into the reviewer phase and pre-commit hook, so that I do not need to remember to invoke each one separately.

---

## Functional Requirements

### FR-1: Simplify Agent

**FR-1.1 — Trigger:** Runs automatically and unconditionally during the `reviewer` phase. Cannot be skipped. May also be invoked on-demand via `/dev-framework:observe`.

**FR-1.2 — Simplification checks (all must be performed):**
- **Duplicate logic detection:** Identify blocks of code that are semantically equivalent or nearly identical across functions, modules, or classes.
- **Class/method consolidation:** Detect free functions or scattered logic that belongs in a cohesive class. Recommend introducing a class with distinct method responsibilities.
- **Interface/abstract class opportunities:** Flag hierarchies or duck-typed patterns where a formal interface (Python: `ABC` / `Protocol`; TypeScript: `interface` / `abstract class`) would make the contract explicit and extensible.
- **Loop-to-functional replacement:** Detect explicit `for`/`while` loops that can be replaced with idiomatic functional constructs (`map`, `filter`, `reduce`, list/dict comprehensions in Python; `Array.map`, `Array.filter`, `Array.reduce` in JS/TS).

**FR-1.3 — TDD gate (strict zero regression):**
- For each suggestion, the agent must verify the suggestion against the existing test suite.
- If any test fails after applying the suggestion, the suggestion is **rejected**.
- Rejected suggestions are still reported in the reviewer artifact with the note "attempted — test regression detected" so the developer is informed.
- Only suggestions that pass with zero regressions are marked as actionable recommendations.

**FR-1.4 — Output:** Suggestions are written to the reviewer artifact under a dedicated `## Simplify Agent Findings` section. Each entry includes: file, line range, issue type, current code snippet, proposed replacement, and test outcome.

**FR-1.5 — Language support:** Python and JavaScript/TypeScript. Python code must use strict type hints; suggestions that introduce untyped code are invalid and must themselves be rejected.

---

### FR-2: Secure Coding Agent

**FR-2.1 — Developer prompt (developer phase):** During the `developer` phase, the framework surfaces a secure coding checklist as a structured prompt to the implementor before any code is written. This is advisory and non-blocking — it guides implementation.

**Checklist includes (minimum):**
- OWASP Top 10 items relevant to the detected stack (web, API, DB, auth)
- Input sanitisation at all system boundaries (user input, external API responses, file reads)
- Parameterised SQL / ORM-safe queries (no string interpolation into queries)
- No hardcoded credentials, tokens, or secrets
- Proper error handling that does not leak stack traces or internal paths
- Least-privilege principle for file, DB, and network access
- Dependency integrity (no `*` version pins, known-vulnerable packages flagged)

**FR-2.2 — Reviewer agent (review phase):** A dedicated `secure-coding` sub-agent runs automatically during the `reviewer` phase after the Simplify agent.

**FR-2.3 — Hard block:** Any finding rated HIGH or CRITICAL causes an immediate hand-off rejection. The reviewer artifact records the finding and the workflow returns to the `developer` phase. MEDIUM findings also block unless explicitly annotated with a PO-approved risk-acceptance note. LOW findings are filed as bugs and do not block.

**FR-2.4 — Standards enforced:**
- OWASP Top 10 (2021 edition)
- Input sanitisation: all untrusted data sanitised before use
- Parameterised queries: no raw string SQL construction
- Secure defaults: authentication required by default, explicit opt-out required
- No eval/exec of user-controlled strings
- Secrets: no credentials in source (also caught by FR-3, but cross-checked here)

**FR-2.5 — Language specifics:**
- **Python:** enforce `mypy`-compatible strict typing; flag `eval()`, `exec()`, `pickle.loads()` on untrusted input; flag raw `sqlite3`/`psycopg2` string queries.
- **JavaScript/TypeScript:** flag `eval()`, `innerHTML` assignment from user data, unvalidated `req.params`/`req.body` passed to DB; flag `any` type escape hatches that bypass input validation.

**FR-2.6 — Output:** Written to reviewer artifact under `## Secure Coding Findings`. Each entry: file, line, severity (CRITICAL/HIGH/MEDIUM/LOW), rule violated, description, recommended fix.

---

### FR-3: Secret Detection Agent

**FR-3.1 — Trigger:** Runs as a **pre-commit hook** (`pre-commit` git hook). Executes on every `git commit` attempt against the staged diff only (not full history).

**FR-3.2 — Also runs in reviewer phase** as a secondary check against the full branch diff since the base branch, ensuring nothing was committed earlier in the feature branch that slipped through.

**FR-3.3 — Detection scope:**
- Source code files (`.py`, `.js`, `.ts`, `.tsx`, `.jsx`)
- Config files (`.env`, `.yaml`, `.yml`, `.json`, `.toml`, `.ini`, `.cfg`)
- Test fixtures and seed files
- Shell scripts

**FR-3.4 — Patterns detected (minimum):**
- API keys (generic high-entropy strings, AWS/GCP/Azure key patterns)
- Bearer tokens, JWT secrets, OAuth client secrets
- Private keys (PEM headers)
- Database connection strings with embedded credentials
- Hardcoded passwords assigned to variables named `password`, `passwd`, `pwd`, `secret`, `token`, `key`, `api_key`, `auth`
- GitHub/GitLab personal access tokens

**FR-3.5 — On detection:**
- **Pre-commit hook:** Hard-block the commit. Print the file, line, and pattern matched. Exit non-zero.
- **Reviewer phase:** Record in reviewer artifact under `## Secret Detection Findings`. Treat as CRITICAL — blocks hand-off, returns to developer.

**FR-3.6 — Allowlist mechanism:** A `.code-quality-ignore` file at repo root may contain glob patterns or inline `# noqa: secret` comments to suppress known false positives (e.g., dummy credentials in test fixtures). Allowlist entries must include a justification comment.

---

### FR-4: Bundling and Integration

**FR-4.1 — Skill name:** `code-quality`. Exposed as a Claude Code skill at `skills/code-quality/`.

**FR-4.2 — Sub-agents:** Three clearly named sub-agents invoked in order during review: `simplify` → `secure-coding` → `secret-detection`.

**FR-4.3 — Reviewer phase chain:** When the `reviewer` phase starts, `code-quality` runs all three sub-agents sequentially. Findings from all three are aggregated into the reviewer artifact. The phase gates from FR-1.3, FR-2.3, and FR-3.5 are all enforced.

**FR-4.4 — Pre-commit hook setup:** The `code-quality` skill installation writes a `pre-commit` hook script to `.git/hooks/pre-commit` that invokes the secret detection agent. Existing hooks are preserved (hook is prepended, not replaced).

**FR-4.5 — Standalone invocation:** Users may invoke `/dev-framework:observe` to run all three agents outside of the formal review phase (e.g., mid-development spot-check).

---

## Non-Functional Requirements

**NFR-1 — Language enforcement (Python):** All Python code produced or evaluated by this feature must use strict type hints compatible with `mypy --strict`. Untyped Python is a violation.

**NFR-2 — Language support:** Python 3.10+ and JavaScript/TypeScript (ES2020+, Node 18+, TypeScript 5+).

**NFR-3 — Speed:** The pre-commit hook (secret detection) must complete in under 5 seconds on a typical staged diff of ≤500 lines.

**NFR-4 — Idempotency:** Running any agent multiple times on the same code produces identical output.

**NFR-5 — No external service dependency:** All agents must run locally without network calls. No SaaS scanning services.

**NFR-6 — Zero false-negative tolerance for secrets:** It is preferable to have false positives (suppressible via allowlist) than to miss a real secret.

---

## Acceptance Criteria

**AC-1:** During the reviewer phase, all three sub-agents (Simplify, Secure Coding, Secret Detection) run automatically without manual invocation.

**AC-2:** A Simplify suggestion that causes any test regression is marked "attempted — test regression detected" and NOT applied.

**AC-3:** A HIGH or CRITICAL secure coding finding blocks the reviewer hand-off and returns the workflow to the developer phase with a specific finding list.

**AC-4:** A `git commit` containing a matched secret pattern is rejected by the pre-commit hook with a non-zero exit code and a human-readable error message identifying the file and line.

**AC-5:** A false positive suppressed via `.code-quality-ignore` does not block the commit or reviewer phase.

**AC-6:** All Python code in this feature passes `mypy --strict` with zero errors.

**AC-7:** The `code-quality` skill is discoverable via the skills list and documented with usage examples.

**AC-8:** Installing the pre-commit hook does not overwrite any existing pre-commit logic.

---

## Edge Cases

**EC-1:** No test suite exists in the repo — Simplify agent reports suggestions as "unverified (no tests found)" and marks them advisory only (does not apply them).

**EC-2:** A file is in an unsupported language — agents skip it and log a "language not supported" notice.

**EC-3:** The `.code-quality-ignore` allowlist itself contains a pattern that would suppress a real secret — the agent warns that the allowlist entry matches a high-confidence secret pattern.

**EC-4:** A loop-to-functional replacement produces code that is longer or less readable — the agent must evaluate line-count delta and readability heuristics; only suggest if the replacement is objectively simpler.

**EC-5:** A TypeScript file uses `any` extensively — the secure coding agent flags each boundary where `any` data flows into a security-sensitive operation (DB query, HTTP response, file write) but does not flag internal `any` usage that never reaches a boundary.

**EC-6:** Pre-commit hook is bypassed with `git commit --no-verify` — this is a user-override and outside the agent's control. Document that `--no-verify` bypasses the secret detection hook and recommend CI-level enforcement as a complementary control.

---

## Dependencies

**DEP-1:** Existing `reviewer` phase infrastructure in `.dev-framework/` — the code-quality agents hook into the reviewer phase artifact generation.

**DEP-2:** Git hooks support — the target repo must be a git repository with a writable `.git/hooks/` directory.

**DEP-3:** Python environment with `mypy` available for strict typing checks (Python projects).

**DEP-4:** Node/TypeScript environment with `tsc` available for type checking (TS projects).

**DEP-5:** The `skills/observer-observability/` skill — `code-quality` reuses the observer invocation pattern for standalone runs.

**DEP-6:** No new external dependencies beyond what is already available in Claude Code skill execution environment.
