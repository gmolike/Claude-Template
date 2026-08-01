---
name: llm-council
description: Convene a Claude-diverse LLM council to deliberate a complex or high-stakes question — members answer independently, peer-rank each other's ANONYMIZED answers, and a chairman synthesizes the final answer. Trigger on wide-solution-space decisions, architecture calls, high-stakes or genuinely uncertain work — not trivial, fully-specified tasks.
argument-hint: '[frage oder entscheidung]'
allowed-tools: Task, Read, Grep, Glob, Bash
---

# LLM Council

A three-stage deliberation engine for a single hard question. Members answer the query independently, then peer-rank each other's answers with identities stripped, then a chairman synthesizes one final answer from all of it. The value comes from tier diversity: a Claude-diverse line-up produces diverse failure modes, so the ranking stage catches what any single model would miss — perspective-diverse verify, made concrete. Reach for the council when the question has a wide solution space or real stakes and a single model's confident answer is not enough. It complements `research-decide`: that skill is the operating loop (frame → research → verify → decide → build → verify → document); the council is the deliberation engine its "surface the decisions" step can invoke when the decision itself is contested rather than merely under-researched.

## When to use

- **Wide solution space** — several defensible approaches, no obviously-correct one; an architecture or design call.
- **High-stakes or irreversible** — the answer drives a change with real blast radius, and being wrong is expensive.
- **Genuine multi-way decision under uncertainty** — the tradeoffs are contested and one model's judgment is a single point of failure.
- **You want adversarial cross-check by construction** — independent answers, then blind peer ranking, beat one long chain of thought.

## When NOT to use

- **Trivial or fully specified** — the answer is determined; there is nothing to deliberate. Just do it.
- **Reversible single-file work** — small, local, cheaply undone. Council ceremony is pure overhead.
- **A research gap, not a decision** — the question is answerable from a primary source. Verify against ground truth instead (that's `research-decide`'s job), and only convene the council if a genuine judgment call survives the research.

## The council

Standard per ADR-0031. Three members across distinct tiers, one chairman:

- **Opus 5** (`opus`) — the canonical model; strongest agentic reasoning and broad synthesis.
- **Opus 4.8** (`claude-opus-4-8`) — the previous generation; deep and careful, with a different failure profile.
- **Sonnet 5** (`claude-sonnet-5`) — fast, pragmatic tier; catches over-engineering and surfaces the plain reading.
- **Chairman: Opus 5** (`opus`) — the strongest freely-available synthesis model compiles the final answer.

The point of the line-up is **tier diversity → diverse failure modes**. Members that fail differently make the peer-ranking stage informative; three copies of one model would just agree with themselves.

**No seat is Fable 5.** Fable costs double (10/50 vs 5/25 USD per MTok) and runs in no path automatically — seating it, in any seat or as chairman, needs the user's explicit prior consent first (`06-model-effort`, ADR-0037). The line-up above needs no such ask.

## The three stages

**Stage 1 — First Opinions.** The query is fanned out to every member independently. Each answers in isolation, seeing only the question — never another member's answer. Collect all three answers.

**Stage 2 — Review (anonymized ranking).** Each member receives the *other* members' answers with identity stripped — no model names, presented only as **Response A / Response B / Response C** — and ranks them by **accuracy + insight**, each with a short justification. Anonymization is load-bearing: it stops a member playing favorites by brand or tier, and a member never sees which answer is its own beyond its position in the shuffled set. Every member reviews; collect all rankings.

**Stage 3 — Final Response (Chairman synthesis).** The chairman (**Opus 5**) receives all first opinions plus all rankings and compiles one final answer — taking the strongest supported points, resolving conflicts on the merits, and **explicitly noting where the council disagreed** rather than papering over it. The disagreement map is part of the deliverable: it tells the user where the answer is solid and where it is a judgment call.

## Running it via Workflow

Drive the council with the **Workflow tool**. Pin every `agent()` call's model to its tier and run at `effort: max` (per `06-model-effort`) — a fan-out step does not inherit the delegation model, so set it explicitly on each call. Label the three stages **First Opinions**, **Review**, **Chairman**.

Shape:

```
# Stage 1 — First Opinions (independent, parallel)
opinions = parallel(
  agent(model: opus,             effort: max, task: "Answer independently: $QUESTION"),
  agent(model: claude-opus-4-8,  effort: max, task: "Answer independently: $QUESTION"),
  agent(model: claude-sonnet-5,  effort: max, task: "Answer independently: $QUESTION"),
)

# Stage 2 — Review (blind peer ranking, parallel)
# For each member, pass the OTHER two answers with identities stripped -> Response A/B/C
rankings = parallel(
  agent(model: opus,             effort: max, task: rank(anonymize(others_of(opinions, opus5)))),
  agent(model: claude-opus-4-8,  effort: max, task: rank(anonymize(others_of(opinions, opus48)))),
  agent(model: claude-sonnet-5,  effort: max, task: rank(anonymize(others_of(opinions, sonnet)))),
)

# Stage 3 — Chairman synthesis (single)
final = agent(model: opus, effort: max,
  task: synthesize(opinions, rankings, note_disagreements: true))
```

`parallel(...)` fans the members out over disjoint work; `anonymize(...)` strips model identity and relabels answers A/B/C; the chairman step is a single synthesis pass. Keep the orchestrator lean — hold the three answers, the rankings, and the final synthesis, not the full transcripts.

---

Convene the council on: **$ARGUMENTS**

(If none given, ask for the one question or decision to deliberate.)
