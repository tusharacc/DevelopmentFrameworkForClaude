# PO Requirements — brownfield-repo-analyzer

## Problem Statement

When the dev framework is adopted on an existing (brownfield) project, there is no mechanism to analyze the repository and establish a shared context. Without this, every workflow phase (PO, Architect, Developer) operates blind — unaware of the existing tech stack, conventions, test setup, or documentation. This forces developers to manually write CLAUDE.md from scratch and re-explain the codebase to every agent. The `init-brownfield` command solves this by running a structured analysis pass upfront, producing or correcting CLAUDE.md, and giving all subsequent framework phases a grounded context to work from.

## User Stories

1. As a developer adopting the framework on an existing project, I want to run a single command that analyzes my repo so I don't have to manually write CLAUDE.md from scratch.
2. As a developer with a partial or outdated CLAUDE.md, I want the command to identify gaps and incorrect entries and offer to correct them — without silently overwriting my existing content.
3. As a developer with an ambiguous project setup (e.g., multiple test runners detected), I want the command to ask me to clarify rather than guessing wrong.
4. As a developer, I want to see a summary of what was discovered before anything is written, so I can catch mistakes before they land in CLAUDE.md.

## Functional Requirements

### FR-1: Command invocation
- Implemented as a slash command: `/dev-framework:init-brownfield`
- Works from any directory that is a git repository
- Can be re-run on a project that already has a CLAUDE.md (refresh mode)

### FR-2: Repository analysis
The command must scan and extract the following:

| Signal | Sources |
|---|---|
| Primary language(s) | File extensions, `package.json`, `go.mod`, `pyproject.toml`, `Cargo.toml`, `Gemfile`, `pom.xml`, `.csproj` |
| Frameworks and major libraries | `package.json` dependencies, `requirements.txt`, `go.mod` require block |
| Directory structure | Top-level directories + key src/test/config paths (depth ≤ 3) |
| Build command | `package.json` scripts (`build`, `compile`), `Makefile` targets, `justfile` |
| Test command | `package.json` scripts (`test`, `test:unit`), `pytest.ini`, `jest.config.*`, `vitest.config.*`, `go test` |
| Dev/run command | `package.json` scripts (`dev`, `start`), `Procfile`, `docker-compose.yml` |
| Linters/formatters | `.eslintrc*`, `prettier.config*`, `.flake8`, `pyproject.toml [tool.ruff]`, `.golangci.yml` |
| Existing documentation | `README.md` (summary/description section), existing `CLAUDE.md` |

### FR-3: Ambiguity resolution
- If two or more equally valid candidates are found for any signal (e.g., both Jest and Vitest config files exist), pause and ask the user to pick one before continuing.
- Present the candidates clearly with filenames so the user can make an informed choice.

### FR-4: Discovery summary
- Before writing anything, output a structured summary of all findings grouped by category (stack, commands, structure, documentation).
- Ask the user: "Does this look correct? Type yes to proceed or describe any corrections."
- Apply any corrections the user gives before writing.

### FR-5: CLAUDE.md creation and correction

**Case A — No CLAUDE.md exists:**
- Generate CLAUDE.md from scratch using the confirmed findings.
- Sections: Project Overview, Tech Stack, Directory Structure, Commands (build/test/dev/lint), Coding Conventions, Key Files.

**Case B — CLAUDE.md exists:**
- Diff discovered findings against existing CLAUDE.md content.
- Identify: missing sections, stale commands, incorrect stack entries.
- Show a change summary ("Adding missing test command", "Updating stack: React 17 → React 19").
- Require explicit user approval ("Type yes to apply changes") before writing.
- Preserve any sections not touched by the analysis (e.g., custom notes the user has written).

### FR-6: Post-write confirmation
- After writing CLAUDE.md, output the final path and line count.
- Remind the user that subsequent framework commands (new-feature, bugfix, etc.) will now inherit this context.

## Non-Functional Requirements

- **NFR-1 Speed:** Analysis should complete in under 30 seconds for repos up to 10,000 files.
- **NFR-2 Safety:** Never overwrite CLAUDE.md without explicit user approval.
- **NFR-3 Portability:** Must work across any language stack; unknown stacks should produce a partial result with a note rather than failing.
- **NFR-4 Idempotent:** Running the command twice on an unchanged repo should produce no changes on the second run.

## Acceptance Criteria

- [ ] `/dev-framework:init-brownfield` is a valid invocable skill.
- [ ] Running on a repo with no CLAUDE.md creates one with all discoverable sections populated.
- [ ] Running on a repo with an existing CLAUDE.md shows a diff and requires approval before writing.
- [ ] When two test runners are detected, the command asks the user to choose before proceeding.
- [ ] Discovery summary is shown and user must confirm before any file is written.
- [ ] Unknown/unsupported stacks produce a partial CLAUDE.md with an explicit "could not detect" note.
- [ ] Re-running on an unchanged repo results in no changes applied.

## Edge Cases

- **Monorepo:** Multiple `package.json` / `go.mod` at different paths — list all detected roots and ask user which is canonical, or document all.
- **No README.md:** Skip that signal; do not fail.
- **CLAUDE.md is empty or < 5 lines:** Treat as Case A (create from scratch).
- **Conflicting commands in README vs config files:** Prefer config files; note the discrepancy.
- **Non-git directory:** Warn the user; proceed with analysis but skip any git-derived signals.

## Dependencies

- Must be implemented as a skill file under `skills/init-brownfield/` following the existing skill convention.
- Reads but does not modify `.dev-framework/` state (this command is pre-framework-workflow, not a phase).
- Output file: `CLAUDE.md` at the repo root (or path specified by user if non-standard).
