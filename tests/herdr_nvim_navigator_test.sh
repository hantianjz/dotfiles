#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
helper="$repo_root/scripts/herdr-nvim-navigator"
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/herdr-nvim-navigator.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT

log="$test_dir/calls"
export HERDR_NVIM_NAVIGATOR_TEST_LOG="$log"

cat >"$test_dir/herdr" <<'EOF'
#!/bin/sh

case "$*" in
  "pane process-info --pane "*)
    [ "${FAKE_HERDR_FAIL:-0}" -eq 0 ] || exit 1
    printf '%s\n' "$FAKE_HERDR_PROCESS_INFO"
    ;;
  *)
    printf 'herdr %s\n' "$*" >>"$HERDR_NVIM_NAVIGATOR_TEST_LOG"
    ;;
esac
EOF
chmod +x "$test_dir/herdr"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  if [ -s "$log" ]; then
    sed 's/^/  /' "$log" >&2
  fi
  exit 1
}

run_helper() {
  PATH="$test_dir:$PATH" HERDR_BIN_PATH="$test_dir/herdr" \
    "$helper" "$@"
}

assert_call() {
  [ "$(cat "$log")" = "$1" ] || fail "expected call: $1"
}

: >"$log"
# Match the wrapped response shape returned by Herdr 0.7.5.
FAKE_HERDR_PROCESS_INFO='{"result":{"process_info":{"foreground_processes":[
  {"name":"zsh","argv0":"/bin/zsh"},
  {"name":"nvim","argv0":"/opt/homebrew/bin/nvim"}
]}}}'
export FAKE_HERDR_PROCESS_INFO
run_helper left pane-1
assert_call "herdr pane send-keys pane-1 ctrl+h"

: >"$log"
FAKE_HERDR_PROCESS_INFO='{"result":{"process_info":{"foreground_processes":[
  {"name":"zsh","argv0":"/bin/zsh"}
]}}}'
export FAKE_HERDR_PROCESS_INFO
run_helper down pane-2
assert_call "herdr pane focus --direction down --pane pane-2"

: >"$log"
HERDR_PANE_ID=pane-from-env run_helper right
assert_call "herdr pane focus --direction right --pane pane-from-env"

: >"$log"
FAKE_HERDR_FAIL=1 run_helper up stale-pane
[ ! -s "$log" ] || fail "runtime failure should not mutate pane state"

: >"$log"
run_helper diagonal pane-3
[ ! -s "$log" ] || fail "invalid direction should be ignored"

printf 'Herdr Neovim navigator tests: ok\n'
