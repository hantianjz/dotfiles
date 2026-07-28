#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
tmux_keys="$repo_root/tmux/tmux.keys.conf"
herdr_config="$repo_root/config/herdr/config.toml"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_config_has() {
  grep -Fq "\"$1\"" "$herdr_config" ||
    fail "Herdr is missing supported chord $1"
}

# Every personal prefix-table binding must remain explicitly classified. The
# unsupported list is intentional and documented; adding a tmux binding makes
# this audit fail until its Herdr disposition is decided.
actual_prefix_keys=$(
  awk '
    /^bind-key[[:space:]]/ && $0 !~ /[[:space:]]-T[[:space:]]/ {
      key = $2
      if (key == "-" || key !~ /^-/) print key
    }
  ' "$tmux_keys" | sort -u | tr '\n' ' '
)
expected_prefix_keys=', - . 0 : = C C-a C-h C-j C-k C-l C-o C-s C-v L R Z [ a h j k l m n p q r s v '
[ "$actual_prefix_keys" = "$expected_prefix_keys" ] ||
  fail "tmux prefix inventory changed: $actual_prefix_keys"

for chord in \
  prefix+d prefix+shift+r prefix+shift+s \
  prefix+shift+c prefix+p prefix+ctrl+p prefix+n prefix+ctrl+n \
  prefix+minus prefix+= prefix+shift+z prefix+[ prefix+a prefix+q \
  prefix+v prefix+ctrl+v prefix+s prefix+ctrl+s \
  prefix+h prefix+ctrl+h prefix+j prefix+ctrl+j \
  prefix+k prefix+ctrl+k prefix+l prefix+ctrl+l \
  ctrl+h ctrl+j ctrl+k ctrl+l \
  prefix+ctrl+o prefix+0 prefix+] prefix+shift+y prefix+b
do
  assert_config_has "$chord"
done

# Prefixed navigation remains native. Direct navigation must use the
# process-aware router so Neovim can consume the key before crossing an edge.
for binding in \
  'focus_pane_left = ["prefix+h", "prefix+ctrl+h"]' \
  'focus_pane_down = ["prefix+j", "prefix+ctrl+j"]' \
  'focus_pane_up = ["prefix+k", "prefix+ctrl+k"]' \
  'focus_pane_right = ["prefix+l", "prefix+ctrl+l"]'
do
  grep -Fqx "$binding" "$herdr_config" ||
    fail "Herdr native navigation binding changed: $binding"
done

for command in \
  'herdr-nvim-navigator\" left' \
  'herdr-nvim-navigator\" down' \
  'herdr-nvim-navigator\" up' \
  'herdr-nvim-navigator\" right'
do
  grep -Fq "$command" "$herdr_config" ||
    fail "Herdr process-aware navigation command is missing: $command"
done

# Double-prefix literal forwarding is built into Herdr. These tmux cases deliberately
# have no Herdr binding: command prompt, refresh, clear history, and layouts.
for unsupported in ': command-prompt' 'r refresh-client' 'L clear-history' \
  '. selectl' ', selectl' 'm selectl'
do
  grep -Fq "bind-key $unsupported" "$tmux_keys" ||
    fail "unsupported tmux classification went stale: $unsupported"
done

printf 'Herdr/tmux parity audit: ok\n'
