---
name: gitnexus-refactoring
description: "Use when the user wants to rename, extract, split, move, or restructure code safely. Examples: \"Rename this function\", \"Extract this into a module\", \"Refactor this class\", \"Move this to a separate file\""
---

# Refactoring with GitNexus

## When to Use

- "Rename this function safely"
- "Extract this into a module"
- "Split this service"
- "Move this to a new file"
- Any task involving renaming, extracting, splitting, or restructuring code

## Workflow

```
0. npx gitnexus status  → VERIFY FRESHNESS FIRST. Compare "Indexed commit" to `git rev-parse HEAD`.
                          Not equal (or "Repository not indexed.") → npx gitnexus analyze. Do not skip.
1. gitnexus_impact({target: "X", direction: "upstream"})  → Map all dependents
2. gitnexus_query({query: "X"})                            → Find execution flows involving X
3. gitnexus_context({name: "X"})                           → See all incoming/outgoing refs
4. Plan update order: interfaces → implementations → callers → tests
```

## Step 0 — Verify the index is fresh (mandatory)

**Nothing tells you the index is stale** — the graph does not self-maintain, and no hook re-indexes it after a commit or merge. Check it yourself before any rename or move:

```bash
npx gitnexus status        # "Indexed commit" must equal `git rev-parse HEAD`
git rev-parse HEAD
```

Refactoring on a stale index is the worst case: `gitnexus_impact` misses dependents added since the last `analyze`, so a rename that reports a clean blast radius silently breaks callers the graph has never seen. `gitnexus_rename` then edits from that same outdated map. Two tools fail differently here:

- `gitnexus_impact` on an unindexed symbol returns `{"error": "Target not found", "impactedCount": 0, "risk": "UNKNOWN"}` — an explicit error, not a false green. Treat `UNKNOWN` as "re-index," never as "safe to rename."
- `gitnexus_detect_changes` returns the literal **`"No changes detected."`** on a stale index even with hundreds of changed files — it never checks staleness. It means "I have no idea," not "only expected files changed."

> **Trap for automation:** `npx gitnexus status` **exits 0 in every case** — stale index and "Repository not indexed." alike. A `gitnexus status || block` gate never fires. Parse stdout; do not branch on the exit code.

## Checklists

### Rename Symbol

```
- [ ] npx gitnexus status FIRST — "Indexed commit" == HEAD, else analyze (a stale graph hides callers)
- [ ] gitnexus_rename({symbol_name: "oldName", new_name: "newName", dry_run: true}) — preview all edits
- [ ] Review graph edits (high confidence) and ast_search edits (review carefully)
- [ ] If satisfied: gitnexus_rename({..., dry_run: false}) — apply edits
- [ ] gitnexus_detect_changes() — verify only expected files changed ("No changes detected." on a non-empty diff = stale index, not an all-clear)
- [ ] Run tests for affected processes
```

### Extract Module

```
- [ ] npx gitnexus status FIRST — "Indexed commit" == HEAD, else analyze (a stale graph hides callers)
- [ ] gitnexus_context({name: target}) — see all incoming/outgoing refs
- [ ] gitnexus_impact({target, direction: "upstream"}) — find all external callers
- [ ] Define new module interface
- [ ] Extract code, update imports
- [ ] gitnexus_detect_changes() — verify affected scope (only trustworthy on a fresh index)
- [ ] Run tests for affected processes
```

### Split Function/Service

```
- [ ] npx gitnexus status FIRST — "Indexed commit" == HEAD, else analyze (a stale graph hides callers)
- [ ] gitnexus_context({name: target}) — understand all callees
- [ ] Group callees by responsibility
- [ ] gitnexus_impact({target, direction: "upstream"}) — map callers to update
- [ ] Create new functions/services
- [ ] Update callers
- [ ] gitnexus_detect_changes() — verify affected scope (only trustworthy on a fresh index)
- [ ] Run tests for affected processes
```

## Tools

**gitnexus_rename** — automated multi-file rename:

```
gitnexus_rename({symbol_name: "validateUser", new_name: "authenticateUser", dry_run: true})
→ 12 edits across 8 files
→ 10 graph edits (high confidence), 2 ast_search edits (review)
→ Changes: [{file_path, edits: [{line, old_text, new_text, confidence}]}]
```

**gitnexus_impact** — map all dependents first:

```
gitnexus_impact({target: "validateUser", direction: "upstream"})
→ d=1: loginHandler, apiMiddleware, testUtils
→ Affected Processes: LoginFlow, TokenRefresh
```

**gitnexus_detect_changes** — verify your changes after refactoring:

```
gitnexus_detect_changes({scope: "all"})
→ Changed: 8 files, 12 symbols
→ Affected processes: LoginFlow, TokenRefresh
→ Risk: MEDIUM
```

**gitnexus_cypher** — custom reference queries:

```cypher
MATCH (caller)-[:CodeRelation {type: 'CALLS'}]->(f:Function {name: "validateUser"})
RETURN caller.name, caller.filePath ORDER BY caller.filePath
```

## Risk Rules

| Risk Factor         | Mitigation                                |
| ------------------- | ----------------------------------------- |
| Many callers (>5)   | Use gitnexus_rename for automated updates |
| Cross-area refs     | Use detect_changes after to verify scope  |
| String/dynamic refs | gitnexus_query to find them               |
| External/public API | Version and deprecate properly            |

## Example: Rename `validateUser` to `authenticateUser`

```
1. gitnexus_rename({symbol_name: "validateUser", new_name: "authenticateUser", dry_run: true})
   → 12 edits: 10 graph (safe), 2 ast_search (review)
   → Files: validator.ts, login.ts, middleware.ts, config.json...

2. Review ast_search edits (config.json: dynamic reference!)

3. gitnexus_rename({symbol_name: "validateUser", new_name: "authenticateUser", dry_run: false})
   → Applied 12 edits across 8 files

4. gitnexus_detect_changes({scope: "all"})
   → Affected: LoginFlow, TokenRefresh
   → Risk: MEDIUM — run tests for these flows
```
