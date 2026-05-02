---
name: observe
description: Run observability checks on the current workspace (linting, types, security, performance, accessibility)
arguments: ""
examples:
  - /dev observe
---

Run observability checks for the current workspace.

## Step 1: Identify current workspace

Read `.dev-framework/current-workspace`. If empty, output "No active workspace." and stop.

## Step 2: Determine project type

Check for relevant config files to understand what checks apply:
- `package.json` → Node/JS/TS project
- `tsconfig.json` → TypeScript
- `pyproject.toml` / `requirements.txt` → Python
- `Cargo.toml` → Rust

## Step 3: Run available checks

Run each check that is applicable to the project. Output results as you go:

**Linting**
```bash
npx eslint . --max-warnings=0 2>/dev/null || \
  python -m flake8 . 2>/dev/null || \
  echo "No linter configured"
```

**Type checking**
```bash
npx tsc --noEmit 2>/dev/null || \
  python -m mypy . 2>/dev/null || \
  echo "No type checker configured"
```

**Security / dependency audit**
```bash
npm audit --audit-level=moderate 2>/dev/null || \
  pip-audit 2>/dev/null || \
  echo "No audit tool found"
```

**Secret scanning** (check for common patterns)
```bash
grep -rn "api_key\|secret\|password\|token" --include="*.ts" --include="*.py" --include="*.js" \
  --exclude-dir=node_modules --exclude-dir=.git . 2>/dev/null | grep -v "test\|spec\|example" | head -10
```

**Code quality — Simplify, Secure Coding, Secret Detection**
Invoke `skills/code-quality/code-quality.md` in observe mode.
This runs all three code-quality sub-agents and writes a report to `.dev-framework/artifacts/$SLUG.code-quality-report.md`.
All findings are advisory in observe mode — no hand-off is blocked.

## Step 4: Write results to artifact

Read the workspace slug from `.dev-framework/current-workspace`.
Append results to `.dev-framework/artifacts/$SLUG.observe.md`, creating it if it doesn't exist.

## Step 5: Output summary

```
════════════════════════════════
  OBSERVABILITY: $SLUG
════════════════════════════════

[results from each check]

Summary:
  Critical issues: N (must fix before handoff)
  Warnings: N
  Results saved to: .dev-framework/artifacts/$SLUG.observe.md
════════════════════════════════
```

Flag any critical issues (secrets found, type errors, high-severity vulnerabilities) clearly so the user knows what must be fixed before running `/dev hand-off`.
