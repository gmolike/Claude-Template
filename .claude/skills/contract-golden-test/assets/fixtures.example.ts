/**
 * The ONE shared fixture set — example.
 *
 * THIS FILE LIVES IN EXACTLY ONE PACKAGE (e.g. `packages/contract-fixtures/src/fixtures.ts`) AND IS
 * IMPORTED BY EVERY CONSUMER. Never copy it into a consumer, never "adjust it slightly" per package:
 * a copied fixture drifts along with the copy it lives next to, and the golden test then only
 * confirms the local truth — exactly the failure it exists to catch.
 *
 *     packages/contract-fixtures/src/fixtures.ts   ← the ONE set (this file)
 *        ↑              ↑                 ↑
 *     apps/api     apps/web-gm      apps/web-player   ← each IMPORTS, none copies
 *
 * The test itself does run N times (once per consumer's gate) — that is the point: a single central
 * run would never see the local copy. Rule: `25-orchestration`. Decision: ADR-0021.
 *
 * Coverage rule of thumb — one fixture per contract variant that actually exists in the wild:
 *   - the CURRENT form (the one the producer builds today),
 *   - every LEGACY form still readable from storage,
 *   - the degenerate edge cases (empty collection, all-optional-fields-absent).
 * Anything the read path must accept needs a fixture, or drift hides in the untested variant.
 */

/** One panel inside a slot. */
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

/** v1 wire form — still present in storage, so the read path must keep lifting it. */
export interface SlotV1 {
  readonly version: 1;
  readonly panelId: string | null;
}

/** What the producer (editor/builder) consumes. */
export interface LayoutInput {
  readonly panels: readonly Panel[];
  readonly focused: string | null;
}

// ── producer inputs ──────────────────────────────────────────────────────────────────────────────

/** The everyday case: a multi-panel tab group with a focused panel. */
export const tabGroupLayout: LayoutInput = {
  panels: [
    { id: 'p1', kind: 'map' },
    { id: 'p2', kind: 'sheet' },
  ],
  focused: 'p2',
};

/** Degenerate case: no panels at all — catches shims that assume `panels[0]` exists. */
export const emptyLayout: LayoutInput = { panels: [], focused: null };

// ── wire payloads (what the read path receives) ──────────────────────────────────────────────────

/** Current form, as the API returns it. */
export const currentSlot: SlotV2 = {
  version: 2,
  panels: [
    { id: 'p1', kind: 'map' },
    { id: 'p2', kind: 'sheet' },
  ],
  activePanelId: 'p2',
};

/** Legacy form still sitting in storage — must be lifted, never skipped. */
export const legacyV1Slot: SlotV1 = { version: 1, panelId: 'p1' };

/** Legacy form with nothing selected — the `null` branch of the migration. */
export const legacyV1EmptySlot: SlotV1 = { version: 1, panelId: null };

/**
 * Every wire payload the read path must accept, for table-driven golden tests.
 * Extend this list when a new variant becomes readable — a variant that is not in here is a variant
 * no consumer's gate covers.
 */
export const allReadableSlots: ReadonlyArray<SlotV1 | SlotV2> = [currentSlot, legacyV1Slot, legacyV1EmptySlot];
