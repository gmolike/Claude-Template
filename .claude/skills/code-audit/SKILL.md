---
name: code-audit
description: Cross-Code-verifying audit of a repo — flags drift/dead-code conservatively, never "DROP" without cross-repo verification
---

# Code-Audit

Wird vom Code-Auditor-Profil verwendet, wenn ein Repo (oder Sub-Slice) auf Dead-Code, FSD-Verstöße, Drift, oder Refactor-Kandidaten gescannt werden soll. **Conservative-by-default** — wenn unklar, BEHALTEN, nicht DROP.

## Warum diese Skill existiert

Welle-0-Audit im Refactor 2026-05 hatte 10 Misslesungen mit teilweise destruktiven "DROP"-Empfehlungen, die durch Welle-N-Agents korrigiert werden mussten. Häufigste Fehlmuster:

1. **M2M-Junctions als "Zero-Code"** — `DeityDomain`, `DragonTaxonomyRace/Species` sind Junction-Tables, nur via `include: { … }` referenziert
2. **Schema-Sub-Builds als "ungenutzt"** — `z.object({ X, Y, Z })` setzt sich aus Building-Blocks zusammen, die per File-Grep findbar sind
3. **FSD-Layer-Inversionen falsch positiv** — `widgets/* → features/*`-Import ist **erlaubt**, nicht "verkehrt"
4. **Asset-Loader-Pattern** — `.placeholder.json`-Sidecars existieren, Retire ohne echte Assets stummschaltet App
5. **API-Response-Schemas "obsolet bei Hono 4"** — kompletter Cross-Repo-Konsumer-Greps fehlten

**Lesson: Bei Zweifel BEHALTEN. Ein false-positive "BEHALTEN" kostet 0 Aufwand, ein false-positive "DROP" wird zu einem Recovery-Sprint.**

## Workflow

1. Story / Auftrag lesen — was genau soll auditiert werden?
2. **Vor jeder DROP-Empfehlung** die unten stehende Cross-Code-Verification-Checklist durchgehen
3. Output-Format: pro Befund einen Block mit:
   - **Befund:** [Was wurde gefunden]
   - **Empfehlung:** KEEP / REFACTOR / DROP
   - **Confidence:** high / medium / low / skeptical
   - **Cross-Code-Verifikation:** [welche Greps durchgeführt, welche Ergebnisse]
   - **Begründung:** [warum]
4. Bei **Confidence < high** für DROP: kein DROP, sondern KEEP oder REFACTOR mit Begründung
5. Cross-Repo-Befunde immer mit allen 5 Code-Repos verifizieren (api, shared, lore-admin, session-gm, session-player)

## Cross-Code-Verification-Checklist

### Vor jeder "Zero-Code" / "DROP"-Empfehlung

- [ ] **Prisma-Model:** mit `include`/`relation`-Grep verifiziert? (`grep -rn "<ModelName>" --include="*.ts"`, dann nach `include: { … }`)
- [ ] **M2M-Junction:** ist es ein 2-FK-Pattern (`@@id([fkA, fkB])`)? Falls ja → BEHALTEN, ist immer Junction
- [ ] **Lookup-Table:** sind FKs aus anderen Modellen drauf? Falls ja → BEHALTEN
- [ ] **Schema/Type:** alle Konsumer-Repos durchsucht? (workspace-level Grep, nicht nur ein Repo)
- [ ] **OpenAPI-Registry:** wird das Schema in `createRoute({ responses: { … } })` verwendet? → BEHALTEN
- [ ] **Asset-Loader:** Pattern `dynamic-import + placeholder.json` erkannt? → KEEP, Sound-Curation getrennt
- [ ] **Slice-Konsumenten:** wirklich keiner? `grep -rn "from.*<slice>" --include="*.ts" --include="*.tsx"` in jedem Frontend
- [ ] **Test-Konsumenten:** kein Test importiert das? (`grep` mit `*.test.ts*` + `e2e/*`)

### Vor jeder "FSD-Layer-Inversion"-Flag

- [ ] Ist es **widgets → features** oder **pages → widgets**? → ERLAUBT, FSD-konform, **kein Befund**
- [ ] Ist es **features → widgets** oder **entities → features**? → echte Inversion, KEEP-Befund mit "muss refactored werden" (kein DROP)
- [ ] Ist es **shared → entities/features/widgets/pages**? → schwere Inversion, REFACTOR-Befund

### Vor jeder "Schema-Removal"-Empfehlung

- [ ] **Building-Block-Pattern:** wird das Schema als Sub-Builder in einem anderen Schema verwendet? (`grep -rn "<SchemaName>" --include="*.ts"` in shared/)
- [ ] **Test-Konsumenten:** wird das Schema in Tests verwendet?
- [ ] **Frontend-Type-Imports:** wird der via `@flammenreiter/api-types` exportierte Type benutzt? (`grep -rn "<TypeName>" --include="*.ts*"` in allen 3 Frontends)
- [ ] **Variants:** sind die "duplikate" Schemas tatsächlich by-design getrennt (z. B. `CreateX` vs `UpdateX` vs `X`)? → KEEP

### Vor jedem "useX retire" (Hook/Service)

- [ ] **Konsumer-Anzahl:** wie viele Files importieren das? (`grep -rn "useX" --include="*.ts*"`)
- [ ] **Replacement-Ready:** ist der `useY` der das ersetzen soll bereits feature-complete? Beispiel: useSoundEffects vs useSfx → useSfx war nur Stub
- [ ] **Asset-Voraussetzung:** wenn Hook Assets braucht (Sounds, Images, Fonts), sind echte Assets da oder nur Placeholder?

## Output-Format

```markdown
# Audit-Bericht <Repo / Slice / Datum>

## Befund 1: <Name>

- **Status:** KEEP / REFACTOR / DROP
- **Confidence:** high / medium / low / skeptical
- **Details:** [Was wurde gefunden, wo, in welchem Kontext]
- **Cross-Code-Verifikation:**
  - `grep "<X>" in api/` → N Treffer in M Files
  - `grep "<X>" in shared/` → N Treffer
  - `grep "<X>" in lore-admin/` → 0 Treffer
  - `grep "<X>" in session-gm/` → 0 Treffer
  - `grep "<X>" in session-player/` → N Treffer
- **Begründung:** [Warum dieser Status]
- **Empfohlener Fix (falls REFACTOR):** [konkreter Plan]

## Befund 2: ...
```

## Verwandte Dokumente

- `workspace-docs/audits/2026-05-10/MASTER.md` — Beispiel-Output Welle-0-Audit (mit gelernten Misslesungen markiert)
- `.scrum/done/STORY-REFACTOR-2026-05-AUDIT.md` — der Audit-Sprint selbst
- `workflow-defaults.md` §9 — Risiko-bewusste Operationen (verwandt: niemals destruktiv ohne Verifikation)

## Anti-Patterns (NIE TUN)

- ❌ "Zero-Code"-Flag auf einem Prisma-Model setzen ohne `include`-Greps
- ❌ "Schema-Removal" empfehlen weil ein Sub-Schema "nicht direkt importiert" wird (Sub-Builders sind In-File-Building-Blocks)
- ❌ "Layer-Inversion" auf `widgets → features` flaggen (ist FSD-erlaubt)
- ❌ "Library-Migration" pauschal empfehlen ohne POC + Bundle-Vergleich + Konsumer-Audit
- ❌ Auf einem Repo gegrept → Empfehlung gegeben (immer Cross-Repo)
- ❌ Confidence-Level weglassen — Glenn muss skeptische Befunde von confident-Befunden trennen können
