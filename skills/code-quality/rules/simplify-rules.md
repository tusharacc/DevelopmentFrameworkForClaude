# Simplify Agent Rules

This file defines the four simplification checks performed by the simplify agent.
Rules are applied via LLM analysis against the branch diff.

Each rule has:
- **ID** — unique identifier
- **Name** — short label
- **Description** — what to detect
- **Detection heuristic** — concrete patterns to look for
- **Python example** — before/after in Python
- **JS/TS example** — before/after in JS/TS
- **Rejection criteria** — when NOT to suggest this transformation
- **Python typing constraint** — the proposed replacement must preserve or improve type annotations

---

## SIM-01 — Duplicate Logic

**Description:** Two or more functions, methods, or code blocks that perform semantically equivalent operations with only superficial differences (variable names, minor branching).

**Detection heuristic:**
- Blocks of 5+ lines that share the same algorithmic structure across different functions or modules
- Functions that differ only in which field/property they access
- Copy-pasted error handling, validation, or transformation logic

**Python example:**
```python
# BEFORE (duplicate)
def validate_username(username: str) -> bool:
    if not username:
        return False
    if len(username) < 3:
        return False
    return True

def validate_email(email: str) -> bool:
    if not email:
        return False
    if len(email) < 3:
        return False
    return True

# AFTER (consolidated)
def _validate_non_empty_min_length(value: str, min_len: int = 3) -> bool:
    return bool(value) and len(value) >= min_len

def validate_username(username: str) -> bool:
    return _validate_non_empty_min_length(username)

def validate_email(email: str) -> bool:
    return _validate_non_empty_min_length(email)
```

**JS/TS example:**
```typescript
// BEFORE (duplicate)
function validateUsername(username: string): boolean {
  if (!username) return false;
  if (username.length < 3) return false;
  return true;
}
function validateEmail(email: string): boolean {
  if (!email) return false;
  if (email.length < 3) return false;
  return true;
}

// AFTER
function validateNonEmptyMinLength(value: string, minLen = 3): boolean {
  return !!value && value.length >= minLen;
}
```

**Rejection criteria:**
- The blocks are similar in structure but semantically distinct (e.g., same shape but different business rules)
- Consolidation would require a callback/strategy parameter that makes the result harder to understand than the original duplication
- The extracted function would be called exactly once

---

## SIM-02 — Class/Method Consolidation

**Description:** A set of related free functions, module-level variables, or loosely coupled procedures that share state or operate on the same data structure, which would be more cohesive as a class with distinct methods.

**Detection heuristic:**
- Three or more functions that all take the same first argument (same data structure/dict/object)
- Module-level mutable state accessed by multiple functions in the same module
- Functions prefixed with the same noun (`user_get`, `user_update`, `user_delete`)
- Functions that pass a context/config dict around as the first parameter

**Python example:**
```python
# BEFORE (scattered free functions sharing state)
def connect_db(config: dict[str, str]) -> Connection: ...
def query_db(config: dict[str, str], sql: str) -> list[Row]: ...
def close_db(config: dict[str, str]) -> None: ...

# AFTER (cohesive class)
class DatabaseClient:
    def __init__(self, config: dict[str, str]) -> None:
        self._config = config
        self._conn: Connection | None = None

    def connect(self) -> None: ...
    def query(self, sql: str) -> list[Row]: ...
    def close(self) -> None: ...
```

**JS/TS example:**
```typescript
// BEFORE
function connectDb(config: DbConfig): Connection { ... }
function queryDb(config: DbConfig, sql: string): Row[] { ... }
function closeDb(config: DbConfig): void { ... }

// AFTER
class DatabaseClient {
  constructor(private config: DbConfig) {}
  connect(): Connection { ... }
  query(sql: string): Row[] { ... }
  close(): void { ... }
}
```

**Rejection criteria:**
- Fewer than three functions share the same concern
- The functions are already in separate modules with no shared state — forcing a class adds artificial coupling
- The class would have no state (all methods would be static) — use a module/namespace instead

---

## SIM-03 — Interface / Abstract Class Opportunity

**Description:** Two or more classes or objects implement the same duck-typed contract (same method names, same argument shapes) without a formal interface or abstract base class defining that contract.

**Detection heuristic:**
- Multiple classes with identically named methods (same name, compatible signatures) used interchangeably via duck typing
- Type hints using `Union[ClassA, ClassB]` where both classes share a common method set
- Functions that check `hasattr(obj, 'method_name')` or `isinstance(obj, (ClassA, ClassB))` to dispatch

**Python example:**
```python
# BEFORE (implicit duck typing)
class FileExporter:
    def export(self, data: list[dict]) -> None: ...

class CsvExporter:
    def export(self, data: list[dict]) -> None: ...

def run_export(exporter: FileExporter | CsvExporter, data: list[dict]) -> None:
    exporter.export(data)

# AFTER (explicit Protocol)
from typing import Protocol

class Exporter(Protocol):
    def export(self, data: list[dict[str, object]]) -> None: ...

def run_export(exporter: Exporter, data: list[dict[str, object]]) -> None:
    exporter.export(data)
```

**JS/TS example:**
```typescript
// BEFORE (implicit duck typing)
class FileExporter {
  export(data: Record<string, unknown>[]): void { ... }
}
class CsvExporter {
  export(data: Record<string, unknown>[]): void { ... }
}

// AFTER (explicit interface)
interface Exporter {
  export(data: Record<string, unknown>[]): void;
}
```

**Rejection criteria:**
- Only one concrete implementation exists or is planned — an interface adds no value with a single implementor
- The shared method names are coincidental (same name, different semantics)
- Adding the interface would require modifying third-party code

---

## SIM-04 — Loop to Functional

**Description:** An explicit `for` or `while` loop that transforms, filters, or reduces a collection, which can be replaced with an idiomatic functional construct that is shorter and more expressive.

**Detection heuristic:**
- `for` loop that appends to a new list → `map` / list comprehension
- `for` loop with an `if` that conditionally appends → `filter` / list comprehension with condition
- `for` loop that accumulates a single value → `reduce` / `sum` / `any` / `all`
- `for` loop that builds a dict → dict comprehension
- `while` loop iterating a counter over a sequence → replace with `enumerate` or `zip`

**Python example:**
```python
# BEFORE
result: list[int] = []
for x in numbers:
    if x > 0:
        result.append(x * 2)

# AFTER
result: list[int] = [x * 2 for x in numbers if x > 0]
```

```python
# BEFORE (accumulator)
total: int = 0
for item in items:
    total += item.price

# AFTER
total: int = sum(item.price for item in items)
```

**JS/TS example:**
```typescript
// BEFORE
const result: number[] = [];
for (const x of numbers) {
  if (x > 0) result.push(x * 2);
}

// AFTER
const result: number[] = numbers.filter(x => x > 0).map(x => x * 2);
```

**Rejection criteria:**
- The loop body has side effects beyond building the result (e.g., logging, mutating external state) — functional replacements should be pure
- The loop contains `break` or `continue` with complex conditions that would require a `reduce` with accumulated state — the functional version would be harder to read
- The resulting functional expression exceeds ~80 characters and would need to be split across multiple lines in a way that's less readable than the original loop
- The loop iterates fewer than 3 items over a literal — no benefit to transformation

---

## Output Format

Each finding is reported as:

```
SIMPLIFY FINDING
  ID:        SIM-01
  File:      path/to/module.py
  Lines:     14–28 and 31–45
  Issue:     Duplicate logic — validate_username and validate_email share identical structure
  Current:
    [current code snippet]
  Proposed:
    [proposed replacement with type annotations]
  Notes:     Extract _validate_non_empty_min_length; both callers pass through unchanged.
  Status:    ACTIONABLE  (or: ATTEMPTED — test regression detected)
```

Findings marked ACTIONABLE are implementation tasks for the developer.
Findings marked ATTEMPTED were proposed but caused a test regression when verified — included for transparency.
Findings marked ADVISORY have no test suite to verify against — developer must verify manually.
