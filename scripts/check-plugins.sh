#!/bin/bash
# Checks the marketplace, the plugin manifests and the skills' frontmatter.
# Offline and quick; CI runs it, and so can you before a push.
#
# Usage: scripts/check-plugins.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 2
fail=0
err() { fail=1; echo "FAIL $*"; }

# Every JSON file in the repo parses.
while IFS= read -r f; do
  jq empty "$f" 2>/dev/null || err "$f is not valid JSON"
done < <(git ls-files '*.json')

# The marketplace names itself and lists plugins whose folders hold a matching plugin.json.
M=.claude-plugin/marketplace.json
jq -e '(.name | type == "string" and length > 0) and (.owner.name | type == "string" and length > 0)
       and (.plugins | type == "array" and length > 0)' "$M" >/dev/null 2>&1 ||
  err "$M needs name, owner.name and a non-empty plugins array"
listed=()
while IFS=$'\t' read -r name src; do
  [ -n "$name" ] || { err "$M has a plugin without a name"; continue; }
  [ -n "$src" ] || continue   # a remote source (github, url): nothing local to check
  listed+=("${src#./}")
  P=$src/.claude-plugin/plugin.json
  [ -f "$P" ] || { err "$M lists $name at $src, which has no .claude-plugin/plugin.json"; continue; }
  pname=$(jq -r '.name // empty' "$P" 2>/dev/null)
  [ "$pname" = "$name" ] || err "$P is named '$pname', the marketplace calls it '$name'"
done < <(jq -r '.plugins[]? | [.name // "", (.source | if type == "string" then . else "" end)] | @tsv' "$M" 2>/dev/null)

# Every plugin has name, version and description, and the marketplace lists it.
for P in plugins/*/.claude-plugin/plugin.json; do
  jq -e 'all(.name, .version, .description; type == "string" and length > 0)' "$P" >/dev/null 2>&1 ||
    err "$P needs name, version and description"
  dir=${P%/.claude-plugin/plugin.json}
  printf '%s\n' "${listed[@]}" | grep -qxF "$dir" || err "$dir is not listed in $M"
done

# Every SKILL.md opens with frontmatter that has a description and a name matching its folder.
# value KEY FILE: the key's value in the frontmatter; for a block scalar (> or |), its first line.
value() {
  awk -v key="$1" '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    want { if ($0 ~ /^[ \t]+[^ \t]/) { sub(/^[ \t]+/, ""); print } exit }
    index($0, key ":") == 1 {
      v = substr($0, length(key) + 2); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      if (v ~ /^[>|][-+0-9]*$/) { want = 1; next }
      gsub(/^["'\'']|["'\'']$/, "", v); print v; exit
    }' "$2"
}
skills=0
while IFS= read -r S; do
  skills=$((skills + 1))
  [ "$(head -1 "$S")" = "---" ] && [ "$(sed 1d "$S" | grep -cx -- '---')" -ge 1 ] ||
    { err "$S has no frontmatter between --- lines"; continue; }
  folder=$(basename "$(dirname "$S")")
  name=$(value name "$S")
  [ -n "$name" ] || err "$S has no name"
  [ -z "$name" ] || [ "$name" = "$folder" ] || err "$S is named '$name' but lives in '$folder'"
  [ -n "$(value description "$S")" ] || err "$S has no description"
done < <(git ls-files 'plugins/*/SKILL.md')
[ "$skills" -gt 0 ] || err "no SKILL.md found"

[ "$fail" = 0 ] && echo "ok   marketplace, plugins and $skills skills"
exit "$fail"
