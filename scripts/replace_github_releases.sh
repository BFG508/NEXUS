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

# tag|asset|title|notes
RELEASES=(
"astra-v0.1.0|ASTRA-v0.1.0.zip|ASTRA v0.1.0|Initial public release of ASTRA. Standalone project artifact; NEXUS integrations are maintained separately."
"beam-v0.1.0|BEAM-v0.1.0.zip|BEAM v0.1.0|Initial public release of BEAM. Standalone project artifact; NEXUS integrations are maintained separately."
"eden-v0.1.0|EDEN-v0.1.0-Stable-Prototype.zip|EDEN v0.1.0 — Stable Prototype|Historical EDEN Stable Prototype. Documentation is the prepared English edition; project behavior remains historical and standalone."
"eden-v0.2.0|EDEN-v0.2.0-Research-Prototype.zip|EDEN v0.2.0 — Research Prototype|Historical EDEN Research Prototype. Documentation is the prepared English edition; project behavior remains historical and standalone."
"eden-v0.3.0|EDEN-v0.3.0.zip|EDEN v0.3.0|EDEN research release with true LRU memory, stronger invasion/ESS diagnostics, uncertainty quantification, and ABM–replicator convergence tooling."
"semanticlogos-v0.1.0|SemanticLogos-v0.1.0.zip|SemanticLogos.jl v0.1.0 — Historical precursor|Historical precursor of ETHOS.jl, preserved as originally supplied."
"ethos-v0.1.1|ETHOS-v0.1.1.zip|ETHOS.jl v0.1.1 — Rebrand baseline|Historical ETHOS rebrand release, preserved as originally supplied."
"ethos-v0.2.0|ETHOS-v0.2.0.zip|ETHOS.jl v0.2.0 — Correctness baseline|Historical ETHOS correctness baseline, preserved as originally supplied."
"ethos-v1.0.0|ETHOS-v1.0.0.zip|ETHOS.jl v1.0.0 — Stable API baseline|Historical ETHOS stable API baseline, preserved as originally supplied."
"ethos-v1.1.0|ETHOS-v1.1.0.zip|ETHOS.jl v1.1.0|ETHOS release with rank-safe alignment, explicit comparisons, cross-language guards, stronger bootstrap inference, portable configuration, and improved reproducibility."
"gaia-v0.1.0|GAIA-v0.1.0.zip|GAIA v0.1.0|Initial public release of GAIA. Standalone project artifact; NEXUS integrations are maintained separately."
"levi-v0.1.0|LEVI-v0.1.0.zip|LEVI v0.1.0|Initial public release of LEVI. Standalone project artifact; NEXUS integrations are maintained separately."
"scale-v0.1.0|SCALE-v0.1.0.zip|SCALE v0.1.0|Initial public release of SCALE. Standalone project artifact; NEXUS integrations are maintained separately."
"spartan-v0.1.0|SPARTAN-v0.1.0.zip|SPARTAN v0.1.0|Initial public release of SPARTAN. Standalone project artifact; NEXUS integrations are maintained separately."
)

create_isolated_commit() {
  local asset="$1" tag="$2"
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
  commit="$(printf 'Standalone release tree for %s\n' "$tag" | git commit-tree "$tree")"
  rm -rf "$temp" "$index"
  printf '%s' "$commit"
}

for spec in "${RELEASES[@]}"; do
  IFS='|' read -r tag filename title notes <<< "$spec"
  asset="$ROOT/_release_assets/built/$filename"
  [[ -f "$asset" ]] || { echo "ERROR: missing $asset"; exit 1; }

  echo "== Replacing $tag =="
  if gh release view "$tag" >/dev/null 2>&1; then
    gh release delete "$tag" --cleanup-tag --yes
  fi
  git tag -d "$tag" >/dev/null 2>&1 || true
  if git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1; then
    git push origin ":refs/tags/$tag"
  fi

  commit="$(create_isolated_commit "$asset" "$tag")"
  git tag -a "$tag" "$commit" -m "$title"
  git push origin "refs/tags/$tag"
  gh release create "$tag" "$asset" --verify-tag --title "$title" --notes "$notes"
done

echo
echo "Published project-only releases:"
gh release list --limit 30
