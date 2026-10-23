#!/usr/bin/env bash
# Publish NEW project-only GitHub releases without deleting or rewriting history.
#
# Usage:
#   bash scripts/publish_github_releases.sh --execute PROJECT[@UTC_DATE] [...]
#
# Examples:
#   bash scripts/publish_github_releases.sh --execute AEGIS
#   bash scripts/publish_github_releases.sh --execute \
#     HERMES@2026-09-09T12:00:00Z \
#     AEGIS@2026-09-10T12:00:00Z \
#     ATLAS@2026-09-11T12:00:00Z
#
# Existing releases are immutable: if a GitHub release already exists, it is
# skipped; if only its remote tag exists, publication stops rather than deleting
# or retargeting the tag.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PROJECTS=(AEGIS ASTRA ATLAS BEAM EDEN ETHOS GAIA HERMES LEVI SCALE SPARTAN)

PROTECTED_TAGS=(
  ethos-v1.1.0
  eden-v0.3.0
  ethos-v1.0.0
  ethos-v0.2.0
  ethos-v0.1.1
  ethos-v0.1.0
  eden-v0.2.0
  eden-v0.1.0
  astra-v0.1.0
  scale-v0.1.0
  gaia-v0.1.0
  spartan-v0.1.0
  levi-v0.1.0
  beam-v0.1.0
)

usage() {
  cat <<'EOF'
Usage:
  bash scripts/publish_github_releases.sh --execute PROJECT[@UTC_DATE] [...]

PROJECT must be an active NEXUS project. UTC_DATE is optional and, when given,
must be an ISO-8601 Git date such as 2026-09-09T12:00:00Z. Supplying explicit
separate dates is recommended when several releases must have a defined visual
chronology on GitHub.

This script is append-only. It never deletes a GitHub release or remote tag.
EOF
}

if [[ "${1:-}" != "--execute" ]]; then
  usage
  exit 2
fi
shift

[[ "$#" -gt 0 ]] || { usage; exit 2; }
[[ -z "$(git status --porcelain)" ]] || {
  echo "ERROR: working tree is not clean"
  git status --short
  exit 1
}

gh auth status >/dev/null
git fetch origin --tags

is_project() {
  local candidate="$1" p
  for p in "${PROJECTS[@]}"; do
    [[ "$candidate" == "$p" ]] && return 0
  done
  return 1
}

is_protected_tag() {
  local candidate="$1" p
  for p in "${PROTECTED_TAGS[@]}"; do
    [[ "$candidate" == "$p" ]] && return 0
  done
  return 1
}

create_isolated_commit() {
  local asset="$1" tag="$2" sort_date="$3"
  local temp index worktree tree commit top_count top

  temp="$(mktemp -d)"
  index="$(mktemp)"
  rm -f "$index"

  unzip -q "$asset" -d "$temp"
  top_count="$(find "$temp" -mindepth 1 -maxdepth 1 -printf '%f\n' | wc -l)"
  [[ "$top_count" -eq 1 ]] || {
    echo "ERROR: $asset has multiple top-level entries"
    rm -rf "$temp" "$index"
    exit 1
  }

  top="$(find "$temp" -mindepth 1 -maxdepth 1 -printf '%f\n')"
  worktree="$temp/$top"
  [[ -d "$worktree" ]] || {
    echo "ERROR: $asset top-level entry is not a directory"
    rm -rf "$temp" "$index"
    exit 1
  }

  GIT_INDEX_FILE="$index" GIT_WORK_TREE="$worktree" git read-tree --empty
  GIT_INDEX_FILE="$index" GIT_WORK_TREE="$worktree" git add -A
  tree="$(GIT_INDEX_FILE="$index" git write-tree)"
  commit="$(
    printf 'Standalone release tree for %s\n' "$tag" |
      GIT_AUTHOR_DATE="$sort_date" \
      GIT_COMMITTER_DATE="$sort_date" \
      git commit-tree "$tree"
  )"

  rm -rf "$temp" "$index"
  printf '%s' "$commit"
}

for spec in "$@"; do
  if [[ "$spec" == *@* ]]; then
    project="${spec%%@*}"
    sort_date="${spec#*@}"
  else
    project="$spec"
    sort_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  fi

  is_project "$project" || {
    echo "ERROR: unknown project '$project'"
    printf 'Valid projects:'
    printf ' %s' "${PROJECTS[@]}"
    printf '\n'
    exit 1
  }

  version="$(tr -d '[:space:]' < "$ROOT/$project/VERSION")"
  [[ -n "$version" ]] || { echo "ERROR: empty VERSION for $project"; exit 1; }

  lower_project="$(printf '%s' "$project" | tr '[:upper:]' '[:lower:]')"
  tag="${lower_project}-v${version}"
  title="$project v$version"

  if is_protected_tag "$tag"; then
    echo "[PROTECTED] $tag belongs to the established NEXUS history; skipping."
    continue
  fi

  if gh release view "$tag" >/dev/null 2>&1; then
    echo "[EXISTS] GitHub release $tag already exists; leaving it unchanged."
    continue
  fi

  if git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1; then
    echo "ERROR: remote tag $tag already exists but no GitHub release was found."
    echo "Refusing to delete, retarget, or overwrite an existing tag."
    exit 1
  fi

  echo "== Building $project v$version =="
  python3 scripts/build_release_assets.py "$project"
  asset="$ROOT/_release_assets/built/${project}/${project}-v${version}.zip"
  [[ -f "$asset" ]] || { echo "ERROR: missing $asset"; exit 1; }
  python3 scripts/check_release_isolation.py "$asset"

  echo "== Publishing NEW release $tag =="
  commit="$(create_isolated_commit "$asset" "$tag" "$sort_date")"
  GIT_COMMITTER_DATE="$sort_date" git tag -a "$tag" "$commit" -m "$title"
  git push origin "refs/tags/$tag"

  notes="Standalone $title release. NEXUS integration code is maintained separately at repository level."
  gh release create "$tag" "$asset" --verify-tag --title "$title" --notes "$notes"
  echo "[OK] Published $title without modifying existing release history."
done
