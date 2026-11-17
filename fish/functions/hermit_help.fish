function activate_hermit --on-variable PWD --on-event fish_prompt
  set CUR $PWD
  set -q HERMIT_ROOT_BIN; or set HERMIT_ROOT_BIN "$HOME/bin/hermit"

  if test -n "$ACTIVE_HERMIT"; and not functions -q _hermit_deactivate
      if not set -q HERMIT_ENV_OPS
          echo "Hermit: cannot restore inherited environment without HERMIT_ENV_OPS" >&2
          return 1
      end
      set -l deactivation ("$ACTIVE_HERMIT/bin/hermit" env --deactivate-from-ops="$HERMIT_ENV_OPS"); or return $status
      printf '%s\n' $deactivation | source; or return $status
      set -e ACTIVE_HERMIT
      set -e HERMIT_ENV_OPS
  end

  while test "$CUR" != "/"
      if test "$CUR" -ef "$HERMIT_ENV"; and test "$CUR" -ef "$ACTIVE_HERMIT"; and functions -q _hermit_deactivate
          return
      end
      if test -f "$CUR/bin/activate-hermit.fish"
          if test -n "$HERMIT_ENV"
              type -q _hermit_deactivate; and _hermit_deactivate
          end
          # Validate and activate the Hermit environment
          if not test "$CUR" -ef "$DEACTIVATED_HERMIT"
              "$HERMIT_ROOT_BIN" --quiet validate env "$CUR" >/dev/null; or return $status
              source "$CUR/bin/activate-hermit.fish"
          end
          return
      end
      set CUR (dirname "$CUR")
  end
  set -e DEACTIVATED_HERMIT
  if test -n "$HERMIT_ENV"
      type -q _hermit_deactivate; and _hermit_deactivate
  end
end

function __complete_hermit
    set -q HERMIT_ROOT_BIN; or set HERMIT_ROOT_BIN "$HOME/bin/hermit"
    set -lx COMP_LINE (commandline -cp)
    test -z (commandline -ct)
    and set COMP_LINE "$COMP_LINE "
    $HERMIT_ROOT_BIN noop
end

complete -f -c hermit -a "(__complete_hermit)"
