#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT

fish_bin=$(command -v fish)
bash_bin=$(command -v bash)

mkdir -p \
  "$test_home/.config" \
  "$test_home/.config/shell" \
  "$test_home/.local/bin" \
  "$test_home/bin" \
  "$test_home/.cargo/bin"
ln -s "$repo_root/fish" "$test_home/.config/fish"
ln -s "$repo_root/shellrc/environment" "$test_home/.config/shell/environment"
ln -s "$repo_root/shellrc/profile" "$test_home/.profile"
ln -s "$repo_root/shellrc/bashrc" "$test_home/.bashrc"
printf 'set -gx SHELL_LOCAL_MARKER loaded\n' > "$test_home/.config/local_config.fish"


fail() {
  printf 'shell startup test: %s\n' "$1" >&2
  exit 1
}

assert_equal() {
  local expected=$1
  local actual=$2
  local label=$3
  [[ $actual == "$expected" ]] || fail "$label: expected '$expected', got '$actual'"
}

assert_path() {
  local actual=$1
  local label=$2
  local entry
  local managed_count
  local system_path_found=0
  local -a entries

  IFS=':' read -r -a entries <<< "$actual"
  [[ ${entries[0]:-} == "$test_home/.local/bin" ]] || fail "$label: ~/.local/bin is not first in '$actual'"
  [[ ${entries[1]:-} == "$test_home/bin" ]] || fail "$label: ~/bin is not second in '$actual'"
  [[ ${entries[2]:-} == "$test_home/.cargo/bin" ]] || fail "$label: ~/.cargo/bin is not third in '$actual'"

  for managed in "$test_home/.local/bin" "$test_home/bin" "$test_home/.cargo/bin"; do
    managed_count=0
    for entry in "${entries[@]}"; do
      [[ $entry == "$managed" ]] && ((managed_count += 1))
    done
    [[ $managed_count == 1 ]] || fail "$label: '$managed' occurs $managed_count times in '$actual'"
  done

  for entry in "${entries[@]}"; do
    [[ $entry == /usr/bin ]] && system_path_found=1
  done
  [[ $system_path_found == 1 ]] || fail "$label: /usr/bin is missing from '$actual'"
}

clean_env=(
  env -i
  "HOME=$test_home"
  "USER=${USER:-test}"
  "XDG_CONFIG_HOME=$test_home/.config"
  "MISE_FISH_AUTO_ACTIVATE=0"
  "PATH=/usr/bin"
)

sh_path=$("${clean_env[@]}" /bin/sh -c '. "$HOME/.profile"; printf %s "$PATH"')
assert_path "$sh_path" '/bin/sh profile PATH'

bash_output=$("${clean_env[@]}" "$bash_bin" --noprofile --norc -ic \
  '. "$HOME/.profile"; printf "%s|%s|" "$PATH" "$EDITOR"; alias ll >/dev/null; printf alias-loaded' \
  2>"$test_home/bash.stderr")
IFS='|' read -r bash_path bash_editor bash_alias <<< "$bash_output"
assert_path "$bash_path" 'interactive Bash login PATH'
assert_equal nvim "$bash_editor" 'interactive Bash login EDITOR'
assert_equal alias-loaded "$bash_alias" 'interactive Bash configuration'

fish_stderr="$test_home/fish.stderr"
fish_output=$("${clean_env[@]}" "$fish_bin" -c \
  'printf "%s|%s|%s" (string join : -- $PATH) "$EDITOR" "$SHELL_LOCAL_MARKER"' \
  2>"$fish_stderr")
[[ ! -s $fish_stderr ]] || fail "non-interactive Fish wrote to stderr: $(cat "$fish_stderr")"
IFS='|' read -r fish_path fish_editor fish_marker <<< "$fish_output"
assert_path "$fish_path" 'non-interactive Fish PATH'
assert_equal nvim "$fish_editor" 'non-interactive Fish EDITOR'
assert_equal loaded "$fish_marker" 'non-interactive Fish local config'

interactive_fish_output=$("${clean_env[@]}" "$fish_bin" -lic \
  'printf "%s|%s|%s|" (string join : -- $PATH) "$EDITOR" "$SHELL_LOCAL_MARKER"; type -q ll; and printf alias-loaded' \
  2>"$test_home/fish-interactive.stderr")
IFS='|' read -r interactive_fish_path interactive_fish_editor interactive_fish_marker interactive_fish_alias <<< "$interactive_fish_output"
assert_path "$interactive_fish_path" 'interactive Fish login PATH'
assert_equal nvim "$interactive_fish_editor" 'interactive Fish login EDITOR'
assert_equal loaded "$interactive_fish_marker" 'interactive Fish local config'
assert_equal alias-loaded "$interactive_fish_alias" 'interactive Fish configuration'

printf 'Shell startup tests: ok\n'
