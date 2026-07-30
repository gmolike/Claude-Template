// commitlint.config.mjs — Conventional Commits gate (reference; adapt per project).
//
// Enforces the commit grammar the version-bump derivation reads: `type(scope)?: subject`.
// Wire it as a `commit-msg` husky hook:  npx --no-install commitlint --edit "$1"
// Note: commitlint only checks the MESSAGE — it is NOT the [Unreleased] gate (that is CI,
// see changelog-guard.yml). A well-formed message can still forget the changelog.
//
// German subjects are fine (project convention); the TYPE PREFIX stays English.

/** @type {import('@commitlint/types').UserConfig} */
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Allowed types — same set the version-bump.mjs level derivation understands.
    'type-enum': [
      2,
      'always',
      [
        'feat', // new feature            → minor
        'fix', // bug fix                → patch
        'perf', // performance            → patch
        'docs', // documentation only
        'chore', // tooling / deps / config
        'refactor', // no feature / no fix
        'test', // tests only
        'style', // formatting only
        'ci', // CI / pipelines
        'build', // build system
        'revert', // revert a prior commit
      ],
    ],
    'type-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'header-max-length': [2, 'always', 100], // subject ≤ 100 chars
  },
};
