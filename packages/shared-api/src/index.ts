/**
 * @module @repo/shared-api
 * API Client und Query Factories — genutzt von Web und Mobile.
 *
 * `main` points at `src/index.ts` with no build step, so a Node process that imports this package
 * reads the source as-is: relative specifiers keep their `.ts` extension (see `@repo/shared-types`).
 */
export { userQueries } from './queries/user.queries.ts';
