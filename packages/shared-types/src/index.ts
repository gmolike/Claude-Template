/**
 * @module @repo/shared-types
 * Single Source of Truth für alle Types und Zod Schemas.
 * Web, API und Mobile importieren von hier.
 *
 * Node reads this package at runtime (`main` -> `src/index.ts`, no build step), so every relative
 * specifier keeps its `.ts` extension; without it `node` fails with ERR_MODULE_NOT_FOUND while every
 * bundler-based gate stays green. `moduleResolution: "NodeNext"` in tsconfig.json flags a missing
 * extension wherever a typecheck actually runs over this package.
 */
export * from './user.ts';
export * from './api.ts';
