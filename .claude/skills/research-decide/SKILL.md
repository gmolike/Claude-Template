---
name: research-decide
description: Run a disciplined research → adversarially-verify → decide → delegate → verify → document loop on a task. Invoke for high-stakes or uncertain work — a fast-moving library/tool API, a config schema or model ID to get exactly right, a genuine decision only the user can make, or a change with real blast radius (shared config, releases, multi-repo). Not for trivial, fully-specified, single-file work.
---

# Research & Decide

An operating loop for high-stakes or uncertain work. The point: never trust memory on a fast-moving surface, never guess a decision that is the user's to make, never implement inline, and never call it done on green tests alone.

## When this applies

- **Uncertain / fast-moving surface** — a library or tool API, a config schema, a model ID, a format that shifts between versions. Verify against the live source, not recall.
- **A genuine decision exists** — mutually exclusive approaches, a scope or strictness call, a value you cannot infer. That belongs to the user.
- **Real blast radius** — shared config, a release, an outward or irreversible action, many files or repos.

If none of these hold — the task is small, fully specified, and reversible — skip the ceremony and just do it.

## The loop

1. **Frame.** Restate the task in one line. Separate what is known or inferable from what is genuinely unknown or a decision. State assumptions inline; do not ask what you can infer or verify yourself.
2. **Research against ground truth.** For anything uncertain, verify against primary sources — official docs, the actual source code — not memory. Fan out read-only agents over disjoint questions; each returns a focused, cited summary. Hold the conclusions, not the transcripts.
3. **Adversarially verify.** A second, independent pass tries to *refute* each load-bearing finding — especially anything that, if wrong, deadlocks, corrupts, or silently under-delivers. Default to the pessimistic reading unless the docs are explicit. One confident answer is not proof.
4. **Surface the decisions.** Bring the user the real choices — one decision per round, each with a recommended option and the trade-off stated plainly. Make it an explicit question, not a line buried in prose. Do not re-ask what is already settled.
5. **Delegate the build.** The orchestrator does not implement. Split the work into disjoint slices (by file or domain — no shared-file collisions) and dispatch parallel writers with exact, self-contained instructions. Keep your own context lean.
6. **Verify the result.** Run the real gate — build, the full test suite, and the actual behavior (drive the flow, grep-prove the claim, do a real run) — not just "tests are green." Fix what verification surfaces before calling it done.
7. **Document & gate.** Update the changelog / decision record / memory. Ship in dependency order. Outward or irreversible steps — releases, pushes, publishes — wait for an explicit go; confirm before firing, and say plainly when a change takes effect.

## Principles

- **Verify, don't trust.** A claim about a moving API is a hypothesis until a primary source confirms it.
- **One decision at a time, with a recommendation.** The user decides what is theirs; you decide the rest and move.
- **Delegate implementation, keep the orchestrator clean.** Fewer agents, each at full effort, over disjoint work.
- **Fail open on safety-critical guards.** Never ship a change whose failure mode is a silent deadlock or corruption.
- **Be honest about blast radius** — what changes, and when it takes effect.

---

Apply this loop to: **$ARGUMENTS**

(If no task was given, ask for the one thing to run it on.)
