#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
manifest="$repo_root/config/herdr/plugins"

duplicates=$(sort "$manifest" | uniq -d)
[ -z "$duplicates" ] || {
  printf 'Duplicate Herdr plugins:\n%s\n' "$duplicates" >&2
  exit 1
}

while IFS= read -r plugin; do
  case "$plugin" in
    ""|\#*) continue ;;
    */*) ;;
    *)
      printf 'Invalid Herdr plugin source: %s\n' "$plugin" >&2
      exit 1
      ;;
  esac
done <"$manifest"

printf 'Herdr plugin manifest tests: ok\n'
