# PO Artifact — assign-model-for-commands

## Problem Statement
All 23 dev-framework skills currently have no `model:` in their frontmatter and inherit whatever model the calling conversation uses. The 6 agents all hardcode `model: sonnet` regardless of task complexity. This wastes cost on lightweight tasks (session management, file lookups) and under-specs high-value tasks (architecture planning). The goal is to assign each skill and agent the most appropriate model tier based on its cognitive demand.

## User Stories
- As a developer using the framework, I want lightweight skills (start-of-day, status, list-bugs) to run on Haiku so they are fast and cheap.
- As a developer, I want requirement gathering (po-requirements agent) to stay on Sonnet for nuanced conversation.
- As a developer, I want architecture and planning (architect-design agent) to use Opus for the highest reasoning quality.
- As a developer, I want implementation and testing agents (developer-executor, tester-validation) to use Haiku since they follow explicit instructions rather than reason deeply.
- As a developer, I want reviewer and observer agents to use Sonnet for quality analysis without the cost of Opus.
- As a developer, I want orchestration and session skills to use Haiku since they are coordination scripts, not reasoning tasks.
- As a developer, I want the explore and init-brownfield skills to use Sonnet for conversational discovery and analysis.

## Functional Requirements

### Agents — model assignments
| Agent file | Current model | New model |
|---|---|---|
| `agents/po-requirements.md` | sonnet | sonnet (no change) |
| `agents/architect-design.md` | sonnet | opus |
| `agents/developer-executor.md` | sonnet | haiku |
| `agents/reviewer-quality.md` | sonnet | sonnet (no change) |
| `agents/tester-validation.md` | sonnet | haiku |
| `agents/observer-observability.md` | sonnet | sonnet (no change) |

### Skills — model assignments
**Haiku** (session management, simple lookups, orchestration, file I/O):
- `skills/start-of-day/skill.md`
- `skills/end-of-day/skill.md`
- `skills/status/skill.md`
- `skills/list-bugs/skill.md`
- `skills/list-workspaces/skill.md`
- `skills/view-bug/skill.md`
- `skills/switch-workspace/skill.md`
- `skills/new-feature/skill.md`
- `skills/hand-off/skill.md`
- `skills/handoff-orchestrator/skill.md`
- `skills/continue/skill.md`
- `skills/bugfix/skill.md`
- `skills/hotfix/skill.md`
- `skills/minor-enhancement/skill.md`
- `skills/upgrade-feature/skill.md`
- `skills/archive-feature/skill.md`
- `skills/framework-manager/skill.md`
- `skills/artifact-generator/skill.md`
- `skills/bug-manager/skill.md`
- `skills/create-bug/skill.md`

**Sonnet** (conversational discovery, analysis, observability):
- `skills/explore/skill.md`
- `skills/init-brownfield/skill.md`
- `skills/observe/skill.md`

### Implementation
- Add `model: <tier>` to the YAML frontmatter of each skill and agent file listed above.
- Use short aliases: `haiku`, `sonnet`, `opus` (consistent with existing codebase convention).
- Do not add a central manifest; frontmatter is the single source of truth.

## Non-Functional Requirements
- No behaviour change — model assignment affects which Claude model runs, not the skill/agent logic.
- Changes are purely additive (adding a frontmatter key); no skill content is modified.
- Skills that already have the correct model (po-requirements, reviewer-quality, observer-observability all already `sonnet`) still get the key written explicitly for consistency.

## Acceptance Criteria
- Every skill `skill.md` has a `model:` key in its frontmatter.
- Every agent `.md` has a `model:` key matching the table above.
- `grep -r "^model:" skills/ agents/` returns exactly 29 lines (23 skills + 6 agents).
- `grep "^model: opus" agents/` returns exactly 1 line (`architect-design.md`).
- `grep "^model: haiku" skills/` returns exactly 20 lines.
- `grep "^model: sonnet" skills/` returns exactly 3 lines.
- `grep "^model: haiku" agents/` returns exactly 2 lines (developer-executor, tester-validation).
- No skill content (instructions, steps, tool lists) is modified.

## Edge Cases
- If a skill frontmatter already contains a `model:` key (none currently do), overwrite it with the assigned value.
- If a skill has no frontmatter delimiters (`---`) at all, add them before inserting the `model:` key.
- The `tester-validation.md` agent file is in `agents/` despite not appearing in the initial `ls` output — confirm file exists before editing.

## Dependencies
- Requires read access to all 23 `skills/*/skill.md` files and 6 `agents/*.md` files.
- No external dependencies.
