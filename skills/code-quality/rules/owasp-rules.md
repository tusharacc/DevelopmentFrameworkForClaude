# OWASP & Secure Coding Rules

This file defines the rules used by the secure-coding agent in both checklist mode (developer phase)
and review mode (reviewer phase). Rules are applied via LLM analysis against the target code.

---

## Rule Structure

Each rule has:
- **ID** — unique identifier
- **Category** — OWASP category or custom secure coding category
- **Severity** — CRITICAL / HIGH / MEDIUM / LOW
- **Description** — what the rule detects
- **Detection heuristic** — what patterns to look for in code
- **Python specifics** — language-specific patterns
- **JS/TS specifics** — language-specific patterns
- **Recommended fix** — concrete remediation guidance

---

## Rules

---

### SC-01
**Category:** OWASP A03:2021 — Injection
**Severity:** CRITICAL
**Description:** SQL query constructed via string concatenation or interpolation with unsanitised input.
**Detection heuristic:** Look for SQL keyword strings (`SELECT`, `INSERT`, `UPDATE`, `DELETE`, `WHERE`) concatenated or f-string interpolated with variables that originate from function parameters, request objects, or external input.
**Python specifics:** Flag `cursor.execute(f"...")`, `cursor.execute("..." + var)`, `cursor.execute("..." % var)`. Safe patterns: `cursor.execute("...", (param,))` or ORM query builders.
**JS/TS specifics:** Flag template literals passed directly to `db.query()`, `connection.execute()`, `pool.query()` where the template contains variables. Safe pattern: parameterised `$1`/`?` placeholders with separate values array.
**Recommended fix:** Use parameterised queries / prepared statements. Pass user input as bind parameters, never in the query string itself.

---

### SC-02
**Category:** OWASP A03:2021 — Injection (Command Injection)
**Severity:** CRITICAL
**Description:** Shell command constructed with user-controlled input passed to `subprocess`, `os.system`, `exec`, `eval`, or similar.
**Detection heuristic:** Any call to `subprocess.run`, `subprocess.Popen`, `os.system`, `os.popen` where the command string is constructed from variables. Any `eval()` or `exec()` call where the argument is not a string literal.
**Python specifics:** Flag `subprocess.run(f"cmd {user_input}", shell=True)`. Safe pattern: `subprocess.run(["cmd", user_input], shell=False)`.
**JS/TS specifics:** Flag `child_process.exec(` + template literal with variables. Flag `eval(userInput)`. Safe pattern: `child_process.execFile` with args array.
**Recommended fix:** Never pass `shell=True` with interpolated input. Use argument arrays. Whitelist and validate any value that influences a command.

---

### SC-03
**Category:** OWASP A03:2021 — Injection (XSS)
**Severity:** HIGH
**Description:** User-controlled data assigned directly to `innerHTML`, `outerHTML`, `document.write`, or similar DOM sinks.
**Detection heuristic:** Assignment to `.innerHTML`, `.outerHTML`, `document.write(`, `insertAdjacentHTML(` where the right-hand side includes variables derived from URL params, form input, API responses, or `localStorage`.
**Python specifics:** Flag Jinja2/Django templates where `{{ var }}` is replaced with `{{ var | safe }}` without explicit sanitisation. Flag `Markup(user_input)` in Flask.
**JS/TS specifics:** Flag `element.innerHTML = userInput`, `element.innerHTML = \`...\${userInput}...\``. Safe pattern: `element.textContent = userInput` or DOMPurify sanitisation before innerHTML assignment.
**Recommended fix:** Use `textContent` for text. If HTML is required, sanitise with DOMPurify (JS) or `bleach` (Python) before assignment.

---

### SC-04
**Category:** OWASP A01:2021 — Broken Access Control
**Severity:** HIGH
**Description:** Route or function performs privileged action without authentication/authorisation check.
**Detection heuristic:** HTTP handler functions (Flask routes, Express handlers, FastAPI endpoints) that modify data, access user-specific resources, or perform admin operations without a guard decorator/middleware (`@login_required`, `authenticate`, `requireAuth`, JWT verification).
**Python specifics:** Flask/FastAPI routes with `POST`/`PUT`/`DELETE`/`PATCH` methods lacking `@login_required`, `Depends(get_current_user)`, or equivalent.
**JS/TS specifics:** Express routes with mutating methods lacking `authenticate`/`authorize` middleware in the chain. Next.js API routes without session checks.
**Recommended fix:** Apply authentication middleware globally and opt out explicitly for public routes. Never opt in per route — the default must be protected.

---

### SC-05
**Category:** OWASP A02:2021 — Cryptographic Failures
**Severity:** HIGH
**Description:** Weak or broken cryptographic algorithm used for sensitive data.
**Detection heuristic:** Use of `MD5`, `SHA1` for password hashing or data integrity. Use of `DES`, `RC4`, `ECB` mode for encryption. Hardcoded IV or salt.
**Python specifics:** Flag `hashlib.md5(password)`, `hashlib.sha1(password)`. Flag `Crypto.Cipher.DES`. Safe pattern: `bcrypt`, `argon2`, `hashlib.sha256` for non-password hashing.
**JS/TS specifics:** Flag `crypto.createHash('md5')` on passwords. Flag `crypto.createCipheriv('des-ecb', ...)`. Safe pattern: `bcrypt`, `argon2`, `crypto.createHash('sha256')` for non-passwords.
**Recommended fix:** Use `bcrypt` or `argon2` for passwords. Use `AES-256-GCM` for symmetric encryption with a random IV per operation.

---

### SC-06
**Category:** OWASP A05:2021 — Security Misconfiguration
**Severity:** HIGH
**Description:** Debug mode, verbose error output, or stack traces exposed in production code paths.
**Detection heuristic:** `DEBUG=True` in non-test config files. Exception handlers that return full stack traces in HTTP responses. `app.run(debug=True)` in application entry points.
**Python specifics:** Flag `app.run(debug=True)` in Flask outside of `if __name__ == "__main__"` dev guards. Flag `traceback.format_exc()` returned in HTTP response bodies.
**JS/TS specifics:** Flag `app.use((err, req, res, next) => res.json(err.stack))`. Flag `NODE_ENV !== 'production'` checks absent where `debug` is enabled.
**Recommended fix:** Use environment variables for debug flags. Return generic error messages to clients; log full details server-side only.

---

### SC-07
**Category:** OWASP A06:2021 — Vulnerable and Outdated Components
**Severity:** MEDIUM
**Description:** Dependency version pinned to `*`, `latest`, or a known-vulnerable version range.
**Detection heuristic:** `requirements.txt` or `package.json` entries with `*`, `latest`, unpinned `>=` ranges, or versions matching known CVE ranges (check against common vulnerable version patterns).
**Python specifics:** Flag `package>=1.0` without upper bound in `requirements.txt`. Flag `package==*`.
**JS/TS specifics:** Flag `"dependency": "*"` or `"dependency": "latest"` in `package.json`.
**Recommended fix:** Pin to exact versions in production dependencies. Use `pip-audit` or `npm audit` regularly. Use a lockfile (`poetry.lock`, `package-lock.json`).

---

### SC-08
**Category:** OWASP A04:2021 — Insecure Design (Input Validation)
**Severity:** HIGH
**Description:** User input used without validation or sanitisation at a system boundary.
**Detection heuristic:** Variables derived from `request.args`, `request.form`, `request.json`, `req.body`, `req.params`, `req.query` used directly in file operations, database queries, template rendering, or subprocess calls without explicit validation.
**Python specifics:** `request.args.get('filename')` passed to `open()` without path validation. `request.json` fields used in DB queries without schema validation (Pydantic/marshmallow).
**JS/TS specifics:** `req.body.filename` passed to `fs.readFile()` without sanitisation. `req.params.id` used in a DB query without type coercion to integer.
**Recommended fix:** Validate all inputs at the boundary using a schema library (Pydantic, Joi, Zod). Coerce types explicitly. Whitelist valid values where possible.

---

### SC-09
**Category:** Secure Coding — Deserialisation
**Severity:** CRITICAL
**Description:** Unsafe deserialisation of untrusted data.
**Detection heuristic:** `pickle.loads()`, `yaml.load()` (without `Loader=yaml.SafeLoader`), `marshal.loads()` called with data from network, file, or user input.
**Python specifics:** Flag `pickle.loads(request_data)`. Flag `yaml.load(data)` without explicit `Loader`. Safe pattern: `yaml.safe_load(data)`, `json.loads(data)`.
**JS/TS specifics:** Flag `node-serialize` or `serialize-javascript` deserialisation of untrusted input.
**Recommended fix:** Never deserialise untrusted data with `pickle` or `marshal`. Use `json` for data exchange. If YAML is required, always use `yaml.safe_load`.

---

### SC-10
**Category:** Secure Coding — Path Traversal
**Severity:** HIGH
**Description:** File path constructed from user input without canonicalisation and containment check.
**Detection heuristic:** `open(user_input)`, `os.path.join(base, user_input)` without verifying the resolved path starts with the intended base directory. `fs.readFile(req.params.file)` without path normalisation.
**Python specifics:** Flag `open(request.args.get('file'))`. Flag `os.path.join(BASE_DIR, user_file)` without `os.path.realpath` + prefix check.
**JS/TS specifics:** Flag `fs.readFile(path.join(baseDir, req.params.file))` without `path.resolve` + `startsWith(baseDir)` check.
**Recommended fix:**
```python
# Python
safe_path = os.path.realpath(os.path.join(BASE_DIR, user_input))
if not safe_path.startswith(BASE_DIR):
    raise ValueError("Path traversal detected")
```

---

### SC-11
**Category:** Secure Coding — Strict Typing (Python)
**Severity:** MEDIUM
**Description:** Python function or method missing type annotations on parameters or return value.
**Detection heuristic:** Any `def` statement where one or more parameters lack type annotations, or the return type is missing (and the function is not `__init__`).
**Python specifics:** Flag `def process(data):` — missing param type. Flag `def get_user(id):` — missing param and return type. Safe pattern: `def process(data: str) -> dict[str, Any]:`.
**JS/TS specifics:** Not applicable (TypeScript enforces this via `tsc --strict`).
**Recommended fix:** Add type annotations to all function signatures. Use `mypy --strict` in CI.

---

### SC-12
**Category:** Secure Coding — Strict Typing (TypeScript `any`)
**Severity:** MEDIUM
**Description:** TypeScript `any` type used at a security-sensitive boundary (DB input, HTTP response, file write, auth check).
**Detection heuristic:** Variable typed as `any` that flows into: a DB query call, `res.json()`/`res.send()`, `fs.writeFile()`, or a conditional that gates access control.
**Python specifics:** Not applicable.
**JS/TS specifics:** Flag `const data: any = req.body; db.query(data.id)`. Safe pattern: define an explicit interface for request body and validate with Zod/Joi before use.
**Recommended fix:** Replace `any` with a specific interface. Validate at the boundary with a runtime schema validator.

---

## Checklist Mode Output (Developer Phase)

When invoked in checklist mode, the secure-coding agent produces a structured prompt like:

```
SECURE CODING CHECKLIST — [detected stack: Python / TypeScript / both]

Before writing code, verify your implementation will satisfy:

[ ] SC-01  No raw SQL string construction — use parameterised queries
[ ] SC-02  No shell commands constructed from user input
[ ] SC-03  No innerHTML/outerHTML assignment from user data  (TS only)
[ ] SC-04  All mutating routes protected by auth middleware
[ ] SC-05  No MD5/SHA1 for password hashing
[ ] SC-06  Debug mode disabled in non-dev config paths
[ ] SC-07  All dependencies pinned to exact versions
[ ] SC-08  All user inputs validated at system boundaries
[ ] SC-09  No pickle/unsafe yaml.load on untrusted data  (Python only)
[ ] SC-10  No user-controlled file paths without containment check
[ ] SC-11  All Python functions fully type-annotated  (Python only)
[ ] SC-12  No `any` type at security-sensitive boundaries  (TS only)

This checklist is advisory. The secure-coding reviewer agent will hard-check all
items above and block hand-off on CRITICAL/HIGH/MEDIUM violations.
```
