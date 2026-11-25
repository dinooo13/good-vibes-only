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

# Every SKILL.md opens with valid YAML frontmatter that has a description and a
# name matching its folder. Strict YAML parsing catches unquoted `: ` scalars
# that lenient parsers accept but strict ones (like T3 Code's Antigravity skill
# scanner) silently drop.
if python3 -c 'import yaml' >/dev/null 2>&1; then
  yaml_parser=python3
elif command -v ruby >/dev/null 2>&1; then
  yaml_parser=ruby
else
  err "need python3 (PyYAML) or ruby to validate SKILL.md YAML frontmatter"
  yaml_parser=none
fi

parse_frontmatter() {
  case "$yaml_parser" in
    python3)
      python3 - "$1" <<'PY'
import json, sys, yaml

lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
if not lines or lines[0] != "---" or "---" not in lines[1:]:
    sys.exit("no frontmatter between --- lines")
end = lines.index("---", 1)
try:
    data = yaml.safe_load("\n".join(lines[1:end]))
except yaml.YAMLError as exc:
    msg = getattr(exc, "problem", None) or str(exc).splitlines()[0]
    sys.exit(f"invalid YAML frontmatter: {msg}")
if not isinstance(data, dict):
    sys.exit("frontmatter must be a YAML mapping")
print(json.dumps({
    "name": data["name"] if isinstance(data.get("name"), str) else "",
    "description": data["description"] if isinstance(data.get("description"), str) else "",
}))
PY
      ;;
    ruby)
      ruby -ryaml -rjson - "$1" <<'RB'
lines = File.read(ARGV[0], encoding: "UTF-8").lines.map(&:chomp)
end_idx = lines[1..]&.index("---")
abort "no frontmatter between --- lines" unless lines[0] == "---" && end_idx
begin
  data = YAML.safe_load(lines[1, end_idx].join("\n"))
rescue Psych::Exception => exc
  abort "invalid YAML frontmatter: #{exc.message.lines.first.strip}"
end
abort "frontmatter must be a YAML mapping" unless data.is_a?(Hash)
puts JSON.generate({
  "name" => data["name"].is_a?(String) ? data["name"] : "",
  "description" => data["description"].is_a?(String) ? data["description"] : "",
})
RB
      ;;
    *)
      return 1
      ;;
  esac
}

skills=0
while IFS= read -r S; do
  skills=$((skills + 1))
  [ "$yaml_parser" = none ] && continue
  if ! fm_json=$(parse_frontmatter "$S" 2>&1); then
    err "$S: $fm_json"
    continue
  fi
  folder=$(basename "$(dirname "$S")")
  sdir=$(dirname "$S")
  name=$(jq -r '.name' <<< "$fm_json")
  [ -n "$name" ] || err "$S has no name"
  [ -z "$name" ] || [ "$name" = "$folder" ] || err "$S is named '$name' but lives in '$folder'"
  [ -z "$name" ] || { printf '%s\n' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' && [ "${#name}" -le 64 ]; } ||
    err "$S name '$name' must be lowercase kebab-case (<= 64 chars)"
  desc=$(jq -r '.description' <<< "$fm_json")
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
