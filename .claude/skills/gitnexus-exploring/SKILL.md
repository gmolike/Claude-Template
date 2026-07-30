---
name: gitnexus-exploring
description: "Use when the user asks how code works, wants to understand architecture, trace execution flows, or explore unfamiliar parts of the codebase. Examples: \"How does X work?\", \"What calls this function?\", \"Show me the auth flow\""
---

# Exploring Codebases with GitNexus

## When to Use

- "How does authentication work?"
- "What's the project structure?"
- "Show me the main components"
- "Where is the database logic?"
- Understanding code you haven't seen before

## Workflow

```
0. npx gitnexus status  → VERIFY FRESHNESS FIRST. Compare "Indexed commit" to `git rev-parse HEAD`.
                          Not equal (or "Repository not indexed.") → npx gitnexus analyze. Do not skip.
1. READ gitnexus://repos                          → Discover indexed repos
2. READ gitnexus://repo/{name}/context             → Codebase overview
3. gitnexus_query({query: "<what you want to understand>"})  → Find related execution flows
4. gitnexus_context({name: "<symbol>"})            → Deep dive on specific symbol
5. READ gitnexus://repo/{name}/process/{name}      → Trace full execution flow
```

## Step 0 — Verify the index is fresh (mandatory)

Steps 1 and 2 *do* carry a staleness signal — `gitnexus://repos` and `.../context` compare the indexed commit to HEAD and emit `⚠️ Index is N commits behind HEAD. Run analyze tool to update.` **Do not wait for it anyway.** It fails in the direction that hurts: any git error — an indexed commit rebased away or garbage-collected — is swallowed and reported as *fresh*, and it counts only committed drift, never your uncommitted working tree. Silence means "no drift I could measure," not "the graph matches your tree."

The graph does not self-maintain — no hook re-indexes it after a commit or merge. Check it yourself:

```bash
npx gitnexus status        # "Indexed commit" must equal `git rev-parse HEAD`
git rev-parse HEAD
```

A stale graph is quietly wrong when exploring: `gitnexus_query`/`gitnexus_context` answer confidently from code that no longer exists, so you learn an architecture that was already refactored away.

> **Trap for automation:** `npx gitnexus status` **exits 0 in every case** — stale index and "Repository not indexed." alike. A `gitnexus status || block` gate never fires. Parse stdout; do not branch on the exit code.

## Checklist

```
- [ ] npx gitnexus status FIRST — "Indexed commit" == HEAD, else analyze (a stale graph describes code that no longer exists)
- [ ] READ gitnexus://repo/{name}/context
- [ ] gitnexus_query for the concept you want to understand
- [ ] Review returned processes (execution flows)
- [ ] gitnexus_context on key symbols for callers/callees
- [ ] READ process resource for full execution traces
- [ ] Read source files for implementation details
```

## Resources

| Resource                                | What you get                                            |
| --------------------------------------- | ------------------------------------------------------- |
| `gitnexus://repo/{name}/context`        | Stats, staleness warning (~150 tokens)                  |
| `gitnexus://repo/{name}/clusters`       | All functional areas with cohesion scores (~300 tokens) |
| `gitnexus://repo/{name}/cluster/{name}` | Area members with file paths (~500 tokens)              |
| `gitnexus://repo/{name}/process/{name}` | Step-by-step execution trace (~200 tokens)              |

## Tools

**gitnexus_query** — find execution flows related to a concept:

```
gitnexus_query({query: "payment processing"})
→ Processes: CheckoutFlow, RefundFlow, WebhookHandler
→ Symbols grouped by flow with file locations
```

**gitnexus_context** — 360-degree view of a symbol:

```
gitnexus_context({name: "validateUser"})
→ Incoming calls: loginHandler, apiMiddleware
→ Outgoing calls: checkToken, getUserById
→ Processes: LoginFlow (step 2/5), TokenRefresh (step 1/3)
```

## Example: "How does payment processing work?"

```
1. READ gitnexus://repo/my-app/context       → 918 symbols, 45 processes
2. gitnexus_query({query: "payment processing"})
   → CheckoutFlow: processPayment → validateCard → chargeStripe
   → RefundFlow: initiateRefund → calculateRefund → processRefund
3. gitnexus_context({name: "processPayment"})
   → Incoming: checkoutHandler, webhookHandler
   → Outgoing: validateCard, chargeStripe, saveTransaction
4. Read src/payments/processor.ts for implementation details
```
