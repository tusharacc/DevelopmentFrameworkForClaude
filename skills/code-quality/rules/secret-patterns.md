# Secret Detection Patterns

This file defines regex patterns and entropy thresholds used by the secret-detection agent.
Each pattern is applied to every line of the target diff/file set.

---

## Entropy Threshold

Strings of 20+ characters with Shannon entropy ≥ 4.5 bits/char that appear on a line
where the variable name matches a sensitive name pattern are flagged as GENERIC_HIGH_ENTROPY.

**Sensitive variable name patterns (case-insensitive):**
`password`, `passwd`, `pwd`, `secret`, `token`, `api_key`, `apikey`, `auth`, `credential`,
`private_key`, `access_key`, `client_secret`, `signing_key`, `encryption_key`, `jwt_secret`

---

## Pattern Table

| Pattern Name | Regex | Notes |
|---|---|---|
| AWS_ACCESS_KEY_ID | `AKIA[0-9A-Z]{16}` | AWS access key |
| AWS_SECRET_ACCESS_KEY | `[0-9a-zA-Z/+]{40}` near `aws_secret` | Entropy + context |
| GCP_SERVICE_ACCOUNT_KEY | `"private_key":\s*"-----BEGIN` | GCP JSON key file |
| AZURE_CLIENT_SECRET | `[0-9a-zA-Z~_\-\.]{34,40}` near `client_secret` | Azure app secret |
| PRIVATE_KEY_PEM | `-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----` | Any PEM private key |
| BEARER_TOKEN | `[Bb]earer\s+[A-Za-z0-9\-_\.]{20,}` | HTTP Authorization header value |
| JWT_TOKEN | `eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}` | JWT (three base64url segments) |
| GITHUB_PAT | `gh[pousr]_[A-Za-z0-9]{36,}` | GitHub personal/oauth/user/server/refresh token |
| GITLAB_PAT | `glpat-[A-Za-z0-9\-_]{20,}` | GitLab personal access token |
| SLACK_TOKEN | `xox[baprs]-[0-9A-Za-z\-]{10,}` | Slack bot/app/user token |
| STRIPE_KEY | `sk_(live|test)_[A-Za-z0-9]{24,}` | Stripe secret key |
| TWILIO_KEY | `SK[a-z0-9]{32}` | Twilio API key |
| SENDGRID_KEY | `SG\.[A-Za-z0-9\-_]{22}\.[A-Za-z0-9\-_]{43}` | SendGrid API key |
| DB_CONN_WITH_CREDS | `(postgres|mysql|mongodb|redis):\/\/[^:]+:[^@]+@` | DB connection string with embedded password |
| HARDCODED_PASSWORD | `(password|passwd|pwd)\s*[=:]\s*["'][^"']{8,}["']` | Assigned string literal ≥ 8 chars |
| GENERIC_HIGH_ENTROPY | Entropy ≥ 4.5 on 20+ char string near sensitive var name | Catches novel key formats |

---

## File Scope

Patterns are applied to all of the following file extensions:
`.py`, `.js`, `.ts`, `.tsx`, `.jsx`, `.sh`, `.bash`,
`.env`, `.env.*`, `.yaml`, `.yml`, `.json`, `.toml`, `.ini`, `.cfg`, `.conf`,
`.pem`, `.key`, `.p12`, `.pfx`

**Always skipped (regardless of extension):**
- `node_modules/`
- `.git/`
- `*.min.js`
- `dist/`, `build/`, `.next/`
- Files matching patterns in `.code-quality-ignore`

---

## Allowlist Format (`.code-quality-ignore`)

Place this file at the repository root. Supported entries:

```
# Justification: dummy credentials used only in unit test fixtures
tests/fixtures/sample_config.json

# Justification: example .env file for documentation, no real secrets
docs/example.env

# Glob pattern
tests/**/*.fixture.json
```

Inline suppression on a source line:
```python
EXAMPLE_KEY = "AKIAIOSFODNN7EXAMPLE"  # noqa: secret — documented example key
```

Every allowlist entry MUST have a justification comment on the preceding line.
Entries without justification comments are treated as invalid and ignored (the pattern still fires).

---

## Output Format

Each finding is reported as:

```
SECRET DETECTED
  File:     path/to/file.py
  Line:     42
  Pattern:  AWS_ACCESS_KEY_ID
  Match:    AKIA*************  (redacted)
  Entropy:  4.8 bits/char
  Action:   BLOCKED — remove secret, use environment variable or secrets manager
```
