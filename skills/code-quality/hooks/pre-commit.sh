#!/usr/bin/env bash
# Secret detection pre-commit hook
# Installed by the code-quality skill. Prepended to any existing hook content.
# To suppress a known false positive, add an entry to .code-quality-ignore
# with a justification comment on the preceding line.
# Note: git commit --no-verify bypasses this hook. Complement with CI enforcement.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
IGNORE_FILE="$REPO_ROOT/.code-quality-ignore"

# Patterns to detect (name:regex pairs, tab-separated)
declare -A PATTERNS=(
  [AWS_ACCESS_KEY_ID]="AKIA[0-9A-Z]{16}"
  [PRIVATE_KEY_PEM]="-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"
  [BEARER_TOKEN]="[Bb]earer[[:space:]]+[A-Za-z0-9_.-]{20,}"
  [JWT_TOKEN]="eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"
  [GITHUB_PAT]="gh[pousr]_[A-Za-z0-9]{36,}"
  [GITLAB_PAT]="glpat-[A-Za-z0-9_-]{20,}"
  [SLACK_TOKEN]="xox[baprs]-[0-9A-Za-z-]{10,}"
  [STRIPE_KEY]="sk_(live|test)_[A-Za-z0-9]{24,}"
  [DB_CONN_WITH_CREDS]="(postgres|mysql|mongodb|redis)://[^:]+:[^@]+@"
  [HARDCODED_PASSWORD]="(password|passwd|pwd)[[:space:]]*[=:][[:space:]]*[\"'][^\"']{8,}[\"']"
)

# Build allowlist from .code-quality-ignore
build_allowlist() {
  local -a allowed=()
  if [[ -f "$IGNORE_FILE" ]]; then
    local prev_line=""
    while IFS= read -r line || [[ -n "$line" ]]; do
      # Skip empty lines and comment-only lines
      [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && { prev_line="$line"; continue; }
      # Entry is valid only if the previous non-empty line was a comment (justification)
      if [[ "$prev_line" =~ ^[[:space:]]*# ]]; then
        allowed+=("$line")
      fi
      prev_line="$line"
    done < "$IGNORE_FILE"
  fi
  printf '%s\n' "${allowed[@]}"
}

is_allowlisted() {
  local file="$1"
  while IFS= read -r pattern; do
    # Simple glob match using bash
    # shellcheck disable=SC2053
    if [[ "$file" == $pattern ]]; then
      return 0
    fi
  done < <(build_allowlist)
  return 1
}

FINDINGS=0
CHECKED_FILES=0

# Analyse staged diff
while IFS= read -r line; do
  # Track current file from diff headers
  if [[ "$line" =~ ^\+\+\+[[:space:]]b/(.+)$ ]]; then
    CURRENT_FILE="${BASH_REMATCH[1]}"
    CURRENT_LINE=0
    continue
  fi

  # Track line numbers from hunk headers: @@ -a,b +c,d @@
  if [[ "$line" =~ ^@@[[:space:]].*\+([0-9]+) ]]; then
    CURRENT_LINE="${BASH_REMATCH[1]}"
    (( CURRENT_LINE-- )) || true
    continue
  fi

  # Count lines in context and removed lines (not added)
  if [[ "$line" =~ ^[\ -] ]]; then
    [[ "$line" =~ ^[\ ] ]] && (( CURRENT_LINE++ )) || true
    continue
  fi

  # Process added lines only
  if [[ "$line" =~ ^\+ ]]; then
    (( CURRENT_LINE++ )) || true
    CONTENT="${line:1}"  # Strip leading '+'

    # Skip inline-suppressed lines
    if [[ "$CONTENT" =~ "#"[[:space:]]*noqa:[[:space:]]*secret ]]; then
      continue
    fi

    # Skip allowlisted files
    if [[ -n "${CURRENT_FILE:-}" ]] && is_allowlisted "$CURRENT_FILE"; then
      continue
    fi

    # Apply each pattern
    for PATTERN_NAME in "${!PATTERNS[@]}"; do
      REGEX="${PATTERNS[$PATTERN_NAME]}"
      if echo "$CONTENT" | grep -qP "$REGEX" 2>/dev/null; then
        MATCH=$(echo "$CONTENT" | grep -oP "$REGEX" | head -1)
        REDACTED="${MATCH:0:4}****"
        echo ""
        echo "  SECRET DETECTED"
        echo "  File:     ${CURRENT_FILE:-unknown}"
        echo "  Line:     $CURRENT_LINE"
        echo "  Pattern:  $PATTERN_NAME"
        echo "  Match:    $REDACTED"
        echo "  Action:   BLOCKED — remove secret, use environment variable or secrets manager"
        (( FINDINGS++ )) || true
      fi
    done

    (( CHECKED_FILES++ )) || true
  fi
done < <(git diff --cached --unified=0)

echo ""
if (( FINDINGS > 0 )); then
  echo "SECRET DETECTION: BLOCKED — $FINDINGS secret(s) found in staged changes."
  echo "Resolve the above findings before committing."
  echo "To suppress a known false positive, add an entry to .code-quality-ignore"
  echo "with a justification comment on the preceding line."
  exit 1
else
  echo "Secret detection: PASSED (0 findings in staged changes)"
  exit 0
fi
