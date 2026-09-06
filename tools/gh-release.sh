#!/usr/bin/env bash
#
# gh-release.sh — Control Flex 版本发布脚本
#
# 用法:
#   tools/gh-release.sh <版本> [选项]
#
# 流程:
#   1) 必传版本参数（例如 0.8.8-beta1）
#   2) 从 docs/release/<版本>/release-notes.md 读取发布说明作为 release body
#   3) 从 artifacts/<版本>/ 收集 jar 产物
#   4) 用 jar 内嵌的 mod 版本号校验产物（Forge/NeoForge 读 META-INF/*.mods.toml；Fabric 读 fabric.mod.json）
#   5) 只把校验通过的 jar 上传到 GitHub release（tag = v<版本>）
#   6) 若该 tag 的 release 不存在，则自动用 release-notes.md 创建；已存在则直接上传
#
# 说明:
#   - 默认跳过 *-sources.jar（用 --include-sources 改为上传）
#   - 默认发布到 ControlFlexMC/control-flex（用 --repo 覆盖）
#   - 产物目录 /artifacts/ 已在 .gitignore 内，jar 不会被提交
set -euo pipefail

# ---------- 参数 ----------
VERSION=""
REPO="ControlFlexMC/control-flex"
TITLE=""
INCLUDE_SOURCES=0
DRAFT=0
PRERELEASE=0
DRY_RUN=0

usage() {
  cat >&2 <<'EOF'
用法: tools/gh-release.sh <版本> [选项]

参数:
  <版本>                必填。当前发布版本，例如 0.8.8-beta1

选项:
  --repo <owner/repo>   目标 GitHub 仓库 (默认: ControlFlexMC/control-flex)
  --title <标题>        release 标题 (默认: <版本>)
  --include-sources     同时上传 *-sources.jar (默认跳过)
  --draft               以草稿方式创建 release
  --prerelease          标记为 prerelease
  --dry-run             只打印将要执行的动作，不真正调用 gh
  -h, --help            显示本帮助
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
    -*)            echo "未知选项: $1" >&2; usage; exit 2 ;;
    *)             POSITIONALS+=("$1"); shift ;;
  esac
done

if [ "${#POSITIONALS[@]}" -eq 0 ]; then
  echo "错误: 缺少版本参数。" >&2
  usage >&2
  exit 1
fi
VERSION="${POSITIONALS[0]}"

# ---------- 路径 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NOTES="$ROOT/docs/release/$VERSION/release-notes.md"
ART_DIR="$ROOT/artifacts/$VERSION"
TAG="v$VERSION"
[ -z "$TITLE" ] && TITLE="$VERSION"

if [ ! -f "$NOTES" ]; then
  echo "错误: 找不到发布说明: $NOTES" >&2
  exit 1
fi
if [ ! -d "$ART_DIR" ]; then
  echo "错误: 找不到产物目录: $ART_DIR" >&2
  exit 1
fi

# ---------- 从 jar 内嵌元数据读取 mod 版本 ----------
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

# ---------- 收集并校验产物 ----------
shopt -s nullglob
ALL_JARS=( "$ART_DIR"/*.jar )
shopt -u nullglob

if [ "${#ALL_JARS[@]}" -eq 0 ]; then
  echo "错误: 产物目录中没有 jar 文件: $ART_DIR" >&2
  exit 1
fi

VALID_JARS=()
SKIPPED=()
REJECTED=()
for jar in "${ALL_JARS[@]}"; do
  base="$(basename "$jar")"
  if [[ "$base" == *-sources.jar ]]; then
    if [ "$INCLUDE_SOURCES" -eq 1 ]; then
      : # 作为普通候选继续校验
    else
      SKIPPED+=("$base")
      continue
    fi
  fi
  embedded="$(extract_jar_version "$jar")"
  if [ -z "$embedded" ]; then
    REJECTED+=("$base (无法读取内嵌版本)")
  elif [ "$embedded" != "$VERSION" ]; then
    REJECTED+=("$base (内嵌版本 $embedded != $VERSION)")
  else
    VALID_JARS+=("$jar")
  fi
done

# ---------- 打印校验结果 ----------
echo "版本: $VERSION"
echo "仓库: $REPO"
echo "Tag : $TAG"
echo "产物来源: $ART_DIR"
echo
echo "通过校验 (${#VALID_JARS[@]}):"
if [ "${#VALID_JARS[@]}" -gt 0 ]; then
  for j in "${VALID_JARS[@]}"; do echo "  + $(basename "$j")"; done
fi
if [ "${#SKIPPED[@]}" -gt 0 ]; then
  echo "跳过 sources (${#SKIPPED[@]}):"
  for s in "${SKIPPED[@]}"; do echo "  - $s"; done
fi
if [ "${#REJECTED[@]}" -gt 0 ]; then
  echo "未通过校验 (${#REJECTED[@]}):"
  for r in "${REJECTED[@]}"; do echo "  x $r"; done
fi
echo

if [ "${#VALID_JARS[@]}" -eq 0 ]; then
  echo "错误: 没有通过校验的 jar，中止。" >&2
  exit 1
fi

# ---------- gh 发布 ----------
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
  echo "[dry-run] 将执行以下命令上传产物到 $REPO:"
  echo "  gh release create $TAG --repo $REPO --title \"$TITLE\" --notes-file \"$NOTES\" ${VALID_JARS[*]}"
  echo "  (若该 tag 的 release 已存在，则改为: gh release upload $TAG --repo $REPO <files>)"
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "警告: gh 未通过认证 (请先运行 'gh auth login')，后续命令可能失败。" >&2
fi

EXTRA=()
[ "$DRAFT" -eq 1 ] && EXTRA+=(--draft)
[ "$PRERELEASE" -eq 1 ] && EXTRA+=(--prerelease)

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "release $TAG 已存在，直接上传产物 ..."
  run gh release upload "$TAG" --repo "$REPO" "${VALID_JARS[@]}"
else
  echo "release $TAG 不存在，创建并上传产物 ..."
  run gh release create "$TAG" --repo "$REPO" --title "$TITLE" --notes-file "$NOTES" "${EXTRA[@]+"${EXTRA[@]}"}" "${VALID_JARS[@]}"
fi

echo
echo "完成: $REPO 的 $TAG 已上传 ${#VALID_JARS[@]} 个产物。"
