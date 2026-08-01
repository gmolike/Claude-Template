/**
 * Golden test template — ONE shared fixture set, run in EVERY consumer's gate.
 *
 * This file ships as `*.example.ts` ON PURPOSE: it must not be collected by any consumer's default
 * test glob while it sits unadopted under `.claude/skills/…/assets/`. **When you adopt it, copy it
 * into the consumer and rename it to `contract.golden.test.ts`** — only then is it a test.
 *
 * It exercises the only path that catches shim drift:
 *
 *     build → serialize → validate → read
 *
 * The order is load-bearing: the save schema validates the **serialized wire form**, not the
 * in-memory object. Validating before `JSON.stringify` is what let the shipped bug through — the
 * API never sees the object, it sees the payload, and `Date` / `undefined` / `Map` / class
 * instances differ between the two.
 *
 * A renderer/unit test does NOT catch shim drift: producer and assertion come from the SAME local
 * copy, so the test is internally consistent and stays green while the copies diverge from each
 * other. Only the round-trip crosses a real package boundary.
 *
 * Canonical pattern + rationale: `skill:contract-golden-test` (SKILL.md).
 * Rule: `25-orchestration` ("Consolidate shared semantics"). Decision: ADR-0021.
 *
 * HOW TO ADOPT (three edits):
 *   1. Rename to `contract.golden.test.ts` in the consumer (`src/**\/contract.golden.test.ts`).
 *   2. Uncomment the REAL IMPORTS block and point it at your modules.
 *      Do NOT re-point the fixture import at a local copy — the fixture set lives in exactly ONE
 *      package and every consumer imports THAT one (see `fixtures.example.ts`).
 *   3. Delete everything between the STAND-IN markers.
 *
 * Then RED-verify (mandatory, per `30-quality` "verified RED, not assumed"): swap the OLD (v1)
 * migrate/producer back in, run `vitest run`, watch this file FAIL, note the emitted diff, swap back.
 */
import { describe, expect, it } from 'vitest';

// ─────────────────────────────────────────────────────────────────────────────────────────────────
// 1. REAL IMPORTS — uncomment and re-point at your own modules.
// ─────────────────────────────────────────────────────────────────────────────────────────────────
// import { editorBuild } from '@repo/editor';                              // the producer
// import { SaveSchema, migrateOnRead } from '@repo/shared-contract';       // save path + read path
// import { tabGroupLayout, legacyV1Slot } from '@repo/contract-fixtures';  // the ONE fixture set

// ─────────────────────────────────────────────────────────────────────────────────────────────────
// 2. STAND-IN START — delete this whole block once (2) is wired.
//    It exists only so the template runs green out of the box and shows the exact shapes the four
//    round-trip steps expect. It is a v2 "slot" contract: `panels[]` + `activePanelId` (the v1 form
//    it replaced carried a single `panelId`).
// ─────────────────────────────────────────────────────────────────────────────────────────────────

/** One panel inside a slot. Replace with your contract's own child node type. */
export interface Panel {
  readonly id: string;
  readonly kind: string;
}

/** v2 wire form: an ordered `panels[]` plus the focused `activePanelId`. */
export interface SlotV2 {
  readonly version: 2;
  readonly panels: readonly Panel[];
  readonly activePanelId: string | null;
}

/** v1 wire form — kept ONLY so the RED-verify canary below has something old to swap in. */
export interface SlotV1 {
  readonly version: 1;
  readonly panelId: string | null;
}

/** What the producer consumes. Replace with your editor's/builder's own input type. */
export interface LayoutInput {
  readonly panels: readonly Panel[];
  readonly focused: string | null;
}

/** Zod-compatible result shape, so a real `z.ZodType` drops in unchanged. */
export interface SafeParseResult<T> {
  readonly success: boolean;
  readonly data?: T;
}

/** Minimal `safeParse` surface — a real Zod schema satisfies this structurally. */
export interface Validator<T> {
  safeParse(value: unknown): SafeParseResult<T>;
}

/**
 * Producer stand-in: builds the v2 form from a layout input.
 * Replace with your editor/builder entry point.
 *
 * @param input - the layout the editor is holding
 * @returns the v2 slot the editor would hand to the save path
 */
export function editorBuild(input: LayoutInput): SlotV2 {
  return { version: 2, panels: [...input.panels], activePanelId: input.focused };
}

/**
 * Save-path stand-in: the schema the API validates the WIRE payload against. Replace with your real
 * `SaveSchema` (a Zod schema satisfies `Validator<T>` as-is).
 */
export const SaveSchema: Validator<SlotV2> = {
  safeParse(value: unknown): SafeParseResult<SlotV2> {
    if (typeof value !== 'object' || value === null) return { success: false };
    const v = value as Record<string, unknown>;
    const ok =
      v.version === 2 &&
      Array.isArray(v.panels) &&
      v.panels.every((p) => typeof p === 'object' && p !== null && typeof (p as Panel).id === 'string') &&
      (typeof v.activePanelId === 'string' || v.activePanelId === null);
    return ok ? { success: true, data: v as unknown as SlotV2 } : { success: false };
  },
};

/**
 * Read-path stand-in: normalizes any accepted wire form (v1 or v2) to the CURRENT form.
 * Replace with your real `migrateOnRead`.
 *
 * @param wire - the JSON-decoded payload as it arrives from the API
 * @returns the current (v2) form
 */
export function migrateOnRead(wire: unknown): SlotV2 {
  const v = wire as Partial<SlotV2> & Partial<SlotV1>;
  if (v.version === 2) {
    return { version: 2, panels: [...(v.panels ?? [])], activePanelId: v.activePanelId ?? null };
  }
  const id = v.panelId ?? null;
  return { version: 2, panels: id ? [{ id, kind: 'unknown' }] : [], activePanelId: id };
}

/**
 * The OLD (v1) read path — the exact drift that shipped: it only understands `panelId`, so every v2
 * payload degrades to an empty slot SILENTLY (no throw, no log). Used by the canary below.
 *
 * @param wire - the JSON-decoded payload as it arrives from the API
 * @returns the v1 form the stale shim produced
 */
export function migrateOnReadV1(wire: unknown): SlotV1 {
  const v = wire as Partial<SlotV1>;
  return { version: 1, panelId: v.panelId ?? null };
}

/** The ONE shared fixture set — in a real adoption this comes from the fixture package. */
const tabGroupLayout: LayoutInput = {
  panels: [
    { id: 'p1', kind: 'map' },
    { id: 'p2', kind: 'sheet' },
  ],
  focused: 'p2',
};

/** Legacy payload still sitting in the database — the read path must lift it to the current form. */
const legacyV1Slot: SlotV1 = { version: 1, panelId: 'p1' };

// ─────────────────────────────────────────────────────────────────────────────────────────────────
// STAND-IN END
// ─────────────────────────────────────────────────────────────────────────────────────────────────

describe('contract golden test — slot form', () => {
  it('round-trips build → serialize → validate → read', () => {
    const built = editorBuild(tabGroupLayout); // producer
    const wire: unknown = JSON.parse(JSON.stringify(built)); // api boundary (serialize)
    expect(SaveSchema.safeParse(wire).success).toBe(true); // save path validates the WIRE form
    expect(migrateOnRead(wire)).toEqual(built); // read path
    // RED-verify: swap in the OLD (v1) migrate → must fail.
  });

  it('lifts the legacy payload to the SAME form the producer builds', () => {
    // Without this case a consumer can keep reading v1 forever and still look green: the
    // round-trip above only ever shows it payloads its own producer just made.
    const legacyWire: unknown = JSON.parse(JSON.stringify(legacyV1Slot));
    const migrated = migrateOnRead(legacyWire);
    // Serialize again before validating: what gets saved back is the payload, not the object.
    expect(SaveSchema.safeParse(JSON.parse(JSON.stringify(migrated))).success).toBe(true);
    expect(migrated.version).toBe(2);
  });

  // ── RED-verify canary ──────────────────────────────────────────────────────────────────────────
  // Mutates the GATE, not the fixture (`30-quality`): it pins that the OLD read path really does
  // fail the assertion above, so `toEqual` is load-bearing and not vacuously true.
  // It does NOT replace the manual swap in your own consumer — your old implementation differs from
  // this stand-in. Do the swap once per consumer and watch the real test fall.
  it('RED-verify: the OLD (v1) read path must NOT satisfy the round-trip', () => {
    const built = editorBuild(tabGroupLayout);
    const wire: unknown = JSON.parse(JSON.stringify(built));
    expect(migrateOnReadV1(wire)).not.toEqual(built);
  });
});
