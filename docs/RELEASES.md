# NEXUS release policy

NEXUS is a monorepo whose projects are versioned and released independently. Each project maintains a repository-local `VERSION` file and uses Semantic Versioning for its own public behavior.

## Tag naming

Tags are prefixed with the project name:

```text
astra-v0.1.0
beam-v0.1.0
eden-v0.1.0
eden-v0.2.0
gaia-v0.1.0
levi-v0.1.0
scale-v0.1.0
spartan-v0.1.0
```

A `v1.0.0` tag is reserved for a project whose public behavior/interfaces are intentionally considered stable. A version increment in one project does not require version increments in sibling projects unless their own public behavior changes.

## Repository-wide files

NEXUS maintains one root `.gitignore` and one root MIT `LICENSE`. Project folders do not duplicate those files.

When a standalone project release ZIP is generated from the active tree, `scripts/build_release_assets.py` copies the global MIT license into that archive so the distributed artifact remains self-contained.

Generated ZIPs belong under `_release_assets/` and must not be committed to normal repository history.

## EDEN historical releases

EDEN v0.1.0 and v0.2.0 are preserved under `_release_assets/EDEN/` as English language-only editions of their historical release trees. Only documentation language was changed when those historical artifacts were prepared; code, file structure, versions, parameters, APIs, and behavior remain otherwise unchanged.

The active `EDEN/` directory is based on the v0.2.0 Research Prototype and may evolve independently toward a future release. Historical tags/releases must use the corresponding preserved artifacts rather than rebuilding those versions from the active development tree.

Build a historical EDEN asset with:

```bash
python scripts/build_release_assets.py EDEN --eden-historical 0.1.0
python scripts/build_release_assets.py EDEN --eden-historical 0.2.0
```

## Building release assets

Build a current project ZIP with:

```bash
python scripts/build_release_assets.py ASTRA
```

Build all currently prepared project assets with:

```bash
python scripts/build_release_assets.py all
```

The builder excludes local environments, runtime state, large local datasets, generated results, compiled artifacts, and other files identified as non-release state by the script.

## Project release checklist

For each project release:

1. Confirm the project `VERSION` and intended release tag match.
2. Run the project's GitHub Actions workflow and require a green result.
3. Confirm the project README describes implemented behavior only and documents material modelling limitations.
4. Confirm generated/local assets are absent from `git status` and are not staged.
5. Build the project ZIP with `python scripts/build_release_assets.py <PROJECT>`.
6. Inspect the ZIP contents and run the documented clean-start example where the runtime is available.
7. Create the prefixed Git tag, for example `beam-v0.1.0`.
8. Create the GitHub Release from that tag and attach the ZIP as a release asset only.
9. Do not commit the release ZIP to the normal repository tree.

For EDEN v0.1.0/v0.2.0, use the preserved historical artifacts with `--eden-historical` rather than rebuilding those versions from the active `EDEN/` tree.
