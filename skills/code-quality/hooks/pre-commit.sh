#!/usr/bin/env bash
# Secret detection pre-commit hook
# Installed by the code-quality skill. Prepended to any existing hook content.
# To suppress a known false positive, add an entry to .code-quality-ignore
# with a justification comment on the preceding line.
# Note: git commit --no-verify bypasses this hook. Complement with CI enforcement.
# Compatible with Bash 3.2+ (macOS default) and GNU/BSD grep.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
IGNORE_FILE="$REPO_ROOT/.code-quality-ignore"

# Parallel indexed arrays — compatible with Bash 3.2+ (no associative arrays)
PATTERN_NAMES=(
  AWS_ACCESS_KEY_ID
  PRIVATE_KEY_PEM
  BEARER_TOKEN
  JWT_TOKEN
  GITHUB_PAT
  GITLAB_PAT
  SLACK_TOKEN
  STRIPE_KEY
  DB_CONN_WITH_CREDS
  HARDCODED_PASSWORD
)
PATTERN_REGEXES=(
  "AKIA[0-9A-Z]{16}"
  "-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"
  "[Bb]earer[[:space:]]+[A-Za-z0-9_.\\-]{20,}"
  "eyJ[A-Za-z0-9_\\-]{10,}\\.[A-Za-z0-9_\\-]{10,}\\.[A-Za-z0-9_\\-]{10,}"
  "gh[pousr]_[A-Za-z0-9]{36,}"
  "glpat-[A-Za-z0-9_\\-]{20,}"
  "xox[baprs]-[0-9A-Za-z\\-]{10,}"
  "sk_(live|test)_[A-Za-z0-9]{24,}"
  "(postgres|mysql|mongodb|redis)://[^:]+:[^@]+@"
  "(password|passwd|pwd)[[:space:]]*[=:][[:space:]]*[\"'][^\"']{8,}[\"']"
)

# Build allowlist once — cache in indexed array to avoid repeated file reads
ALLOWLIST=()
if [[ -f "$IGNORE_FILE" ]]; then
  prev_line=""
  while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    [[ -z "$raw_line" || "$raw_line" =~ ^[[:space:]]*# ]] && { prev_line="$raw_line"; continue; }
    if [[ "$prev_line" =~ ^[[:space:]]*# ]]; then
      ALLOWLIST+=("$raw_line")
    fi
    prev_line="$raw_line"
  done < "$IGNORE_FILE"
fi

is_allowlisted() {
  local file="$1"
  local pattern
  for pattern in "${ALLOWLIST[@]+"${ALLOWLIST[@]}"}"; do
    # shellcheck disable=SC2053
    if [[ "$file" == $pattern ]]; then
      return 0
    fi
  done
  return 1
}

FINDINGS=0
CURRENT_FILE=""
CURRENT_LINE=0

# Analyse staged diff — uses grep -E (POSIX ERE, portable across GNU and BSD grep)
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

  # Context lines advance the counter; removed lines do not
  if [[ "$line" =~ ^[[:space:]] ]]; then
    (( CURRENT_LINE++ )) || true
    continue
  fi
  [[ "$line" =~ ^- ]] && continue

  # Process added lines only
  if [[ "$line" =~ ^\+ ]]; then
    (( CURRENT_LINE++ )) || true
    CONTENT="${line:1}"  # Strip leading '+'

    # Skip inline-suppressed lines
    if [[ "$CONTENT" =~ "#"[[:space:]]*noqa:[[:space:]]*secret ]]; then
      continue
    fi

    # Skip allowlisted files
    if [[ -n "$CURRENT_FILE" ]] && is_allowlisted "$CURRENT_FILE"; then
      continue
    fi

    # Apply each pattern using grep -E (portable: works on both GNU and BSD grep)
    local_idx=0
    while [[ $local_idx -lt ${#PATTERN_NAMES[@]} ]]; do
      PATTERN_NAME="${PATTERN_NAMES[$local_idx]}"
      REGEX="${PATTERN_REGEXES[$local_idx]}"
      if echo "$CONTENT" | grep -qE "$REGEX" 2>/dev/null; then
        MATCH=$(echo "$CONTENT" | grep -oE "$REGEX" | head -1)
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
      (( local_idx++ )) || true
    done
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
