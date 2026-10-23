# NEXUS release policy

NEXUS is a monorepo whose projects are versioned and released independently using Semantic Versioning. Every active project maintains a local `VERSION` file; release tags use a project prefix.

## Canonical release chronology

The established public release history is immutable and remains, from oldest to newest, in this exact order:

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

Build and verify all current assets (no historical ZIP inputs are needed):

```bash
python scripts/build_release_assets.py all
python scripts/check_release_isolation.py
```

The active project trees currently build AEGIS v0.1.0, ASTRA v0.1.0, ATLAS v0.1.0, BEAM v0.1.0, EDEN v0.3.0, ETHOS v1.1.0, GAIA v0.1.0, HERMES v0.1.0, LEVI v0.1.0, SCALE v0.1.0, and SPARTAN v0.1.0. HERMES v0.1.0, AEGIS v0.1.0, and ATLAS v0.1.0 are implemented and release-ready. None of the three belongs to the protected original 14-release history until published append-only.

Generated ZIPs live under `_release_assets/built/PROJECT/PROJECT-vVERSION.zip`, with only the current `VERSION` retained for each project. A successful build removes older generated ZIPs for that project. For example, EDEN builds to `_release_assets/built/EDEN/EDEN-v0.3.0.zip`.

Immutable historical EDEN and ETHOS ZIPs live separately under `_release_assets/historical/PROJECT/`. They are ignored by Git and are not required by `all`. The explicit commands `python scripts/build_release_assets.py EDEN --eden-historical 0.1.0` and `python scripts/build_release_assets.py ETHOS --ethos-historical 1.0.0` return the preserved archive path without adding it to `built/`.

For ETHOS v0.1.0, the preserved historical archive payload remains byte-for-byte unchanged. Only its outer release-asset filename is normalized to `ETHOS-v0.1.0.zip`.

## Append-only GitHub release publishing

GitHub automatically creates `Source code (zip)` and `Source code (tar.gz)` from the Git tree referenced by a release tag. Tagging a normal `main` commit would therefore expose the entire monorepo as the automatic source archive.

The established 14-release history is now protected. Current tooling **never deletes, retargets, or recreates those releases or their tags**.

Publish a new standalone release with:

```bash
bash scripts/publish_github_releases.sh --execute PROJECT[@UTC_DATE]
```

HERMES v0.1.0, AEGIS v0.1.0, and ATLAS v0.1.0 are the first three implemented projects intended after the protected history. If none has been published yet, preserve their chronology with:

```bash
bash scripts/publish_github_releases.sh --execute \
  HERMES@2026-09-09T12:00:00Z \
  AEGIS@2026-09-10T12:00:00Z \
  ATLAS@2026-09-11T12:00:00Z
```

If an earlier append-only release already exists, the publisher leaves it unchanged. The three implemented v0.1.0 platform/engineering releases can be published independently, but their explicit dates should preserve the intended chronology.

The publisher:

1. requires a clean working tree and authenticated GitHub CLI;
2. reads the selected project's current `VERSION`;
3. refuses to modify an existing remote tag;
4. skips a release that already exists;
5. builds and verifies the standalone project ZIP;
6. creates an orphan synthetic Git commit from that project tree only;
7. creates and pushes a new annotated project tag; and
8. creates the corresponding GitHub Release.

When several new releases need an intentional visual chronology, pass a different explicit UTC date with each project specification. If no date is supplied, the current UTC time is used.

`scripts/replace_github_releases.sh` remains only as a compatibility safety guard. It exits without modifying GitHub and directs maintainers to the append-only publisher.

Do not publish a new release until `main` is pushed and the relevant CI is green.

## HERMES v0.1.0 release line

HERMES v0.1.0 is the first append-only release planned after the protected 14-release history. Its standalone archive contains only the generic Go orchestrator and the root MIT license. The NEXUS smoke scenario and project-specific adapters remain under repository-level `integration/` and are intentionally excluded from the HERMES release asset.

The recommended chronology-preserving publication command is:

```bash
bash scripts/publish_github_releases.sh --execute HERMES@2026-09-09T12:00:00Z
```

## AEGIS v0.1.0 release line

AEGIS v0.1.0 is the second append-only project release planned after the protected history. Its standalone archive contains only the dependency-free Rust reliability engine and the root MIT license. NEXUS-specific mappings from tactical/communication state to reliability parameters remain under repository-level `integration/` and require an explicit policy.

The chronology-preserving publication command is:

```bash
bash scripts/publish_github_releases.sh --execute AEGIS@2026-09-10T12:00:00Z
```

## ATLAS v0.1.0 release line

ATLAS v0.1.0 is the third append-only project release planned after the protected history. Its standalone archive contains the dependency-free Swift core, CLI, macOS SwiftUI application sources, deterministic preview fixtures, tests, and documentation. It consumes `hermes.run_manifest.v1` as an execution/provenance contract and does not package repository-level scientific adapters.

The chronology-preserving publication command is:

```bash
bash scripts/publish_github_releases.sh --execute ATLAS@2026-09-11T12:00:00Z
```

## Historical lines

EDEN v0.1.0 and v0.2.0 are preserved historical artifacts and are published as `EDEN-v0.1.0.zip` and `EDEN-v0.2.0.zip`. ETHOS v0.1.0, v0.1.1, v0.2.0, and v1.0.0 are also preserved historical artifacts. Historical payloads are not rebuilt from the active development directories.

## Release checklist

Before publishing a new release:

1. confirm the project `VERSION`, tag, README, and changelog agree;
2. require the project's native CI to pass;
3. require repository and integration CI to pass where the project participates in a contract;
4. build the release asset;
5. run `scripts/check_release_isolation.py`;
6. inspect the ZIP and, when the runtime is available, execute its clean-start test/example;
7. record SHA-256 for the asset if distributing it outside GitHub; and
8. only then create the new GitHub release; never rewrite an established release tag.


## Canonical release chronology and GitHub ordering

The protected 14-release history already carries explicit UTC dates on its isolated synthetic commits and annotated tags, from 2026-08-26 through 2026-09-08. Those dates are now historical metadata and current tooling does not alter them. Future releases append to this history; when ordering matters, assign explicit UTC dates when publishing.
