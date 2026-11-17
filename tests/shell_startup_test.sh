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
  "$test_home/.cargo/bin" \
  "$test_home/.bun/bin"
ln -s "$repo_root/fish" "$test_home/.config/fish"
ln -s "$repo_root/shellrc/environment" "$test_home/.config/shell/environment"
ln -s "$repo_root/shellrc/profile" "$test_home/.profile"
ln -s "$repo_root/shellrc/bashrc" "$test_home/.bashrc"
printf 'set -gx SHELL_LOCAL_MARKER loaded\n' > "$test_home/.config/local_config.fish"
hook_root="$test_home/.config/herdr/plugins/github-installations/herdr-automatic-rename-fixture/active/checkout"
old_root="$test_home/.config/herdr/plugins/github-installations/herdr-automatic-rename-fixture/obsolete/checkout"
mkdir -p "$hook_root/shell" "$old_root/shell"
printf 'set -gx HERDR_HOOK_MARKER registered\n' > "$hook_root/shell/hook.fish"
printf 'set -gx HERDR_HOOK_MARKER obsolete\n' > "$old_root/shell/hook.fish"
jq_bin=$(command -v jq)
ln -s "$jq_bin" "$test_home/.local/bin/jq"
jq -n --arg root "$hook_root" \
  '[{source:{kind:"github",owner:"qu8n",repo:"herdr-automatic-rename"},plugin_root:$root}]' \
  > "$test_home/.config/herdr/plugins.json"


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

  for managed in "$test_home/.local/bin" "$test_home/bin" "$test_home/.cargo/bin" "$test_home/.bun/bin"; do
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
  'printf "%s|%s|%s|%s|" (string join : -- $PATH) "$EDITOR" "$SHELL_LOCAL_MARKER" "$HERDR_HOOK_MARKER"; type -q ll; and printf alias-loaded' \
  2>"$test_home/fish-interactive.stderr")
IFS='|' read -r interactive_fish_path interactive_fish_editor interactive_fish_marker herdr_hook_marker interactive_fish_alias <<< "$interactive_fish_output"
assert_path "$interactive_fish_path" 'interactive Fish login PATH'
assert_equal nvim "$interactive_fish_editor" 'interactive Fish login EDITOR'
assert_equal loaded "$interactive_fish_marker" 'interactive Fish local config'
assert_equal alias-loaded "$interactive_fish_alias" 'interactive Fish configuration'
assert_equal registered "$herdr_hook_marker" 'interactive Fish registered Herdr hook'

# Model exported Hermit state crossing an interactive Fish process boundary.
hermit_test="$test_home/hermit"
mkdir -p "$hermit_test"/{a/bin,b/bin,config}
cat > "$hermit_test/hermit" <<'SH'
#!/bin/sh
case "$*" in
  "--quiet validate env "*)
    if [ -f "$4/fail-validation" ]; then
      echo 'fixture: invalid Hermit environment' >&2
      exit 23
    fi
    ;;
  "env --deactivate-from-ops="*)
    if [ -f "$ACTIVE_HERMIT/fail-undo" ]; then
      echo 'set -gx PARTIAL_UNDO applied'
      echo 'fixture: inherited undo failed' >&2
      exit 37
    fi
    cat <<'FISH'
set -l old_bin (contains -i -- "$HERMIT_BIN" $PATH)
if test -n "$old_bin"
    set -e PATH[$old_bin]
end
set -gx HERMIT_TEST_VALUE "$HERMIT_ENV_OPS"
set -e HERMIT_ENV
set -e HERMIT_BIN
FISH
    ;;
  *) echo "fixture: unsupported Hermit command: $*" >&2; exit 1 ;;
esac
SH
chmod +x "$hermit_test/hermit"
for project in a b; do
  ln -s "$hermit_test/hermit" "$hermit_test/$project/bin/hermit"
  cat > "$hermit_test/$project/bin/activate-hermit.fish" <<'FISH'
set -gx HERMIT_ENV (path dirname (path dirname (status filename)))
if test "$ACTIVE_HERMIT" = "$HERMIT_ENV"
    return
end
set -gx HERMIT_ENV_OPS "$HERMIT_TEST_VALUE"
set -gx ACTIVE_HERMIT "$HERMIT_ENV"
set -gx HERMIT_BIN "$HERMIT_ENV/bin"
set -gx PATH "$HERMIT_BIN" $PATH
set -gx HERMIT_TEST_VALUE (path basename "$HERMIT_ENV")
function _hermit_deactivate
    set -l undo ("$ACTIVE_HERMIT/bin/hermit" env --deactivate-from-ops="$HERMIT_ENV_OPS"); or return $status
    printf '%s\n' $undo | source; or return $status
    set -e ACTIVE_HERMIT
    set -e HERMIT_ENV_OPS
    functions -e _hermit_deactivate deactivate-hermit update_hermit_env
end
function deactivate-hermit
    set -gx DEACTIVATED_HERMIT "$HERMIT_ENV"
    _hermit_deactivate
end
function update_hermit_env
    set -l environment "$HERMIT_ENV"
    _hermit_deactivate
    source "$environment/bin/activate-hermit.fish"
end
FISH
done
cat > "$hermit_test/assertions.fish" <<'FISH'
function check
    $argv; or begin
        printf 'Hermit assertion failed: %s\n' (string join ' ' -- $argv) >&2
        exit 1
    end
end
function active
    check test "$ACTIVE_HERMIT" -ef "$HERMIT_TEST_ROOT/$argv[1]"
    check test "$HERMIT_ENV" -ef "$ACTIVE_HERMIT"
    check functions -q _hermit_deactivate deactivate-hermit update_hermit_env
    check test (count (string match -- "$HERMIT_TEST_ROOT/$argv[1]/bin" $PATH)) -eq 1
    check test (count (string match -- "$HERMIT_TEST_ROOT/$argv[2]/bin" $PATH)) -eq 0
    check test "$HERMIT_ENV_OPS" = original
    check test "$HERMIT_TEST_VALUE" = "$argv[1]"
end
function inactive
    check test -z "$ACTIVE_HERMIT"
    check test -z "$HERMIT_ENV"
    for project in a b
        check test (count (string match -- "$HERMIT_TEST_ROOT/$project/bin" $PATH)) -eq 0
    end
    check test "$HERMIT_TEST_VALUE" = original
end
FISH
cat > "$hermit_test/child.fish" <<'FISH'
source "$HERMIT_TEST_ROOT/assertions.fish"
check test (count (functions -q _hermit_deactivate; and echo present)) -eq 0
source "$HERMIT_TEST_HELPER"
emit fish_prompt
switch "$argv[1]"
    case outside
        inactive
    case inside
        active a b
        emit fish_prompt
        active a b
        update_hermit_env
        active a b
        cd "$HERMIT_TEST_ROOT/b"
        active b a
        cd "$HERMIT_TEST_ROOT/a"
        active a b
        cd "$HERMIT_TEST_ROOT"
        inactive
        cd "$HERMIT_TEST_ROOT/a"
        deactivate-hermit
        emit fish_prompt
        emit fish_prompt
        inactive
        check test "$DEACTIVATED_HERMIT" -ef "$HERMIT_TEST_ROOT/a"
        cd "$HERMIT_TEST_ROOT"
        cd "$HERMIT_TEST_ROOT/a"
        active a b
        touch "$HERMIT_TEST_ROOT/b/fail-validation"
        cd "$HERMIT_TEST_ROOT/b"
        activate_hermit
        check test $status -eq 23
        inactive
        rm "$HERMIT_TEST_ROOT/b/fail-validation"
        emit fish_prompt
        active b a
        cd "$HERMIT_TEST_ROOT"
        inactive
    case '*'
        exit 1
end
FISH
cat > "$hermit_test/failure.fish" <<'FISH'
source "$HERMIT_TEST_ROOT/assertions.fish"
source "$HERMIT_TEST_HELPER"
if test "$argv[1]" = missing
    set -e HERMIT_ENV_OPS
end
activate_hermit
set -l result $status
if test "$argv[1]" = missing
    check test "$result" -eq 1
    check test (count $HERMIT_ENV_OPS) -eq 0
else
    check test "$result" -eq 37
    check test "$HERMIT_ENV_OPS" = original
end
check test "$ACTIVE_HERMIT" -ef "$HERMIT_TEST_ROOT/a"
check test "$HERMIT_ENV" -ef "$HERMIT_TEST_ROOT/a"
check test "$HERMIT_TEST_VALUE" = a
check test (count (string match -- "$HERMIT_TEST_ROOT/a/bin" $PATH)) -eq 1
check test -z "$PARTIAL_UNDO"
FISH
cat > "$hermit_test/parent.fish" <<'FISH'
source "$HERMIT_TEST_ROOT/assertions.fish"
source "$HERMIT_TEST_HELPER"
cd "$HERMIT_TEST_ROOT/a"
active a b
check "$HERMIT_TEST_FISH" --no-config --interactive "$HERMIT_TEST_ROOT/child.fish" inside
# Change the child's cwd without running this shell's PWD handler.
check sh -c 'cd "$HERMIT_TEST_ROOT"; exec "$HERMIT_TEST_FISH" --no-config --interactive "$HERMIT_TEST_ROOT/child.fish" outside'
touch "$HERMIT_TEST_ROOT/a/fail-undo"
check "$HERMIT_TEST_FISH" --no-config --interactive "$HERMIT_TEST_ROOT/failure.fish" undo
rm "$HERMIT_TEST_ROOT/a/fail-undo"
check "$HERMIT_TEST_FISH" --no-config --interactive "$HERMIT_TEST_ROOT/failure.fish" missing
cd "$HERMIT_TEST_ROOT"
inactive
echo 'Hermit inheritance tests: ok'
FISH
hermit_output=$("${clean_env[@]}" \
  "XDG_CONFIG_HOME=$hermit_test/config" "TERM=xterm-256color" "PATH=/usr/bin:/bin" \
  "HERMIT_TEST_ROOT=$hermit_test" "HERMIT_TEST_FISH=$fish_bin" \
  "HERMIT_TEST_HELPER=$repo_root/fish/functions/hermit_help.fish" \
  "HERMIT_ROOT_BIN=$hermit_test/hermit" "HERMIT_TEST_VALUE=original" \
  "$fish_bin" --no-config --interactive "$hermit_test/parent.fish" \
  2>"$hermit_test/stderr") || fail "Hermit inheritance: $(cat "$hermit_test/stderr")"
assert_equal 'Hermit inheritance tests: ok' "$hermit_output" 'inherited Hermit environment'
grep -Fxq 'fixture: invalid Hermit environment' "$hermit_test/stderr" || fail 'Hermit validation diagnostic hidden'
grep -Fxq 'fixture: inherited undo failed' "$hermit_test/stderr" || fail 'Hermit undo diagnostic hidden'
grep -Fxq 'Hermit: cannot restore inherited environment without HERMIT_ENV_OPS' "$hermit_test/stderr" || fail 'missing Hermit operation snapshot diagnostic hidden'

printf 'Shell startup tests: ok\n'
