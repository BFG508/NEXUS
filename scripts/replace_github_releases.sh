#!/usr/bin/env bash
# Destructive release replacement is intentionally disabled.
#
# The canonical NEXUS history has already been established. Public releases
# and their isolated tags are now append-only. This compatibility script exists
# only to prevent an old command from accidentally deleting that history.
set -euo pipefail

cat <<'EOF'
ERROR: destructive GitHub release replacement is disabled.

The established NEXUS release history is protected and must not be deleted or
recreated. Publish new standalone project releases with:

  bash scripts/publish_github_releases.sh --execute PROJECT[@UTC_DATE] [...]

Example:

  bash scripts/publish_github_releases.sh --execute AEGIS@2026-09-09T12:00:00Z

No GitHub release or tag has been modified.
EOF
exit 2
