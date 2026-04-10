---
name: observe
description: Run observability checks in parallel (linting, types, security, performance, accessibility)
arguments: ""
examples:
  - /dev observe
---

# /dev observe

Manually trigger observability checks. Normally runs in parallel during development.

## Usage

```
/dev observe
```

## What Runs

1. **Linting & Format**
   - ESLint: code style violations
   - Prettier: formatting check
   - Stylelint: stylesheet linting

2. **Type Safety**
   - TypeScript: type errors
   - Type coverage: % of code with types

3. **Security**
   - Secret scanning: API keys, credentials
   - Dependency audit: vulnerable packages
   - SAST: security pattern analysis

4. **Performance**
   - Bundle size: code size impact
   - Load time: performance metrics
   - Memory usage: leaks, efficiency

5. **Accessibility**
   - WCAG 2.1 AA: compliance check
   - Keyboard navigation: keyboard access
   - Screen reader: assistive tech support

## Output

```
════════════════════════════════════════════════════
  OBSERVABILITY CHECKS
════════════════════════════════════════════════════

[1/5] Linting & Format...
✓ ESLint: 0 errors
✓ Prettier: Formatted
⚠ Stylelint: 2 warnings

[2/5] Type Safety...
✓ TypeScript: 0 errors
📊 Coverage: 92%

[3/5] Security Scanning...
⚠ Secrets: 0 found (but check carefully)
✗ Dependencies: 3 medium vulnerabilities
  • lodash@4.17.19 (upgrade to 4.17.21)
  • moment@2.29.0 (consider @date-fns)

[4/5] Performance...
✓ Bundle: +2 KB (+0.5%)
✓ Load Time: +50 ms
✓ Memory: Stable

[5/5] Accessibility...
✓ WCAG 2.1 AA: Compliant
✓ Keyboard: Full navigation
✓ Screen Readers: Tested

════════════════════════════════════════════════════
  SUMMARY
════════════════════════════════════════════════════

✓ Overall: GOOD
⚠ Warnings: 3 (address before release)
✗ Critical Issues: 1 (fix before release)

See observability artifact for details:
  /dev view-artifact {feature-name}.observe.md

════════════════════════════════════════════════════
```

## When to Use

**Automatic** (during development):
- Runs in parallel with Developer and Reviewer phases
- Continuous monitoring
- Updates throughout development

**Manual** (when needed):
- Run `/dev observe` anytime
- Check progress independently
- Get fresh scan results
- Before handoff to verify

## Issues by Severity

| Level | Action | Examples |
|-------|--------|----------|
| Critical | Must fix | Type errors, secrets, vulnerabilities |
| High | Should fix | Linting errors, a11y failures |
| Medium | Nice to fix | Warnings, performance issues |
| Low | Optional | Style suggestions |

## After Checks

Results saved in artifact:
```
.dev-framework/artifacts/{feature-name}.observe.md
```

View detailed results:
```bash
/dev view-artifact {feature-name}.observe.md
```

## Tools Used

- **ESLint** - JavaScript linting
- **Prettier** - Code formatting
- **Stylelint** - CSS/SCSS linting
- **TypeScript** - Type checking
- **npm audit** - Dependency security
- **TruffleHog/gitleaks** - Secret scanning
- **webpack-bundle-analyzer** - Bundle analysis
- **Lighthouse** - Performance audit
- **axe-core** - Accessibility testing

## Performance Comparison

Observability tracks changes:
```
Feature baseline:
  Bundle: 125 KB
  Load Time: 2.5s
  
After implementation:
  Bundle: 127 KB (+2 KB, +1.6%)
  Load Time: 2.55s (+50 ms, +2%)
  
Assessment: Acceptable impact
```

## Security Focus

Checks for common issues:
- API keys hardcoded
- Database credentials exposed
- JWT tokens in code
- Sensitive data in logs
- Known vulnerable dependencies

## Accessibility Standards

WCAG 2.1 Level AA compliance:
- Color contrast: 4.5:1 for text
- Keyboard accessible: all features
- Screen reader: proper ARIA labels
- Focus indicators: visible
- Alternative text: images described

## Tips

1. **Run Early**: Check frequently during development
2. **Fix Critical**: Don't handoff with critical issues
3. **Review Results**: Understand what each issue means
4. **Improve Baseline**: Fix accessibility/security proactively
5. **Document**: Note any acceptable trade-offs

## Related Commands

- `/dev status` - Check current phase
- `/dev view-artifact {name}.observe.md` - View detailed report
- `/dev hand-off` - Submit for next phase (with clean observability)

Observability runs in parallel throughout development to catch issues early!
