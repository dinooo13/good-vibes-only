#!/bin/bash
# Checks the marketplaces, the plugin manifests and the skills' frontmatter.
# Offline and quick; CI runs it, and so can you before a push.
#
# Usage: scripts/check-plugins.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 2
fail=0
err() { fail=1; echo "FAIL $*"; }

# Every tracked (or new non-ignored) JSON file in the repo parses.
while IFS= read -r f; do
  jq empty "$f" 2>/dev/null || err "$f is not valid JSON"
done < <(git ls-files --cached --others --exclude-standard '*.json')

# Claude marketplace: names itself and lists plugins with matching .claude-plugin/plugin.json.
CM=.claude-plugin/marketplace.json
jq -e '(.name | type == "string" and length > 0) and (.owner.name | type == "string" and length > 0)
       and (.plugins | type == "array" and length > 0)' "$CM" >/dev/null 2>&1 ||
  err "$CM needs name, owner.name and a non-empty plugins array"
claude_listed=()
while IFS=$'\x1f' read -r name src; do
  [ -n "$name" ] || { err "$CM has a plugin without a name"; continue; }
  [ -n "$src" ] || continue   # a remote source (github, url): nothing local to check
  claude_listed+=("${src#./}")
  P=$src/.claude-plugin/plugin.json
  [ -f "$P" ] || { err "$CM lists $name at $src, which has no .claude-plugin/plugin.json"; continue; }
  pname=$(jq -r '.name // empty' "$P" 2>/dev/null)
  [ "$pname" = "$name" ] || err "$P is named '$pname', $CM calls it '$name'"
done < <(jq -r '.plugins[]? | [.name // "", (.source | if type == "string" then . else "" end)] | join("\u001f")' "$CM" 2>/dev/null)

# Codex marketplace: names itself and lists local plugins with matching root plugin.json.
AM=.agents/plugins/marketplace.json
jq -e '(.name | type == "string" and length > 0) and (.plugins | type == "array" and length > 0)' "$AM" >/dev/null 2>&1 ||
  err "$AM needs name and a non-empty plugins array"
agents_listed=()
while IFS=$'\x1f' read -r name stype spath pinst pauth cat; do
  [ -n "$name" ] || { err "$AM has a plugin without a name"; continue; }
  [ -n "$pinst" ] && [ -n "$pauth" ] && [ -n "$cat" ] ||
    err "$AM plugin '$name' needs policy.installation, policy.authentication and category"
  [ "$stype" = "local" ] || continue
  case "$spath" in
    ./*) ;;
    *) err "$AM plugin '$name' source.path '$spath' must start with './'" ;;
  esac
  agents_listed+=("${spath#./}")
  P=$spath/plugin.json
  [ -f "$P" ] || { err "$AM lists $name at $spath, which has no plugin.json"; continue; }
  pname=$(jq -r '.name // empty' "$P" 2>/dev/null)
  [ "$pname" = "$name" ] || err "$P is named '$pname', $AM calls it '$name'"
done < <(jq -r '.plugins[]? | [
  .name // "",
  (.source | if type == "object" then .source // "" elif type == "string" then "local" else "" end),
  (.source | if type == "object" then .path // "" elif type == "string" then . else "" end),
  .policy.installation // "",
  .policy.authentication // "",
  .category // ""
] | join("\u001f")' "$AM" 2>/dev/null)

# Every plugin folder has both manifests, conforms to Agent Plugins 1.0.0, stays
# in sync across both manifests, and is listed in both marketplaces.
AGENT_PLUGINS_SCHEMA='https://agent-plugins.org/schemas/1.0.0/plugin.schema.json'
for dir in plugins/*/; do
  dir=${dir%/}
  CP=$dir/.claude-plugin/plugin.json
  UP=$dir/plugin.json
  [ -f "$CP" ] || { err "$dir has no .claude-plugin/plugin.json"; continue; }
  [ -f "$UP" ] || { err "$dir has no root plugin.json"; continue; }

  jq -e 'all(.name, .version, .description; type == "string" and length > 0)' "$CP" >/dev/null 2>&1 ||
    err "$CP needs name, version and description"

  jq -e --arg schema "$AGENT_PLUGINS_SCHEMA" '
    .["$schema"] == $schema
    and (.name | type == "string" and test("^[a-z0-9]+(-[a-z0-9]+)*$") and length <= 64)
    and all(.version, .description; type == "string" and length > 0)
    and ((keys - ["$schema","name","version","description","author","homepage","repository","license","keywords","extensions"]) | length == 0)
    and ((has("author") | not) or (.author | type == "object" and ((keys - ["name","email","url"]) | length == 0)))
    and ((has("extensions") | not) or (.extensions | type == "object" and all(.[]; type == "object")))
  ' "$UP" >/dev/null 2>&1 ||
    err "$UP does not conform to Agent Plugins 1.0.0 manifest rules"

  for field in name version description; do
    cv=$(jq -r --arg f "$field" '.[$f] // ""' "$CP" 2>/dev/null)
    uv=$(jq -r --arg f "$field" '.[$f] // ""' "$UP" 2>/dev/null)
    [ "$cv" = "$uv" ] || err "$UP and $CP disagree on $field ('$uv' vs '$cv')"
  done

  printf '%s\n' "${claude_listed[@]}" | grep -qxF "$dir" || err "$dir is not listed in $CM"
  printf '%s\n' "${agents_listed[@]}" | grep -qxF "$dir" || err "$dir is not listed in $AM"
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
  sdir=$(dirname "$S")
  name=$(value name "$S")
  [ -n "$name" ] || err "$S has no name"
  [ -z "$name" ] || [ "$name" = "$folder" ] || err "$S is named '$name' but lives in '$folder'"
  [ -z "$name" ] || { printf '%s\n' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' && [ "${#name}" -le 64 ]; } ||
    err "$S name '$name' must be lowercase kebab-case (<= 64 chars)"
  desc=$(value description "$S")
  [ -n "$desc" ] || err "$S has no description"
  [ "${#desc}" -le 1024 ] || err "$S description exceeds 1024 chars (${#desc})"
  [ -f "$sdir/README.md" ] || err "$sdir has no README.md"
  while IFS= read -r target; do
    path=${target%%#*}
    [ -n "$path" ] || continue
    case "$path" in http://*|https://*|mailto:*|/*) continue ;; esac
    [ -e "$sdir/$path" ] || err "$S links to missing '$path'"
  done < <(awk '
    /^```/ { code = !code; next }
    code { next }
    {
      line = $0
      while (match(line, /\[[^][]+\]\([^() \t]+\)/)) {
        m = substr(line, RSTART, RLENGTH)
        sub(/^\[[^][]+\]\(/, "", m)
        sub(/\)$/, "", m)
        print m
        line = substr(line, RSTART + RLENGTH)
      }
    }' "$S")
done < <(git ls-files --cached --others --exclude-standard 'plugins/*/SKILL.md')
[ "$skills" -gt 0 ] || err "no SKILL.md found"

[ "$fail" = 0 ] && echo "ok   marketplaces, plugins and $skills skills"
exit "$fail"
