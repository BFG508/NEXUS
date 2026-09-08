#!/usr/bin/env bash
# Replace NEXUS GitHub releases with project-only tags and assets.
# The synthetic tag commits contain ONLY the standalone project tree, so even
# GitHub's automatically generated Source code archives do not contain NEXUS
# integrations or sibling projects.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "${1:-}" != "--execute" ]]; then
  echo "Dry safety stop: this script DELETES and recreates GitHub releases/tags."
  echo "Run: bash scripts/replace_github_releases.sh --execute"
  exit 2
fi

[[ -z "$(git status --porcelain)" ]] || { echo "ERROR: working tree is not clean"; git status --short; exit 1; }
gh auth status >/dev/null
git fetch origin --tags
python3 scripts/build_release_assets.py all
python3 scripts/check_release_isolation.py

# Releases are declared from oldest to newest. Each synthetic standalone commit
# and annotated tag receives an explicit UTC timestamp on a different day. This
# keeps GitHub's release ordering aligned with the canonical NEXUS chronology
# even when all releases are recreated in one publishing session.
# sort_date|tag|asset|title|notes
RELEASES=(
"2026-08-26T12:00:00Z|beam-v0.1.0|BEAM-v0.1.0.zip|BEAM v0.1.0|Standalone BEAM v0.1.0 release. NEXUS integrations are maintained separately."
"2026-08-27T12:00:00Z|levi-v0.1.0|LEVI-v0.1.0.zip|LEVI v0.1.0|Standalone LEVI v0.1.0 release. NEXUS integrations are maintained separately."
"2026-08-28T12:00:00Z|spartan-v0.1.0|SPARTAN-v0.1.0.zip|SPARTAN v0.1.0|Standalone SPARTAN v0.1.0 release. NEXUS integrations are maintained separately."
"2026-08-29T12:00:00Z|gaia-v0.1.0|GAIA-v0.1.0.zip|GAIA v0.1.0|Standalone GAIA v0.1.0 release. NEXUS integrations are maintained separately."
"2026-08-30T12:00:00Z|scale-v0.1.0|SCALE-v0.1.0.zip|SCALE v0.1.0|Standalone SCALE v0.1.0 release. NEXUS integrations are maintained separately."
"2026-08-31T12:00:00Z|astra-v0.1.0|ASTRA-v0.1.0.zip|ASTRA v0.1.0|Standalone ASTRA v0.1.0 release. NEXUS integrations are maintained separately."
"2026-09-01T12:00:00Z|eden-v0.1.0|EDEN-v0.1.0.zip|EDEN v0.1.0|Standalone historical EDEN v0.1.0 release."
"2026-09-02T12:00:00Z|eden-v0.2.0|EDEN-v0.2.0.zip|EDEN v0.2.0|Standalone historical EDEN v0.2.0 release."
"2026-09-03T12:00:00Z|ethos-v0.1.0|ETHOS-v0.1.0.zip|ETHOS v0.1.0|Standalone historical ETHOS v0.1.0 release. The preserved archive payload is unchanged; only the outer asset filename is normalized."
"2026-09-04T12:00:00Z|ethos-v0.1.1|ETHOS-v0.1.1.zip|ETHOS v0.1.1|Standalone historical ETHOS v0.1.1 release."
"2026-09-05T12:00:00Z|ethos-v0.2.0|ETHOS-v0.2.0.zip|ETHOS v0.2.0|Standalone historical ETHOS v0.2.0 release."
"2026-09-06T12:00:00Z|ethos-v1.0.0|ETHOS-v1.0.0.zip|ETHOS v1.0.0|Standalone historical ETHOS v1.0.0 release."
"2026-09-07T12:00:00Z|eden-v0.3.0|EDEN-v0.3.0.zip|EDEN v0.3.0|EDEN release with true LRU memory, stronger invasion/ESS diagnostics, uncertainty quantification, and ABM-replicator convergence tooling."
"2026-09-08T12:00:00Z|ethos-v1.1.0|ETHOS-v1.1.0.zip|ETHOS v1.1.0|ETHOS release with rank-safe alignment, explicit comparisons, cross-language guards, stronger bootstrap inference, portable configuration, and improved reproducibility."
)

create_isolated_commit() {
  local asset="$1" tag="$2" sort_date="$3"
  local temp index worktree tree commit top_count top
  temp="$(mktemp -d)"
  index="$(mktemp)"
  rm -f "$index"
  unzip -q "$asset" -d "$temp"
  top_count="$(find "$temp" -mindepth 1 -maxdepth 1 -printf '%f\n' | wc -l)"
  [[ "$top_count" -eq 1 ]] || { echo "ERROR: $asset has multiple top-level entries"; rm -rf "$temp" "$index"; exit 1; }
  top="$(find "$temp" -mindepth 1 -maxdepth 1 -printf '%f\n')"
  worktree="$temp/$top"
  [[ -d "$worktree" ]] || { echo "ERROR: $asset top-level entry is not a directory"; rm -rf "$temp" "$index"; exit 1; }

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

echo "== Removing existing GitHub releases and their release tags =="
mapfile -t EXISTING_RELEASE_TAGS < <(
  gh release list --limit 100 --json tagName --jq '.[].tagName'
)
for old_tag in "${EXISTING_RELEASE_TAGS[@]}"; do
  [[ -n "$old_tag" ]] || continue
  echo "Removing existing release $old_tag"
  gh release delete "$old_tag" --cleanup-tag --yes
  git tag -d "$old_tag" >/dev/null 2>&1 || true
  if git ls-remote --exit-code --tags origin "refs/tags/$old_tag" >/dev/null 2>&1; then
    git push origin ":refs/tags/$old_tag"
  fi
done

for spec in "${RELEASES[@]}"; do
  IFS='|' read -r sort_date tag filename title notes <<< "$spec"
  asset="$ROOT/_release_assets/built/$filename"
  [[ -f "$asset" ]] || { echo "ERROR: missing $asset"; exit 1; }

  echo "== Publishing $tag =="
  git tag -d "$tag" >/dev/null 2>&1 || true
  if git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1; then
    git push origin ":refs/tags/$tag"
  fi

  commit="$(create_isolated_commit "$asset" "$tag" "$sort_date")"
  GIT_COMMITTER_DATE="$sort_date" git tag -a "$tag" "$commit" -m "$title"
  git push origin "refs/tags/$tag"
  gh release create "$tag" "$asset" --verify-tag --title "$title" --notes "$notes"
done

echo
echo "Published project-only releases:"
gh release list --limit 30
