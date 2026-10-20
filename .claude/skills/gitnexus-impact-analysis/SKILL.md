---
name: gitnexus-impact-analysis
description: "Use when the user wants to know what will break if they change something, or needs safety analysis before editing code. Examples: \"Is it safe to change X?\", \"What depends on this?\", \"What will break?\""
---

# Impact Analysis with GitNexus

## When to Use

- "Is it safe to change this function?"
- "What will break if I modify X?"
- "Show me the blast radius"
- "Who uses this code?"
- Before making non-trivial code changes
- Before committing — to understand what your changes affect

## Workflow

```
0. npx gitnexus status  → VERIFY FRESHNESS FIRST. Compare "Indexed commit" to `git rev-parse HEAD`.
                          Not equal (or "Repository not indexed.") → npx gitnexus analyze. Do not skip.
1. gitnexus_impact({target: "X", direction: "upstream"})  → What depends on this
2. READ gitnexus://repo/{name}/processes                   → Check affected execution flows
3. gitnexus_detect_changes()                               → Map current git changes to affected flows
4. Assess risk and report to user
```

> **Linked git worktree?** `Repository not indexed.` there means the index lives in the main checkout — do **not** run `analyze` in the worktree. Read `skill:gitnexus-guide` § Worktrees first.

## Step 0 — Verify the index is fresh (mandatory)

**A stale index makes this skill's output worthless.** The graph does not self-maintain — no hook re-indexes it after a commit or merge. It reflects the codebase as of the last manual `analyze`, which may be months old.

Never wait to be told the index is stale — **nothing tells you.** Check it yourself:

```bash
npx gitnexus status        # "Indexed commit" must equal `git rev-parse HEAD`
git rev-parse HEAD
```

Know exactly how each tool fails on a stale index — they are not equally honest:

| Tool | On a stale index | Deceptive? |
| --- | --- | --- |
| `gitnexus_detect_changes` | Returns the literal **`"No changes detected."`** even with hundreds of changed files — it never checks staleness. | **YES.** Reads as an all-clear; it is not one. It means "I have no idea," not "you are safe." |
| `gitnexus_impact` | For a symbol it **never indexed**: `{"error": "Target '<x>' not found", "impactedCount": 0, "risk": "UNKNOWN"}`. For an **indexed** symbol it can answer `impactedCount: 0 · risk: "LOW" · epistemic: "exact"` while a live caller sits in the very same index. | **Half.** `UNKNOWN` is honest — treat it as "re-index," never as "low risk." `0 / LOW / exact` is **not**: it is a false green, and staleness does not explain it — the edge was already in the indexed state, so re-indexing is not the remedy (not re-measured after an `analyze`). |

> **Trap for automation:** `npx gitnexus status` **exits 0 in every case** — for a stale index and for "Repository not indexed." alike. A `gitnexus status || block` gate never fires. Parse stdout; do not branch on the exit code.

> **`impactedCount: 0` is a claim, not a verdict — and staleness does not explain this one.** Measured on this repo 2026-09-17, re-measured 2026-09-22, against the index stamped `829606e` — 72 commits behind `HEAD`, so stale, but the production call `settings = mergeClaudeSettings(…)` already stood in `src/targets/claude.ts` at `829606e`: `impact({target: "mergeClaudeSettings", direction: "upstream"})` answered `impactedCount: 0 · risk: LOW · epistemic: "exact"` (with `includeTests: true` only the test file appears), while `impact({target_uid: "Function:src/targets/claude.ts:syncClaude", direction: "downstream"})` lists exactly that edge, out of the **same** index, as `CALLS` at confidence 0.85 (by name alone it answers `ambiguous`). The upstream traversal loses an edge the downstream traversal finds, and labels the result `exact`. So `epistemic` describes the traversal's own confidence, never the graph's coverage. A zero blast radius owes a second, non-graph confirmation before it becomes "safe to change": grep the symbol name across the repo and report `file:line` as **substitute evidence**, never as "gate green" (`30-quality`, gate evidence). Three failure modes, three different remedies — **no index** (a linked worktree, see the pointer above), **stale index** (`analyze`), and **this one**, which neither of those reaches: the edge sits in the indexed snapshot, so an `analyze` is not its cure (not re-measured after one).

## Checklist

```
- [ ] npx gitnexus status FIRST — "Indexed commit" == HEAD, else analyze (a stale graph invalidates everything below)
- [ ] gitnexus_impact({target, direction: "upstream"}) to find dependents
- [ ] Review d=1 items first (these WILL BREAK)
- [ ] Check high-confidence (>0.8) dependencies
- [ ] READ processes to check affected execution flows
- [ ] gitnexus_detect_changes() for pre-commit check — "No changes detected." is only trustworthy on a fresh index
- [ ] Assess risk level and report to user
```

## Understanding Output

| Depth | Risk Level       | Meaning                  |
| ----- | ---------------- | ------------------------ |
| d=1   | **WILL BREAK**   | Direct callers/importers |
| d=2   | LIKELY AFFECTED  | Indirect dependencies    |
| d=3   | MAY NEED TESTING | Transitive effects       |

## Risk Assessment

| Affected                       | Risk     |
| ------------------------------ | -------- |
| <5 symbols, few processes      | LOW      |
| 5-15 symbols, 2-5 processes    | MEDIUM   |
| >15 symbols or many processes  | HIGH     |
| Critical path (auth, payments) | CRITICAL |

## Tools

**gitnexus_impact** — the primary tool for symbol blast radius:

```
gitnexus_impact({
  target: "validateUser",
  direction: "upstream",
  minConfidence: 0.8,
  maxDepth: 3
})

→ d=1 (WILL BREAK):
  - loginHandler (src/auth/login.ts:42) [CALLS, 100%]
  - apiMiddleware (src/api/middleware.ts:15) [CALLS, 100%]

→ d=2 (LIKELY AFFECTED):
  - authRouter (src/routes/auth.ts:22) [CALLS, 95%]
```

**gitnexus_detect_changes** — git-diff based impact analysis:

```
gitnexus_detect_changes({scope: "staged"})

→ Changed: 5 symbols in 3 files
→ Affected: LoginFlow, TokenRefresh, APIMiddlewarePipeline
→ Risk: MEDIUM
```

## Example: "What breaks if I change validateUser?"

```
1. gitnexus_impact({target: "validateUser", direction: "upstream"})
   → d=1: loginHandler, apiMiddleware (WILL BREAK)
   → d=2: authRouter, sessionManager (LIKELY AFFECTED)

2. READ gitnexus://repo/my-app/processes
   → LoginFlow and TokenRefresh touch validateUser

3. Risk: 2 direct callers, 2 processes = MEDIUM
```
