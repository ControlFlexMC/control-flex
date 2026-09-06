#!/usr/bin/env bash
#
# gh-release.sh — Control Flex release publishing script
#
# Usage:
#   tools/gh-release.sh <version> [options]
#
# Flow:
#   1) Requires a version argument (e.g. 0.8.8-beta1)
#   2) Reads the release notes from docs/release/<version>/release-notes.md as the release body
#   3) Collects jar artifacts from artifacts/<version>/
#   4) Validates each artifact by the mod version embedded in the jar (Forge/NeoForge: META-INF/*.mods.toml; Fabric: fabric.mod.json)
#   5) Uploads only the validated jars to the GitHub release (tag = v<version>)
#   6) If the release for that tag does not exist, creates it using release-notes.md; otherwise uploads directly
#
# Notes:
#   - Skips *-sources.jar by default (use --include-sources to upload them)
#   - Defaults to ControlFlexMC/control-flex (override with --repo)
#   - The /artifacts/ dir is in .gitignore, so jars are never committed
set -euo pipefail

# ---------- Arguments ----------
VERSION=""
REPO="ControlFlexMC/control-flex"
TITLE=""
INCLUDE_SOURCES=0
DRAFT=0
PRERELEASE=0
DRY_RUN=0

usage() {
  cat >&2 <<'EOF'
Usage: tools/gh-release.sh <version> [options]

Arguments:
  <version>              Required. The release version, e.g. 0.8.8-beta1

Options:
  --repo <owner/repo>    Target GitHub repo (default: ControlFlexMC/control-flex)
  --title <title>        Release title (default: <version>)
  --include-sources      Also upload *-sources.jar (default: skip)
  --draft                Create the release as a draft
  --prerelease           Mark the release as a prerelease
  --dry-run              Print the actions instead of calling gh
  -h, --help             Show this help
EOF
}

POSITIONALS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --repo)        REPO="$2"; shift 2 ;;
    --title)       TITLE="$2"; shift 2 ;;
    --include-sources) INCLUDE_SOURCES=1; shift ;;
    --draft)       DRAFT=1; shift ;;
    --prerelease)  PRERELEASE=1; shift ;;
    --dry-run)     DRY_RUN=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    --)            shift; POSITIONALS+=("$@"); break ;;
    -*)            echo "Unknown option: $1" >&2; usage; exit 2 ;;
    *)             POSITIONALS+=("$1"); shift ;;
  esac
done

if [ "${#POSITIONALS[@]}" -eq 0 ]; then
  echo "Error: missing version argument." >&2
  usage >&2
  exit 1
fi
VERSION="${POSITIONALS[0]}"

# ---------- Paths ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NOTES="$ROOT/docs/release/$VERSION/release-notes.md"
ART_DIR="$ROOT/artifacts/$VERSION"
TAG="v$VERSION"
[ -z "$TITLE" ] && TITLE="$VERSION"

if [ ! -f "$NOTES" ]; then
  echo "Error: release notes not found: $NOTES" >&2
  exit 1
fi
if [ ! -d "$ART_DIR" ]; then
  echo "Error: artifacts directory not found: $ART_DIR" >&2
  exit 1
fi

# ---------- Read mod version from jar embedded metadata ----------
extract_jar_version() {
  local jar="$1" ver="" entries=""
  # Capture the entry list once.  Note: we must NOT pipe `unzip -Z1 | grep -q`
  # under pipefail — grep -q closes the pipe early and unzip gets SIGPIPE (141),
  # making the pipeline report failure even on a match.
  entries="$(unzip -Z1 "$jar" 2>/dev/null || true)"
  if grep -qx 'META-INF/neoforge.mods.toml' <<<"$entries"; then
    ver="$(unzip -p "$jar" META-INF/neoforge.mods.toml 2>/dev/null | awk '
      /^[[:space:]]*\[\[mods\]\]/ {inmods=1; next}
      /^\[\[/         {if (inmods) exit}
      inmods && /^[[:space:]]*version[[:space:]]*=/ {sub(/^[[:space:]]*version[[:space:]]*=[[:space:]]*/, ""); gsub(/"/, ""); gsub(/[[:space:]]/, ""); print; exit}' || true)"
  elif grep -qx 'META-INF/mods.toml' <<<"$entries"; then
    ver="$(unzip -p "$jar" META-INF/mods.toml 2>/dev/null | awk '
      /^[[:space:]]*\[\[mods\]\]/ {inmods=1; next}
      /^\[\[/         {if (inmods) exit}
      inmods && /^[[:space:]]*version[[:space:]]*=/ {sub(/^[[:space:]]*version[[:space:]]*=[[:space:]]*/, ""); gsub(/"/, ""); gsub(/[[:space:]]/, ""); print; exit}' || true)"
  elif grep -qx 'fabric.mod.json' <<<"$entries"; then
    ver="$(unzip -p "$jar" fabric.mod.json 2>/dev/null | jq -r '.version // empty' 2>/dev/null || true)"
  fi
  printf '%s' "$ver"
}

# ---------- Collect and validate artifacts ----------
shopt -s nullglob
ALL_JARS=( "$ART_DIR"/*.jar )
shopt -u nullglob

if [ "${#ALL_JARS[@]}" -eq 0 ]; then
  echo "Error: no jar files in artifacts directory: $ART_DIR" >&2
  exit 1
fi

VALID_JARS=()
SKIPPED=()
REJECTED=()
for jar in "${ALL_JARS[@]}"; do
  base="$(basename "$jar")"
  if [[ "$base" == *-sources.jar ]]; then
    if [ "$INCLUDE_SOURCES" -eq 1 ]; then
      : # validate as a normal candidate
    else
      SKIPPED+=("$base")
      continue
    fi
  fi
  embedded="$(extract_jar_version "$jar")"
  if [ -z "$embedded" ]; then
    REJECTED+=("$base (could not read embedded version)")
  elif [ "$embedded" != "$VERSION" ]; then
    REJECTED+=("$base (embedded version $embedded != $VERSION)")
  else
    VALID_JARS+=("$jar")
  fi
done

# ---------- Print validation results ----------
echo "Version: $VERSION"
echo "Repo: $REPO"
echo "Tag : $TAG"
echo "Artifacts dir: $ART_DIR"
echo
echo "Validated (${#VALID_JARS[@]}):"
if [ "${#VALID_JARS[@]}" -gt 0 ]; then
  for j in "${VALID_JARS[@]}"; do echo "  + $(basename "$j")"; done
fi
if [ "${#SKIPPED[@]}" -gt 0 ]; then
  echo "Skipped sources (${#SKIPPED[@]}):"
  for s in "${SKIPPED[@]}"; do echo "  - $s"; done
fi
if [ "${#REJECTED[@]}" -gt 0 ]; then
  echo "Rejected (${#REJECTED[@]}):"
  for r in "${REJECTED[@]}"; do echo "  x $r"; done
fi
echo

if [ "${#VALID_JARS[@]}" -eq 0 ]; then
  echo "Error: no jar passed validation, aborting." >&2
  exit 1
fi

# ---------- gh release ----------
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] %q' "$1"
    shift
    for a in "$@"; do printf ' %q' "$a"; done
    echo
  else
    "$@"
  fi
}

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[dry-run] would upload artifacts to $REPO with:"
  echo "  gh release create $TAG --repo $REPO --title \"$TITLE\" --notes-file \"$NOTES\" ${VALID_JARS[*]}"
  echo "  (if a release for $TAG already exists, this becomes: gh release upload $TAG --repo $REPO <files>)"
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Warning: gh is not authenticated (run 'gh auth login'); subsequent commands may fail." >&2
fi

EXTRA=()
[ "$DRAFT" -eq 1 ] && EXTRA+=(--draft)
[ "$PRERELEASE" -eq 1 ] && EXTRA+=(--prerelease)

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "release $TAG already exists, uploading artifacts ..."
  run gh release upload "$TAG" --repo "$REPO" "${VALID_JARS[@]}"
else
  echo "release $TAG does not exist, creating and uploading ..."
  run gh release create "$TAG" --repo "$REPO" --title "$TITLE" --notes-file "$NOTES" "${EXTRA[@]+"${EXTRA[@]}"}" "${VALID_JARS[@]}"
fi

echo
echo "Done: uploaded ${#VALID_JARS[@]} artifacts to $REPO/$TAG."
