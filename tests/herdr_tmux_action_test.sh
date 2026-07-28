#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
helper="$repo_root/scripts/herdr-tmux-action"
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/herdr-tmux-action.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT

log="$test_dir/calls"
paste_result="$test_dir/paste-result"
clipboard_result="$test_dir/clipboard-result"
export HERDR_TMUX_TEST_LOG="$log"
export HERDR_TMUX_PASTE_RESULT="$paste_result"
export HERDR_TMUX_CLIPBOARD_RESULT="$clipboard_result"

cat >"$test_dir/herdr" <<'EOF'
#!/bin/sh
[ "${FAKE_HERDR_FAIL:-0}" -eq 0 ] || exit 1

case "$*" in
  "pane layout --pane "*)
    printf '%s\n' "$FAKE_HERDR_LAYOUT"
    ;;
  "pane swap "*)
    printf 'herdr %s\n' "$*" >>"$HERDR_TMUX_TEST_LOG"
    printf '{"result":{"changed":true}}\n'
    ;;
  "pane send-text "*)
    printf 'herdr pane send-text %s\n' "$3" >>"$HERDR_TMUX_TEST_LOG"
    printf '%s' "$4" >"$HERDR_TMUX_PASTE_RESULT"
    ;;
  "pane process-info "*)
    printf '%s\n' "$FAKE_HERDR_PROCESS_INFO"
    ;;
esac
EOF

cat >"$test_dir/pbpaste" <<'EOF'
#!/bin/sh
[ "${FAKE_CLIPBOARD_FAIL:-0}" -eq 0 ] || exit 1
printf 'first line\nsecond line\n\n'
EOF

cat >"$test_dir/pbcopy" <<'EOF'
#!/bin/sh
cat >"$HERDR_TMUX_CLIPBOARD_RESULT"
EOF

chmod +x "$test_dir/herdr" "$test_dir/pbpaste" "$test_dir/pbcopy"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  if [ -f "$log" ]; then
    sed 's/^/  /' "$log" >&2
  fi
  exit 1
}

assert_called() {
  grep -Fqx "$1" "$log" || fail "expected call: $1"
}

assert_no_calls() {
  [ ! -s "$log" ] || fail "expected no Herdr mutations"
}

reset_test() {
  : >"$log"
  : >"$paste_result"
  : >"$clipboard_result"
  unset FAKE_HERDR_FAIL FAKE_CLIPBOARD_FAIL
}

run_helper() {
  PATH="$test_dir:$PATH" HERDR_BIN_PATH="$test_dir/herdr" \
    "$helper" "$@"
}

# The input is intentionally not API-ordered. Visual order is top-to-bottom,
# then left-to-right: p1, p2, p3, p4.
FAKE_HERDR_LAYOUT='{"result":{"focused_pane_id":"p2","panes":[
  {"pane_id":"p4","rect":{"x":50,"y":20,"width":50,"height":20}},
  {"pane_id":"p2","rect":{"x":50,"y":0,"width":50,"height":20}},
  {"pane_id":"p1","rect":{"x":0,"y":0,"width":50,"height":20}},
  {"pane_id":"p3","rect":{"x":0,"y":20,"width":50,"height":20}}
]}}'
export FAKE_HERDR_LAYOUT

# Rotation produces p2,p3,p4,p1. p3 lands in p2's original cell and is the
# source of the final swap, which is how Herdr preserves that focused cell.
reset_test
run_helper rotate p2
expected_calls='herdr pane swap --source-pane p3 --target-pane p4
herdr pane swap --source-pane p3 --target-pane p1
herdr pane swap --source-pane p3 --target-pane p2'
[ "$(cat "$log")" = "$expected_calls" ] || fail "unexpected rotation sequence"

reset_test
run_helper swap-first p3
assert_called "herdr pane swap --source-pane p3 --target-pane p1"

# Pasting is literal, including embedded and trailing newlines.
reset_test
run_helper paste p2
printf 'first line\nsecond line\n\n' >"$test_dir/expected-paste"
cmp "$test_dir/expected-paste" "$paste_result" ||
  fail "clipboard text was not sent literally"

reset_test
FAKE_HERDR_PROCESS_INFO='{"result":{"foreground_processes":[
  {"name":"zsh","cwd":"/old"},
  {"name":"nvim","cwd":"/repo/with spaces"}
]}}'
export FAKE_HERDR_PROCESS_INFO
run_helper copy-cwd p2
[ "$(cat "$clipboard_result")" = "/repo/with spaces" ] ||
  fail "foreground cwd was not copied"

# Expected runtime races and unavailable clipboard data are silent.
reset_test
FAKE_HERDR_FAIL=1 run_helper rotate stale
assert_no_calls

reset_test
FAKE_CLIPBOARD_FAIL=1 run_helper paste p2
assert_no_calls
[ ! -s "$paste_result" ] || fail "failed clipboard read still pasted"

reset_test
FAKE_HERDR_LAYOUT='{"result":{"panes":[
  {"pane_id":"only","rect":{"x":0,"y":0,"width":80,"height":24}}
]}}'
export FAKE_HERDR_LAYOUT
run_helper rotate only
run_helper swap-first only
assert_no_calls

printf 'Herdr tmux action tests: ok\n'
