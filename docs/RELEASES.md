# NEXUS release policy

NEXUS is a monorepo whose projects are versioned and released independently using Semantic Versioning. Every active project maintains a local `VERSION` file; release tags use a project prefix.

## Release tags

```text
astra-v0.1.0
beam-v0.1.0
eden-v0.1.0
eden-v0.2.0
eden-v0.3.0
semanticlogos-v0.1.0
ethos-v0.1.1
ethos-v0.2.0
ethos-v1.0.0
ethos-v1.1.0
gaia-v0.1.0
levi-v0.1.0
scale-v0.1.0
spartan-v0.1.0
```

SemanticLogos is the historical precursor of ETHOS rather than a ninth active NEXUS project.

## Standalone artifact rule

A project release contains only that project plus a copy of the root MIT license. Integration code, sibling projects, monorepo workflows, local datasets, generated results, and repository tooling are excluded.

Build and verify all assets:

```bash
python scripts/build_release_assets.py all
python scripts/check_release_isolation.py
```

The active project trees build ASTRA v0.1.0, BEAM v0.1.0, EDEN v0.3.0, ETHOS v1.1.0, GAIA v0.1.0, LEVI v0.1.0, SCALE v0.1.0, and SPARTAN v0.1.0. Historical EDEN and ETHOS/SemanticLogos releases are copied from preserved immutable ZIP inputs.

## Why normal monorepo tags are not sufficient

GitHub automatically creates `Source code (zip)` and `Source code (tar.gz)` from the Git tree referenced by a release tag. If a normal `main` commit is tagged, those automatic archives contain the whole NEXUS monorepo even when the attached custom ZIP is project-only.

NEXUS therefore provides:

```bash
bash scripts/replace_github_releases.sh --execute
```

The script is destructive by design. It:

1. requires a clean working tree and authenticated GitHub CLI;
2. rebuilds and verifies all standalone assets;
3. deletes an existing release/tag with the same name when present;
4. creates an orphan synthetic Git commit from the standalone project tree only;
5. tags and pushes that isolated tree; and
6. recreates the GitHub Release with the verified standalone ZIP attached.

As a result, both the attached artifact and GitHub's automatic source archives are project-only.

Do not run the replacement script until `main` is pushed and all relevant CI is green.

## Historical lines

EDEN v0.1.0 and v0.2.0 are preserved historical artifacts. ETHOS history preserves SemanticLogos v0.1.0, ETHOS v0.1.1, v0.2.0, and v1.0.0. Those artifacts are not rebuilt from the active development directories.

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
