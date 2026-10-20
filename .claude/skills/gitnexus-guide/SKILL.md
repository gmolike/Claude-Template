---
name: gitnexus-guide
description: "Use when the user asks about GitNexus itself — available tools, how to query the knowledge graph, MCP resources, graph schema, or workflow reference. Examples: \"What GitNexus tools are available?\", \"How do I use GitNexus?\""
---

# GitNexus Guide

Quick reference for all GitNexus MCP tools, resources, and the knowledge graph schema.

## Always Start Here

For any task involving code understanding, debugging, impact analysis, or refactoring:

1. **Run `npx gitnexus status`** — "Indexed commit" must equal `git rev-parse HEAD`; if it differs (or it says "Repository not indexed."), run `npx gitnexus analyze` before anything else — **in a linked git worktree that last reflex is wrong; read § Worktrees first**
2. **Read `gitnexus://repo/{name}/context`** — codebase overview
3. **Match your task to a skill below** and **read that skill file**
4. **Follow the skill's workflow and checklist**

> **Freshness is your job, not the tool's.** The graph does not self-maintain — no hook re-indexes it after a commit or merge. `gitnexus://repos` and `.../context` do emit `⚠️ Index is N commits behind HEAD` when they can measure drift, but that check fails open (an indexed commit rebased away or garbage-collected reads as *fresh*) and never sees uncommitted changes — so absence of a warning is not an all-clear. **Trap for automation:** `npx gitnexus status` **exits 0 in every case**, even for "Repository not indexed.", so a `status || block` gate never fires. Parse stdout; do not branch on the exit code.

## Worktrees

**The index does not come with `git worktree add`.** `.gitnexus/` is untracked, so a linked worktree never inherits one: measured on this repo, 6 of 6 linked worktrees have no `.gitnexus/`, and `npx gitnexus status` prints `Repository not indexed.` there at **exit 0**. In a worktree that sentence does not mean "this code is unindexed" — it means **"the index lives in the main checkout"**. Detect the situation before step 1 above:

```bash
[ "$(git rev-parse --git-dir)" != "$(git rev-parse --git-common-dir)" ] && echo "linked worktree"
```

Then pick a lane, in this order:

1. **Diff tools — pass the worktree.** `detect_changes({repo, worktree: "<absolute worktree path>"})` runs `git diff` inside that worktree; staged and unstaged hunks both arrive (measured on gitnexus 1.6.9). Auto-detection already covers the case where the MCP server itself was launched inside the worktree — pass `worktree` when it was not.
2. **Graph tools — pin a branch slot.** `impact`, `context` and `query` have **no** `worktree` parameter; they answer from the workspace index, i.e. the main checkout's last `analyze`. For a graph of your branch run `npx gitnexus analyze --branch <name>` **in the main checkout**, then pass `branch: "<name>"` to those tools. `npx gitnexus clean --branch <name>` drops that slot again.
3. **No usable index — declare substitute evidence.** Report source evidence (`grep`, `file:line`) explicitly as a **substitute** for the graph gate, never as "gate green" (`30-quality`, gate evidence). For a change with real rebuild risk — renames, signature changes, moving a shared contract — opt in to fail-closed instead: hold the change and owe an adversarial second review, disclosed in the PR body.

**The `worktree` parameter moves the diff cwd, not the graph.** Changed symbols are still resolved against the main checkout's last `analyze`. Measured here from a worktree 23 commits ahead of the index: one file, two changed functions, answer `changed_files: 1 · changed_count: 1` — the second function was dropped without a word. A quiet `detect_changes` out of a worktree is a floor, not a proof.

**`Indexed commit` is a label, not a hash of what was indexed.** `analyze` reads the working tree and stamps it with whatever `HEAD` happened to be, uncommitted work included. Measured: `.gitnexus/meta.json` names `829606e`, `git show 829606e:src/generate.ts` contains no `lineCount`, and the index resolves `Function:src/generate.ts:lineCount` regardless. Comparing that field to `git rev-parse HEAD` can prove staleness; it can never prove freshness.

**Never `analyze` from inside a linked worktree.** Unless you pass `--index-only` it injects into that tree's `AGENTS.md` / `CLAUDE.md` and installs `.claude/skills/gitnexus/` (`--skip-agents-md` / `--skip-skills` per `analyze --help`); and the registry names a repo after its remote URL — which a worktree shares with its main checkout, which is why `--name <alias>` / `--allow-duplicate-name` exist. Index from the main checkout, or use `--branch`.

**A present index is not a complete answer either — and this failure is not a staleness artefact.** Measured here 2026-09-17, re-measured 2026-09-22, against the workspace index stamped `829606e` (72 commits behind `HEAD`): `impact({target: "mergeClaudeSettings", direction: "upstream"})` returned `impactedCount: 0 · risk: LOW · epistemic: "exact"`, although the production call already stood in `src/targets/claude.ts` at `829606e`; the reverse direction (`impact({target_uid: "Function:src/targets/claude.ts:syncClaude", direction: "downstream"})` — by name alone it answers `ambiguous`) lists that very edge out of the **same** index as `CALLS` at confidence 0.85. So the three graph failure modes need three different remedies: **no index** (steps 1-3 above), **stale index** (`analyze`), and **a traversal that drops an edge and calls itself `exact`** — which staleness does not explain, so `analyze` is not its remedy (not re-measured after one); the only remedy is a source grep reported as substitute evidence. A blast radius of zero is a lead, never a clearance (`skill:gitnexus-impact-analysis`).

**Named blind spot:** nothing checks whether a session judged its own rebuild risk correctly. The choice in step 3 between substitute evidence and fail-closed is the session's own, and it is unaudited.

**A GitNexus skill without this section is not this one.** `analyze` installs its own copy under `.claude/skills/gitnexus/**` — untracked, gitignored, rewritten on every run.

## Skills

| Task                                         | Skill to read       |
| -------------------------------------------- | ------------------- |
| Understand architecture / "How does X work?" | `gitnexus-exploring`         |
| Blast radius / "What breaks if I change X?"  | `gitnexus-impact-analysis`   |
| Trace bugs / "Why is X failing?"             | `gitnexus-debugging`         |
| Rename / extract / split / refactor          | `gitnexus-refactoring`       |
| Tools, resources, schema reference           | `gitnexus-guide` (this file) |
| Index, status, clean, wiki CLI commands      | `gitnexus-cli`               |

## Tools Reference

| Tool             | What it gives you                                                        |
| ---------------- | ------------------------------------------------------------------------ |
| `query`          | Process-grouped code intelligence — execution flows related to a concept |
| `context`        | 360-degree symbol view — categorized refs, processes it participates in  |
| `impact`         | Symbol blast radius — what breaks at depth 1/2/3 with confidence         |
| `detect_changes` | Git-diff impact — what do your current changes affect. On a stale index returns `"No changes detected."` regardless: "I have no idea," not an all-clear |
| `rename`         | Multi-file coordinated rename with confidence-tagged edits               |
| `cypher`         | Raw graph queries (read `gitnexus://repo/{name}/schema` first)           |
| `list_repos`     | Discover indexed repos                                                   |

## Resources Reference

Lightweight reads (~100-500 tokens) for navigation:

| Resource                                       | Content                                   |
| ---------------------------------------------- | ----------------------------------------- |
| `gitnexus://repo/{name}/context`               | Stats, staleness check                    |
| `gitnexus://repo/{name}/clusters`              | All functional areas with cohesion scores |
| `gitnexus://repo/{name}/cluster/{clusterName}` | Area members                              |
| `gitnexus://repo/{name}/processes`             | All execution flows                       |
| `gitnexus://repo/{name}/process/{processName}` | Step-by-step trace                        |
| `gitnexus://repo/{name}/schema`                | Graph schema for Cypher                   |

## Graph Schema

**Nodes:** File, Function, Class, Interface, Method, Community, Process
**Edges (via CodeRelation.type):** CALLS, IMPORTS, EXTENDS, IMPLEMENTS, DEFINES, MEMBER_OF, STEP_IN_PROCESS

```cypher
MATCH (caller)-[:CodeRelation {type: 'CALLS'}]->(f:Function {name: "myFunc"})
RETURN caller.name, caller.filePath
```
