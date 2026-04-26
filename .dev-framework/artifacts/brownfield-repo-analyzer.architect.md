# Architect Design — brownfield-repo-analyzer

## Overview

`init-brownfield` is implemented as a single self-contained skill file: `skills/init-brownfield/SKILL.md`. Like every other skill in this framework, it is a markdown prompt that Claude executes step by step. No supporting scripts, helpers, or framework state mutations are needed — the skill is purely an analysis and file-write operation that sits outside the workspace lifecycle.

The skill instructs Claude to run targeted bash commands for signal detection, synthesize the results, handle ambiguity interactively, present a discovery summary for user confirmation, and then write or update CLAUDE.md.

---

## Components

### 1. `skills/init-brownfield/SKILL.md` (sole deliverable)

The complete skill prompt. It drives Claude through six phases:

| Phase | What happens |
|---|---|
| Pre-flight | Verify git repo, note working directory |
| Signal detection | Run bash commands to detect stack, commands, structure, docs |
| Ambiguity resolution | Pause and ask user if multiple candidates for the same signal |
| Discovery summary | Output grouped findings; user must confirm or correct |
| CLAUDE.md write/update | Case A (create) or Case B (diff + approval) |
| Post-write confirmation | Output path, line count, context inheritance reminder |

---

## Data Flow

```
User: /dev-framework:init-brownfield
         │
         ▼
  [Pre-flight]
  Is this a git repo? (git status)
  Note working directory
         │
         ▼
  [Signal Detection] — bash commands (see below)
  ┌─────────────────────────────────┐
  │ Stack:     package.json, go.mod, pyproject.toml,  │
  │            Cargo.toml, Gemfile, pom.xml            │
  │ Commands:  scripts in package.json / Makefile /    │
  │            justfile / pytest.ini / go test         │
  │ Structure: find -maxdepth 2 (excl. node_modules,  │
  │            .git, vendor)                           │
  │ Lint/fmt:  .eslintrc*, .prettierrc*, .flake8,     │
  │            .golangci.yml, ruff.toml               │
  │ Docs:      README.md (first paragraph),            │
  │            existing CLAUDE.md                      │
  └─────────────────────────────────┘
         │
         ▼
  [Ambiguity Resolution]
  Multiple test runners found? → ask user to pick
  Multiple package roots found? → ask canonical or document all
         │
         ▼
  [Discovery Summary — user confirmation]
  Show grouped: Stack | Commands | Structure | Docs
  "Does this look correct? Type yes or describe corrections."
  Apply corrections if any
         │
         ▼
  ┌──────────────────────┐
  │ CLAUDE.md exists?    │
  │  < 5 lines → Case A  │
  │  No → Case A         │
  │  Yes, full → Case B  │
  └──────────────────────┘
         │                  │
      Case A              Case B
   Generate from         Semantic diff:
   scratch using         - missing signals
   confirmed findings    - stale entries
                         - preserved sections
                         Show change list
                         Require "yes" approval
         │                  │
         └──────┬───────────┘
                ▼
        Write CLAUDE.md
                │
                ▼
  Post-write: path + line count + context note
```

---

## Signal Detection Commands

These are the exact bash commands the skill instructs Claude to run:

```bash
# Stack config files (depth ≤ 2, exclude generated dirs)
find . -maxdepth 2 \( -name "package.json" -o -name "go.mod" -o -name "pyproject.toml" \
  -o -name "Cargo.toml" -o -name "Gemfile" -o -name "pom.xml" -o -name "*.csproj" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null

# Directory structure (depth ≤ 2, exclude noise)
find . -maxdepth 2 -type d \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  -not -path "*/vendor/*" -not -path "*/__pycache__/*" \
  | sort

# Test runner configs
find . -maxdepth 2 \( -name "jest.config.*" -o -name "vitest.config.*" \
  -o -name "pytest.ini" -o -name "setup.cfg" -o -name ".mocharc*" \
  -o -name "karma.conf.*" \) 2>/dev/null

# Linter / formatter configs
find . -maxdepth 2 \( -name ".eslintrc*" -o -name "eslint.config.*" \
  -o -name "prettier.config.*" -o -name ".prettierrc*" \
  -o -name ".flake8" -o -name ".golangci.yml" -o -name "ruff.toml" \) 2>/dev/null

# CI/CD presence (informational only, not written to CLAUDE.md)
find . -maxdepth 3 -name "*.yml" -path "*/.github/workflows/*" 2>/dev/null | head -5
ls Makefile justfile Procfile docker-compose.yml 2>/dev/null
```

After running, Claude reads `package.json` (if found) to extract `scripts.build`, `scripts.test`, `scripts.dev`, `scripts.lint`, and `dependencies`/`devDependencies` for framework/library identification.

---

## CLAUDE.md Output Template (Case A)

```markdown
# [Project Name]

## Project Overview
[First paragraph of README.md, or "No README found — add a description here."]

## Tech Stack
- **Language:** [detected]
- **Framework:** [detected, or "not detected"]
- **Key Libraries:** [top 5-8 from dependencies, or "not detected"]

## Directory Structure
[Top-level dirs with one-line labels derived from names]

## Commands
- **Build:** `[command]`   ← "not detected" if unknown
- **Test:** `[command]`
- **Dev:** `[command]`
- **Lint:** `[command]`

## Coding Conventions
[Derived from linter config names, e.g. "ESLint + Prettier (see .eslintrc.js)"]
["not detected" if no linter configs found]

## Key Files
[package.json / go.mod / main entry point, one line each]
```

---

## Case B: Semantic Diff Approach

Claude (as the executing agent) reads both the existing CLAUDE.md and the discovered signals, then classifies changes into three buckets:

| Bucket | Example | Action |
|---|---|---|
| **Add** | Test command not in CLAUDE.md | Add to Commands section |
| **Update** | CLAUDE.md says React 16, detected React 19 | Replace inline |
| **Preserve** | User-written "Team conventions" section | Leave untouched |

The change list is presented as a bullet list before writing. User types "yes" to apply or describes corrections inline.

**Idempotency:** If all discovered signals already match CLAUDE.md accurately, output: `CLAUDE.md is up to date — no changes needed.` and stop without writing.

---

## File Structure

```
skills/
└── init-brownfield/
    └── SKILL.md          ← sole deliverable
```

No other files. The skill does not create or modify anything in `.dev-framework/`.

---

## Implementation Map

| # | File | Action |
|---|---|---|
| 1 | `skills/init-brownfield/SKILL.md` | **Create** — complete skill prompt implementing all six phases |

---

## Key Design Decisions

**1. No bash helper scripts — skill prompt only.**
Every other skill in this framework is a single SKILL.md. Introducing a companion bash script would break the convention and add a maintenance surface. Claude's ability to run ad-hoc bash commands within the skill prompt is sufficient for all detection needs.

**2. Semantic diff, not textual diff.**
Case B comparison is done by Claude reading both sources and reasoning about coverage, not by running `diff`. This handles reformatted CLAUDE.md files gracefully and preserves user-written prose sections that a textual diff would flag as changes.

**3. Skill is pre-framework — no workspace created.**
`init-brownfield` is an onboarding tool. It writes CLAUDE.md and exits. It does not create a `.dev-framework/` workspace, does not set `current-workspace`, and does not start a phase chain. This keeps concerns separate: onboarding vs. development workflow.

**4. Detection depth capped at 2 for config files, 2 for structure.**
Deeper scans risk false positives (nested node_modules, vendored copies) and slow down large repos. Root-level and one level deep covers 99% of real project layouts.

---

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| `node_modules/package.json` files produce false positives | All `find` commands exclude `*/node_modules/*` |
| Existing CLAUDE.md has this framework's enforcement rules — overwriting them breaks the framework | Case B preserves all sections not touched by analysis; enforcement rules section will be preserved |
| Monorepo with 10+ roots overwhelms the user prompt | Cap presented roots at 5, with a count note; ask canonical vs. document-all once |
| Unknown stack produces empty CLAUDE.md | Partial output is valid — each undetected section gets an explicit "not detected" placeholder rather than being omitted |
| User runs command from a subdirectory | Pre-flight step checks for `CLAUDE.md` and `package.json` at cwd; warns if repo root appears to be a parent directory |
