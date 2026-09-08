# NEXUS release policy

NEXUS is a monorepo whose projects are versioned and released independently using Semantic Versioning. Every active project maintains a local `VERSION` file; release tags use a project prefix.

## Canonical release chronology

The public release history is recreated from oldest to newest in this exact order:

```text
beam-v0.1.0
levi-v0.1.0
spartan-v0.1.0
gaia-v0.1.0
scale-v0.1.0
astra-v0.1.0
eden-v0.1.0
eden-v0.2.0
ethos-v0.1.0
ethos-v0.1.1
ethos-v0.2.0
ethos-v1.0.0
eden-v0.3.0
ethos-v1.1.0
```

The corresponding GitHub Release titles are exactly:

```text
BEAM v0.1.0
LEVI v0.1.0
SPARTAN v0.1.0
GAIA v0.1.0
SCALE v0.1.0
ASTRA v0.1.0
EDEN v0.1.0
EDEN v0.2.0
ETHOS v0.1.0
ETHOS v0.1.1
ETHOS v0.2.0
ETHOS v1.0.0
EDEN v0.3.0
ETHOS v1.1.0
```

No descriptive suffix is appended to a release title.

## Standalone artifact rule

A project release contains only that project plus a copy of the root MIT license. Integration code, sibling projects, monorepo workflows, local datasets, generated results, and repository tooling are excluded.

Build and verify all assets:

```bash
python scripts/build_release_assets.py all
python scripts/check_release_isolation.py
```

The active project trees build ASTRA v0.1.0, BEAM v0.1.0, EDEN v0.3.0, ETHOS v1.1.0, GAIA v0.1.0, LEVI v0.1.0, SCALE v0.1.0, and SPARTAN v0.1.0. Historical EDEN and ETHOS releases are copied from preserved immutable ZIP inputs.

For ETHOS v0.1.0, the preserved historical archive payload remains byte-for-byte unchanged. Only its outer release-asset filename is normalized to `ETHOS-v0.1.0.zip`.

## Why normal monorepo tags are not sufficient

GitHub automatically creates `Source code (zip)` and `Source code (tar.gz)` from the Git tree referenced by a release tag. If a normal `main` commit is tagged, those automatic archives contain the whole NEXUS monorepo even when the attached custom ZIP is project-only.

NEXUS therefore provides:

```bash
bash scripts/replace_github_releases.sh --execute
```

The script is destructive by design. It:

1. requires a clean working tree and authenticated GitHub CLI;
2. rebuilds and verifies all standalone assets;
3. removes the repository's existing GitHub releases and their associated release tags;
4. creates an orphan synthetic Git commit from each standalone project tree only;
5. tags and pushes that isolated tree in canonical chronological order; and
6. recreates each GitHub Release with the verified standalone ZIP attached.

A short delay between creations keeps the publication timestamps unambiguous. As a result, both the attached artifact and GitHub's automatic source archives are project-only, and the release feed reflects the canonical chronology.

Do not run the replacement script until `main` is pushed and all relevant CI is green.

## Historical lines

EDEN v0.1.0 and v0.2.0 are preserved historical artifacts and are published as `EDEN-v0.1.0.zip` and `EDEN-v0.2.0.zip`. ETHOS v0.1.0, v0.1.1, v0.2.0, and v1.0.0 are also preserved historical artifacts. Historical payloads are not rebuilt from the active development directories.

## Release checklist

Before publishing or replacing a release:

1. confirm the project `VERSION`, tag, README, and changelog agree;
2. require the project's native CI to pass;
3. require repository and integration CI to pass where the project participates in a contract;
4. build the release asset;
5. run `scripts/check_release_isolation.py`;
6. inspect the ZIP and, when the runtime is available, execute its clean-start test/example;
7. record SHA-256 for the asset if distributing it outside GitHub; and
8. only then create or replace the GitHub release.


## Canonical release chronology and GitHub ordering

The release replacement script assigns explicit UTC dates to the synthetic
standalone commits and annotated tags, one day per release, from 2026-08-26
through 2026-09-08. These dates encode the canonical oldest-to-newest NEXUS
release sequence and are intentionally independent of the day on which the
GitHub releases are recreated.

