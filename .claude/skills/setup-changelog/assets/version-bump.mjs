#!/usr/bin/env node
// @ts-check
/**
 * version-bump.mjs — dependency-free reference SemVer bumper (ESM, Node >= 18).
 *
 * WHAT IT DOES
 *   1. Reads Conventional Commits since the last `v*` tag (via `git`, no deps).
 *   2. Derives the SemVer level:  feat → minor ·  fix/perf → patch ·
 *      `type!:` OR a `BREAKING CHANGE:` footer → major.
 *   3. Bumps `package.json#version`.
 *   4. Moves `## [Unreleased]` → `## [x.y.z] - <YYYY-MM-DD>` in CHANGELOG.md
 *      (leaving a fresh, empty `## [Unreleased]` above it).
 *   5. Appends/updates the compare-footer links at the bottom of CHANGELOG.md.
 *
 * ┌─ REFERENCE SCRIPT — ADAPT, DON'T SHIP VERBATIM ────────────────────────────┐
 * │ This is a starting point the `setup-changelog` skill drops into a target    │
 * │ project. Wire it to that project's layout (monorepo package paths, tag      │
 * │ prefix, remote host) before trusting it in CI or a hook.                     │
 * └─────────────────────────────────────────────────────────────────────────────┘
 *
 * ── TRAP 1 · WHERE you may run this as a git hook (git snapshots the tree EARLY)
 *    git builds the in-progress commit's tree BEFORE `prepare-commit-msg` and never
 *    re-reads it. So a `git add package.json CHANGELOG.md` done by this script only
 *    folds into the CURRENT commit when it runs in the `pre-commit` stage. Run it in
 *    `prepare-commit-msg` / `commit-msg` and the bump leaks into the NEXT commit
 *    ("rides one commit behind"). Therefore: bump in `pre-commit` ONLY, or in CI —
 *    NEVER in `commit-msg`. See shared/memory/00-knowledge.md.
 *
 * ── TRAP 2 · WHY this is a .mjs file and not an inline `node -e`
 *    On Windows / Git-Bash a multi-line `node -e "…"` silently runs empty and exits
 *    0 — a bump that never happened, green. Keep the logic in a real file and invoke
 *    it as `node scripts/version-bump.mjs`. See shared/memory/00-knowledge.md.
 *
 * USAGE
 *    node scripts/version-bump.mjs                 # derive level from commits, write
 *    node scripts/version-bump.mjs --level minor   # force a level (major|minor|patch)
 *    node scripts/version-bump.mjs --dry-run       # print the plan, write nothing
 *    node scripts/version-bump.mjs --tag-prefix v  # tag prefix (default "v")
 */

import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

/** @typedef {'major' | 'minor' | 'patch'} Level */

const ROOT = process.cwd();
const PKG_PATH = resolve(ROOT, 'package.json');
const CHANGELOG_PATH = resolve(ROOT, 'CHANGELOG.md');

// ── CLI args ────────────────────────────────────────────────────────────────
const argv = process.argv.slice(2);
const DRY_RUN = argv.includes('--dry-run');
const FORCED_LEVEL = /** @type {Level | undefined} */ (readFlag('--level'));
const TAG_PREFIX = readFlag('--tag-prefix') ?? 'v';

/**
 * Read a `--flag value` pair from argv.
 * @param {string} flag
 * @returns {string | undefined}
 */
function readFlag(flag) {
  const i = argv.indexOf(flag);
  return i !== -1 && i + 1 < argv.length ? argv[i + 1] : undefined;
}

/**
 * Run git and return trimmed stdout ('' on non-zero exit — e.g. no tags yet).
 * @param {string[]} args
 * @returns {string}
 */
function git(args) {
  try {
    return execFileSync('git', args, { encoding: 'utf8' }).trim();
  } catch {
    return '';
  }
}

// ── 1 · last tag + commit range ───────────────────────────────────────────────
/** Newest `v*` tag by SemVer order, or '' when the repo has none yet. */
const lastTag = git(['tag', '--list', `${TAG_PREFIX}*`, '--sort=-v:refname']).split('\n')[0] ?? '';
const range = lastTag ? `${lastTag}..HEAD` : 'HEAD';

// Field sep = US (\x1f), record sep = RS (\x1e) — safe against newlines in bodies.
const raw = git(['log', range, '--no-merges', '--format=%s%x1f%b%x1e']);
const commits = raw
  .split('\x1e')
  .map((rec) => rec.replace(/^\n/, ''))
  .filter((rec) => rec.trim().length > 0)
  .map((rec) => {
    const [subject = '', body = ''] = rec.split('\x1f');
    return { subject: subject.trim(), body: body.trim() };
  });

if (commits.length === 0 && !FORCED_LEVEL) {
  console.error(`No commits since ${lastTag || 'repo start'} — nothing to bump. Use --level to force.`);
  process.exit(1);
}

// ── 2 · derive SemVer level ───────────────────────────────────────────────────
const TYPE_RE = /^(\w+)(\([^)]*\))?(!)?:/; // feat| fix(scope)| feat(x)!:
const BREAKING_RE = /^BREAKING[ -]CHANGE:/m;

let hasBreaking = false;
let hasFeat = false;
let hasPatch = false;

for (const { subject, body } of commits) {
  if (BREAKING_RE.test(subject) || BREAKING_RE.test(body)) hasBreaking = true;
  const m = TYPE_RE.exec(subject);
  if (!m) continue;
  const [, type, , bang] = m;
  if (bang === '!') hasBreaking = true;
  if (type === 'feat') hasFeat = true;
  if (type === 'fix' || type === 'perf') hasPatch = true;
}

/** @type {Level} */
const level =
  FORCED_LEVEL ??
  (hasBreaking ? 'major' : hasFeat ? 'minor' : hasPatch ? 'patch' : 'patch');

if (!FORCED_LEVEL && !hasBreaking && !hasFeat && !hasPatch) {
  console.warn('No feat/fix/perf/breaking commits found — defaulting to a patch bump.');
}

// ── 3 · bump package.json#version ─────────────────────────────────────────────
if (!existsSync(PKG_PATH)) {
  console.error(`package.json not found at ${PKG_PATH}`);
  process.exit(1);
}
const pkgText = readFileSync(PKG_PATH, 'utf8');
const pkg = JSON.parse(pkgText);
const current = String(pkg.version ?? '0.0.0');
const next = applyBump(current, level);

/**
 * Apply a SemVer bump. Drops any pre-release/build metadata (reference behavior).
 * @param {string} version
 * @param {Level} lvl
 * @returns {string}
 */
function applyBump(version, lvl) {
  const core = version.split(/[-+]/)[0];
  const [maj = 0, min = 0, pat = 0] = core.split('.').map((n) => Number.parseInt(n, 10) || 0);
  if (lvl === 'major') return `${maj + 1}.0.0`;
  if (lvl === 'minor') return `${maj}.${min + 1}.0`;
  return `${maj}.${min}.${pat + 1}`;
}

const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD (UTC)

console.log(`Level:   ${level}${FORCED_LEVEL ? ' (forced)' : ''}`);
console.log(`Version: ${current} → ${next}`);
console.log(`Date:    ${today}`);
console.log(`Commits: ${commits.length} since ${lastTag || 'repo start'}`);

if (DRY_RUN) {
  console.log('--dry-run: no files written.');
  process.exit(0);
}

// Preserve the original 2-space JSON style + trailing newline.
const nextPkgText = pkgText.replace(
  /("version"\s*:\s*")[^"]*(")/,
  (_all, a, b) => `${a}${next}${b}`,
);
if (nextPkgText === pkgText) {
  console.error('Could not locate the "version" field in package.json — aborting.');
  process.exit(1);
}
writeFileSync(PKG_PATH, nextPkgText);

// ── 4 · move [Unreleased] → [next] in CHANGELOG.md ────────────────────────────
if (!existsSync(CHANGELOG_PATH)) {
  console.error(`CHANGELOG.md not found at ${CHANGELOG_PATH} — start from the CHANGELOG.template.md asset.`);
  process.exit(1);
}
let changelog = readFileSync(CHANGELOG_PATH, 'utf8');

// `[ \t]*` (not `\s*`) so the match does NOT swallow the trailing newline — otherwise the
// rebuilt section gains an extra blank line under `## [Unreleased]`.
const unreleasedHeading = /^##[ \t]*\[Unreleased\][ \t]*$/m;
const hUn = unreleasedHeading.exec(changelog);
if (!hUn) {
  console.error('No `## [Unreleased]` heading in CHANGELOG.md — cannot roll a release.');
  process.exit(1);
}

// Slice the Unreleased body: from just after its heading to the next `## [` heading (or EOF).
const bodyStart = hUn.index + hUn[0].length;
const nextHeading = /^##\s*\[/m;
nextHeading.lastIndex = bodyStart;
const rel = changelog.slice(bodyStart).search(/^##\s*\[/m);
const bodyEnd = rel === -1 ? changelog.length : bodyStart + rel;
const unreleasedBody = changelog.slice(bodyStart, bodyEnd).trim();

if (unreleasedBody.length === 0 && !FORCED_LEVEL) {
  console.error('`## [Unreleased]` is empty — write your changes there before releasing (or pass --level).');
  process.exit(1);
}

const releasedSection = `## [${next}] - ${today}\n\n${unreleasedBody}\n\n`;
changelog =
  changelog.slice(0, bodyStart) +
  `\n\n${releasedSection}` +
  changelog.slice(bodyEnd).replace(/^\n+/, '');

// ── 5 · compare-footer links ──────────────────────────────────────────────────
const repoUrl = deriveRepoUrl();
if (repoUrl) {
  changelog = updateFooterLinks(changelog, repoUrl, lastTag, next);
} else {
  console.warn('Could not derive the repository URL from `git remote` — skipping compare-footer links.');
}

/**
 * Turn `git remote get-url origin` into an https base URL (handles SSH + `.git`).
 * @returns {string}
 */
function deriveRepoUrl() {
  const remote = git(['remote', 'get-url', 'origin']);
  if (!remote) return '';
  // git@github.com:owner/repo.git → https://github.com/owner/repo
  const ssh = /^git@([^:]+):(.+?)(?:\.git)?$/.exec(remote);
  if (ssh) return `https://${ssh[1]}/${ssh[2]}`;
  return remote.replace(/^https?:\/\//, 'https://').replace(/\.git$/, '');
}

/**
 * Rewrite the `[Unreleased]:` compare link and insert the new `[version]:` link.
 * @param {string} md
 * @param {string} baseUrl
 * @param {string} prevTag  previous `v*` tag, or '' for the first release
 * @param {string} version  the just-bumped version (no `v` prefix)
 * @returns {string}
 */
function updateFooterLinks(md, baseUrl, prevTag, version) {
  const newTag = `${TAG_PREFIX}${version}`;
  const unreleasedLink = `[Unreleased]: ${baseUrl}/compare/${newTag}...HEAD`;
  const versionLink = prevTag
    ? `[${version}]: ${baseUrl}/compare/${prevTag}...${newTag}`
    : `[${version}]: ${baseUrl}/releases/tag/${newTag}`;

  const hasUnreleasedLink = /^\[Unreleased\]:.*$/m.test(md);
  if (hasUnreleasedLink) {
    // Replace the existing [Unreleased]: line and drop the new version link right under it.
    return md.replace(/^\[Unreleased\]:.*$/m, `${unreleasedLink}\n${versionLink}`);
  }
  // No footer yet → append one.
  const sep = md.endsWith('\n') ? '' : '\n';
  return `${md}${sep}\n${unreleasedLink}\n${versionLink}\n`;
}

writeFileSync(CHANGELOG_PATH, changelog);

console.log('');
console.log('Wrote package.json + CHANGELOG.md.');
console.log('Next steps (deliberate — never reflexive):');
console.log(`  1. Review the diff, commit:   git commit -m "release: ${TAG_PREFIX}${next}"`);
console.log(`  2. On explicit go-ahead, tag: git tag ${TAG_PREFIX}${next}`);
console.log('  Tagging is what costs money (CI publish) — batch patches, tag on a milestone.');
