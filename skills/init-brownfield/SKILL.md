---
name: init-brownfield
description: Analyze an existing repository and create or update CLAUDE.md with discovered tech stack, directory structure, commands, and conventions. Use this when adopting the dev framework on a project that was not built with it.
arguments: ""
examples:
  - /dev-framework:init-brownfield
---

You are running a brownfield repository analysis. Your goal is to discover the project's tech stack, structure, and commands, then create or update CLAUDE.md so all future framework phases inherit accurate project context.

This command does NOT create a workspace or modify `.dev-framework/` state. It is a pre-framework onboarding tool.

Follow these steps exactly.

---

## Step 1: Pre-flight

Run:
```bash
git status 2>/dev/null && echo "GIT_OK" || echo "NOT_GIT"
pwd
```

If output contains `NOT_GIT`, warn the user:
> "Warning: this directory does not appear to be a git repository. Analysis will continue but git-derived signals will be skipped."

Note the working directory as `$REPO_ROOT`.

Check whether you appear to be in a subdirectory of a larger project (i.e., there is a `package.json`, `go.mod`, or `CLAUDE.md` in a parent directory but not the current one). If so, warn:
> "Warning: it looks like the repo root may be at [parent path]. Running analysis here at [cwd]. If that's wrong, `cd` to the repo root and re-run."

---

## Step 2: Signal Detection

Run each of the following bash commands and record the output. Do not skip a command because you expect no output — always run it.

**2a. Stack config files**
```bash
find . -maxdepth 2 \( \
  -name "package.json" -o -name "go.mod" -o -name "pyproject.toml" \
  -o -name "Cargo.toml" -o -name "Gemfile" -o -name "pom.xml" -o -name "*.csproj" \
  \) -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/vendor/*" \
  2>/dev/null | sort
```

**2b. Directory structure**
```bash
find . -maxdepth 2 -type d \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  -not -path "*/vendor/*" -not -path "*/__pycache__/*" \
  -not -path "*/.next/*" -not -path "*/dist/*" -not -path "*/build/*" \
  2>/dev/null | sort
```

**2c. Test runner configs**
```bash
find . -maxdepth 2 \( \
  -name "jest.config.*" -o -name "vitest.config.*" -o -name "pytest.ini" \
  -o -name "setup.cfg" -o -name ".mocharc*" -o -name "karma.conf.*" \
  -o -name "phpunit.xml" -o -name "*.test-config.*" \
  \) 2>/dev/null | sort
```

**2d. Linter and formatter configs**
```bash
find . -maxdepth 2 \( \
  -name ".eslintrc*" -o -name "eslint.config.*" \
  -o -name "prettier.config.*" -o -name ".prettierrc*" \
  -o -name ".flake8" -o -name ".golangci.yml" -o -name "ruff.toml" \
  -o -name ".rubocop.yml" -o -name "checkstyle*.xml" \
  \) 2>/dev/null | sort
```

**2e. Build / task runners**
```bash
ls -1 Makefile justfile Procfile docker-compose.yml docker-compose.yaml 2>/dev/null
```

**2f. CI/CD presence (informational)**
```bash
find . -maxdepth 3 -name "*.yml" -path "*/.github/workflows/*" 2>/dev/null | head -5
find . -maxdepth 2 -name "Jenkinsfile" -o -name ".circleci" -o -name ".travis.yml" 2>/dev/null | head -5
```

**2g. Read key config files**

If `package.json` was found at root (`.` or `./package.json`), read it and extract:
- `name` → project name
- `scripts.build`, `scripts.test`, `scripts.dev`, `scripts.start`, `scripts.lint` → commands
- `dependencies` and `devDependencies` keys → libraries (top 10 by name length, shortest first)

If `go.mod` was found, read it and extract: module name, Go version, top-level `require` entries (direct only).

If `pyproject.toml` was found, read it and extract: `[project].name`, `[project].dependencies`, `[tool.pytest.*]` or `[tool.ruff.*]` sections.

If `Cargo.toml` was found, read it and extract: `[package].name`, `[dependencies]` keys.

**2h. Read existing documentation**

Read `README.md` if it exists. Extract: the first non-empty paragraph after the title (this becomes the Project Overview). Do not read more than 60 lines.

Read `CLAUDE.md` if it exists. Store its full contents as `$EXISTING_CLAUDE_MD`. Note its line count. If it has fewer than 5 non-empty lines, treat it as absent (proceed with Case A).

---

## Step 3: Ambiguity Resolution

Before proceeding, check for the following conflicts. For each one found, pause and ask the user to resolve it before continuing to the next step.

**3a. Multiple test runners**
If two or more distinct test runner configs were found (e.g., both `jest.config.js` and `vitest.config.ts`), ask:
> "Multiple test runners detected: [list files]. Which is the active one, or should I document both?"

**3b. Multiple package roots (monorepo)**
If `package.json` (or `go.mod`) was found at more than one path at depth ≤ 2, ask:
> "Multiple package roots detected:
> [list paths]
> Which should I treat as the primary root? Or should I document all of them?"
> (If more than 5 roots found, list only the first 5 and note the count.)

**3c. Conflicting commands**
If `README.md` mentions a build/test command that differs from what's in `package.json` scripts or a `Makefile`, note both sources and prefer the config file. Flag the discrepancy in the output but do not ask the user — just note it.

Resolve all ambiguities before proceeding. Do not move to Step 4 until each one is answered.

---

## Step 4: Discovery Summary

Compile all findings into a structured summary and output it to the user. Use this exact format:

```
──────────────────────────────────────────
BROWNFIELD ANALYSIS — [project name or repo dir name]
──────────────────────────────────────────

STACK
  Language:    [e.g. TypeScript / Go / Python — or "not detected"]
  Framework:   [e.g. Next.js 14, Express, FastAPI — or "not detected"]
  Key libs:    [comma-separated top libs — or "not detected"]

COMMANDS
  Build:  [command — or "not detected"]
  Test:   [command — or "not detected"]
  Dev:    [command — or "not detected"]
  Lint:   [command — or "not detected"]

STRUCTURE
  [one line per top-level directory with a short label]

CONVENTIONS
  [linter/formatter names — or "not detected"]

DOCUMENTATION
  README:    [found / not found]
  CLAUDE.md: [found (N lines) / not found]

CI/CD
  [workflow file names — or "not detected"]
──────────────────────────────────────────
```

Then ask:
> "Does this look correct? Type **yes** to proceed, or describe any corrections."

Wait for the user's response.

- If "yes" (or equivalent): proceed to Step 5.
- If corrections are given: apply them to the compiled findings, briefly confirm what changed ("Updated: test command is `pytest -v`, not `python -m pytest`"), then proceed to Step 5 without asking again.

---

## Step 5: Write or Update CLAUDE.md

### Determine case

- **Case A** — `CLAUDE.md` does not exist, OR existing CLAUDE.md has fewer than 5 non-empty lines: generate from scratch.
- **Case B** — `CLAUDE.md` exists with 5+ non-empty lines: compute semantic diff and require approval.

---

### Case A — Generate from scratch

Write `CLAUDE.md` at `$REPO_ROOT/CLAUDE.md` using this template, substituting confirmed findings:

```markdown
# [project name]

## Project Overview
[First paragraph from README.md, or: "Add a brief description of this project here."]

## Tech Stack
- **Language:** [detected, or "not detected"]
- **Framework:** [detected, or "not detected"]
- **Key Libraries:** [comma-separated, or "not detected"]

## Directory Structure
[One line per top-level directory: `dir/` — brief label]

## Commands
- **Build:** `[command]` *(not detected)*
- **Test:** `[command]` *(not detected)*
- **Dev:** `[command]` *(not detected)*
- **Lint:** `[command]` *(not detected)*

## Coding Conventions
[e.g. "ESLint + Prettier (see .eslintrc.js and .prettierrc)" — or "not detected"]

## Key Files
[One line per key config file found: `filename` — purpose]
```

Rules:
- Replace `*(not detected)*` with the actual value when known; keep the literal text `not detected` when unknown so it is easy to grep for later.
- Omit the `*(not detected)*` annotation when the value is known.
- Do not add sections beyond those in the template.
- Do not add comments explaining that this file was auto-generated.

---

### Case B — Semantic diff and approval

Read the confirmed findings and the existing `$EXISTING_CLAUDE_MD`. Classify every discoverable signal into one of three buckets:

| Bucket | Condition | Display |
|---|---|---|
| **Add** | Signal found; not present in existing CLAUDE.md | `+ Adding: [description]` |
| **Update** | Signal found; existing CLAUDE.md has a different value | `~ Updating: [old] → [new]` |
| **Preserve** | Section in CLAUDE.md not covered by analysis | `= Preserving: [section name]` |

Output the change list:
```
Proposed changes to CLAUDE.md:
  + Adding: test command (`npm test`)
  ~ Updating: Framework — React 16 → React 19
  = Preserving: "Team Conventions" section (untouched)
  ...
```

If there are zero `+` and zero `~` entries, output:
> "CLAUDE.md is already up to date — no changes needed."
Then go to Step 6. Do not write the file.

Otherwise, ask:
> "Type **yes** to apply these changes, or describe corrections."

Wait for the user's response. If "yes", apply changes. If corrections given, apply them, confirm briefly, then write.

When writing:
- Merge changes into the existing file structure where possible.
- Preserve all `= Preserving` sections verbatim.
- Do not reorder sections unless adding a new one (append at the end).

---

## Step 6: Post-write Confirmation

After writing (or confirming no changes needed), output:

```
✓ CLAUDE.md written: [absolute path] ([N] lines)

All future framework commands run from this repository will now inherit
this project context. Suggested next step:

  /dev-framework:new-feature "[your feature name]"
  /dev-framework:bugfix "[bug description]"
```

Stop here. Do not create any workspace, do not modify `.dev-framework/`.
