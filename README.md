# Development Framework Plugin

Streamlined development workflow orchestrator for Claude Code. Replaces chaotic multi-prompt development with structured, role-based sequential workflows.

## Features

- **6 Role-Based Agents**: PO → Architect → Developer → Reviewer → Tester (+ Observability parallel)
- **Workspace Isolation**: New features/upgrades get isolated workspaces and branches
- **Artifact Generation**: Each phase produces markdown artifacts for audit and review
- **Auto-Commit**: Git commits automatically at phase boundaries
- **State Management**: Full tracking of progress through workflow
- **Bug Management**: Centralized bug indexing and tracking
- **Less Verbose**: Streamlined prompts, skips irrelevant questions

## Quick Start

```bash
# Start a new feature
/dev new-feature "User authentication"

# Check current status
/dev status

# Advance to next phase
/dev hand-off

# View all artifacts
/dev list-artifacts

# Archive completed feature
/dev archive-feature "User authentication"
```

## Commands

### Core Workflow
- `/dev new-feature <name>` - Start new feature (PO → full workflow)
- `/dev upgrade-feature <name>` - Major feature upgrade (new branch/workspace)
- `/dev bugfix <bug-id>` - Bug fix workflow (skip PO/Architect)
- `/dev hand-off` - Advance to next phase
- `/dev status` - Show current project state
- `/dev phase <phase-name>` - Direct phase control

### Management
- `/dev list-workspaces` - List all workspaces
- `/dev switch-workspace <name>` - Switch active workspace
- `/dev archive-feature <name>` - Archive completed feature
- `/dev list-artifacts` - List all artifacts
- `/dev view-artifact <artifact>` - View artifact content

### Bug Management
- `/dev list-bugs` - List all bugs
- `/dev create-bug` - Create new bug
- `/dev bugfix <bug-id>` - Start bug fix workflow

### Quality
- `/dev observe` - Run observability checks (linting, types, security, perf)

## Workflow Architecture

```
/dev new-feature "auth"
  ↓
[PO Phase: Gather requirements]
  /dev hand-off
    ↓
[Architect Phase: Design solution]
  /dev hand-off
    ↓
[Developer Phase: Implement]
  [Observability: Parallel checks]
  /dev hand-off
    ↓
[Reviewer Phase: Code review]
  /dev hand-off
    ↓
[Tester Phase: Validate]
  ↓
/dev archive-feature "auth"
```

## Change Types

| Type | Phases | Branch | Workspace | Best For |
|------|--------|--------|-----------|----------|
| New Feature | All 6 | New | New | Significant new capability |
| Major Upgrade | All 6 | New | New | Major version bump |
| Bug Fix | 4 (skip PO/Arch) | Existing | Reuse | Fix existing bugs |
| Minor Change | 2-3 (Dev+Review) | Existing | Reuse | Small tweaks |

## State Management

All workflow state stored in `/.dev-framework/`:
- `workspaces/` - Active workspace state and context
- `artifacts/` - Phase artifacts (requirements, design, implementation, review, tests, observability)
- `bugs/` - Bug tracking with centralized index
- `archived/` - Snapshots of completed features for reference

## For Development Team

Each role is implemented as a separate agent with specific tools and responsibilities:

- **PO Agent**: Gathers requirements and success criteria
- **Architect Agent**: Analyzes patterns, designs technical solution
- **Developer Agent**: Implements, tests, commits
- **Reviewer Agent**: Code review, quality checks
- **Tester Agent**: Full test validation, regression testing
- **Observer Agent**: Linting, types, security, performance, accessibility (runs parallel)

## Less Verbose Design

- Skips innovation questions during requirements gathering
- Streamlined handoffs between roles
- Reuses existing patterns and artifacts
- No back-and-forth for clarifications already covered

## Configuration

See `.claude-plugin/plugin.json` for plugin configuration.

## Directory Structure

```
.dev-framework/
├── .claude-plugin/plugin.json      # Plugin manifest
├── commands/                        # User-facing commands
├── agents/                          # 6 role agents
├── skills/                          # Utility skills
├── artifacts/                       # Phase artifacts (runtime)
├── workspaces/                      # Workspace state (runtime)
├── bugs/                            # Bug tracking (runtime)
└── archived/                        # Completed features (runtime)
```

## Example Workflow

```bash
# Start new authentication feature
/dev new-feature "User authentication system"

# View requirements gathered by PO
/dev view-artifact user-auth.po.md

# Architect designs the solution
/dev hand-off

# View architecture design
/dev view-artifact user-auth.architect.md

# Developer implements
/dev hand-off

# See implementation progress
/dev view-artifact user-auth.dev.md

# Reviewer checks code
/dev hand-off

# Tester validates
/dev hand-off

# Archive when complete
/dev archive-feature "User authentication system"

# View archived snapshot
/dev list-artifacts
```

## License

MIT
