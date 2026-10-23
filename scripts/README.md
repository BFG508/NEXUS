# Repository maintenance tools

These tools belong to the NEXUS repository and its CI. They are not included in standalone project releases.

| File | Purpose | Used by |
|---|---|---|
| `build_release_assets.py` | Build isolated project ZIPs and select preserved historical assets. | Publisher and integration CI. |
| `check_release_isolation.py` | Reject integration code, Git metadata and local assistant/cloud state in release ZIPs. | Publisher and integration CI. |
| `publish_github_releases.sh` | Publish new isolated releases with explicit commit/tag dates, preserving existing history. | Maintainers; see `docs/RELEASES.md`. |
| `replace_github_releases.sh` | Refuse the retired destructive publication command and direct users to the current publisher. | Compatibility guard for old commands. |
| `repo_preflight.py` | Check repository structure, versions, JSON and project boundaries. | Repository and integration CI. |
| `check_hermes_atlas.py` | Exercise successful/failed runs and malformed manifests using real HERMES and ATLAS executables on Linux. | Integration CI. |
| `tests/test_release_assets.py` | Regression tests for current/historical packaging and local-state exclusions. | Repository CI. |

Keep this directory versioned: removing it would break CI and the documented release process. Generated ZIPs and local runtime/assistant/cloud directories are excluded separately by the root `.gitignore` and release packager.
