# Override vendor just.fish completion to use system just for completion generation.
# Hermit-managed just (e.g., v1.40.0) ignores JUST_COMPLETE=fish and dumps
# recipe list as plain text, which fish then tries to source as code.

# Find the real (non-Hermit) just binary
set -l _just_bin (command -s just)
for p in /opt/homebrew/bin/just /usr/local/bin/just
    if test -x $p
        set _just_bin $p
        break
    end
end

if test -n "$_just_bin"
    complete --keep-order --exclusive --command just --arguments "(JUST_COMPLETE=fish $_just_bin -- (commandline --current-process --tokenize --cut-at-cursor) (commandline --current-token))"
end
