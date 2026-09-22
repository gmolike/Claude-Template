/**
 * @module @repo/shared-ui
 * Gemeinsame UI-Komponenten für Web und Mobile.
 *
 * BUNDLER-ONLY: this package ships JSX source (`.tsx`) and has no build step, so only a bundler
 * (Vite) can consume it. Node strips types from `.ts`/`.mts`/`.cts` but never from `.tsx`, so no
 * specifier style helps: a Node import fails with ERR_MODULE_NOT_FOUND on `./button` and with
 * ERR_UNKNOWN_FILE_EXTENSION on `./button.tsx`. Before any Node process (API, script, SSR) imports
 * it, give it a build step plus `exports` on `dist`.
 */
export { Button } from './button';
