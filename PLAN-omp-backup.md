# Portable omp settings backup

## Context

Personal omp settings, installed skills, plugin manifests, and Plannotator preferences live outside this repository. The completed inventory is in `docs/omp-settings.md`. The goal is a private, repeatable file backup that restores on macOS or Linux without copying credentials, conversations, caches, or OS-specific dependencies.

Implementation proceeds after the user's requested revision: invoke the script through uv directly.

## Approach

Add one executable `bin/omp-backup` with `#!/usr/bin/env -S uv run --script` and PEP 723 metadata declaring Python >=3.11 and no package dependencies. uv selects or provisions Python on macOS and Linux. Use Python's standard-library `tarfile` for `.tar.gz` archives and executable permissions; neither omp nor a browser is needed for backup or restore. uv must be installed separately; do not alter the updater.

Commands:

```sh
./bin/omp-backup inventory
./bin/omp-backup backup "$HOME/omp-settings.tar.gz"
./bin/omp-backup restore "$HOME/omp-settings.tar.gz" --dry-run
./bin/omp-backup restore "$HOME/omp-settings.tar.gz"
```

Provide `--home DIRECTORY` for an alternate source or destination home. Resolve known configuration paths beneath that home. Store only home-relative archive names. Refuse active nondefault `PI_CODING_AGENT_DIR`, named profiles, or Plannotator data overrides rather than silently claiming to back them up; document their separate migration. The current installation uses the default locations.

### Included files

Use an explicit allowlist matching the inventory:

- `.omp/agent/config.yml` and optional `ponytail-caveman.json`.
- `.omp/plugins/package.json`, `bun.lock`, and `omp-plugins.lock.json`.
- `.omp/agent/extensions/`, `skills/`, `managed-skills/`, `agents/`, `commands/`, and `themes/` when present.
- `.agents/skills/`, `.agents/personal-skills/`, `.agents/.skill-lock.json`, and `.agents/skills.yaml`.
- `.plannotator/config.json`, optional `review-skills.json`, `guide-instructions.md`, and the documented current/legacy improvement-hook file.
- Optional `.pi/agent/plannotator.json`, used by the installed extension despite running under omp.

Do not recursively copy application-data roots. Exclude dependency directories, Git internals, Python caches, credentials, databases, sessions, memories, logs, locks, generated review state, and binaries.

### Repository-owned links

Identify links into this checkout or the source home's `.dotfiles` directory. Report and skip them, including `.omp/agent/AGENTS.md`; `./setup` recreates managed links on the target. Include a real, user-owned `.omp/agent/AGENTS.md` if present instead of the managed link. Report dangling links without claiming their contents were backed up. Resolve other skill links into regular archive files so the target does not depend on old absolute link targets. Detect cycles.

Do not change or commit the user's preexisting `ai/CLAUDE.md` edits or `PLAN-plannotator-native.md`. Document that uncommitted tracked instructions require separate preservation.

### Privacy and restore safety

- Create archives exclusively, with owner-only permissions under `umask 077`; never overwrite an older archive.
- Use the explicit file allowlist as the archive contract; store no credentials or full environment dump.
- Warn that configuration and skill contents can still contain plaintext secrets or internal material. Keep archives outside Git.
- Validate the complete archive before writing: reject absolute paths, traversal, duplicate/conflicting names, unknown paths, links, and special files. Read member contents to catch corruption before target changes.
- Refuse symlinked destination parents. Leave identical target files and setup-managed links unchanged. Treat differing links as conflicts, never write through them.
- Default: refuse differing existing files before making changes. `--replace` preserves all displaced originals in a private directory before replacing files; print that recovery path. Never delete unrelated files or destination-only skills.
- `--dry-run` lists intended changes and conflicts without modifying files.
- Preserve executable bits for skill support scripts; private regular files and directories remain owner-only.
- Do not rewrite arbitrary absolute paths inside configuration or execute restored code.

### Linux migration and browser boundary

Recreate dotfiles links with `./setup`. Restore the file archive, then reinstall plugin dependencies using the restored manifests and Bun lock:

```sh
bun install --frozen-lockfile --cwd "$HOME/.omp/plugins"
omp plugin list --json
omp plugin doctor
omp login
```

The restore script prints these follow-up commands; it does not install packages or run lifecycle scripts itself. Rebuild dependencies on the target OS, never copy macOS `node_modules` to Linux.

Browser-only Plannotator preferences remain a manual checklist in `docs/omp-settings.md`: Vim mode, HUD, review controls, and related toggles. No browser relay integration, Chrome profile copying, cookie export, or credential export in the script. Review Nerd Font availability, browser relay setup, Codex installation, and machine-specific paths separately.

## Files to modify

- New `bin/omp-backup`: inventory, backup, safe restore, and help.
- New `tests/omp_backup_test.py`: standard-library unit checks for archive selection and restore safety, not a new end-to-end framework.
- Existing `docs/omp-settings.md`: exact commands, prerequisites, scope, conflicts, recovery, manual browser checklist, and observed verification.
- Existing `README.md`: short backup/restore section linking the inventory.
- Existing `.github/workflows/cross-platform-envy.yml`: watch `bin/omp-backup` and run the uv-based unit checks on macOS and Ubuntu.

No setup or updater behavior changes. uv is the explicit runtime prerequisite. No Python package dependencies or browser automation.

## Reuse

- `envy.lua`: authoritative ownership of shared instruction links.
- `envy/local.omp@r0.lua`: existing macOS/Linux omp and Bun setup.
- `README.md`, “Existing dotfiles”: preserve Envy's managed-link ownership and conflict behavior.
- `docs/omp-settings.md`: verified file inventory and exclusions.
- Python standard library: `argparse`, `pathlib`, `tarfile`, `tempfile`, and `unittest`.

## Steps

- [x] Implement file selection and inventory, private tar backup, and validated restore with conflict preservation.
- [x] Add focused unit checks; smoke-run the actual CLI against isolated source and destination homes.
- [x] Update inventory and README with exact migration commands and limits; run spelling checks and commit only task-owned files locally.

## Verification

Use synthetic homes containing representative omp settings, Plannotator preferences, executable skill files, unrelated state, setup-owned links, external skill links, and dangling links.

Verify byte-for-byte configuration round trips, executable permissions, owner-only archive permissions, excluded credentials/state, preserved managed links, alternate home paths containing spaces, empty selections, and existing-backup refusal. Verify conflict refusal makes no target changes; replacement retains originals; dry-run makes no changes; identical re-restore is harmless. Exercise unsafe archive paths, archive symlinks, destination-parent links, duplicates, and malformed archives through unit checks.

Run the actual CLI against a disposable home and read restored configuration through `omp config` with isolated environment settings. Do not run live updater or restore into the real home. Run a real-source inventory without displaying file contents. If Linux execution is unavailable, report macOS verification explicitly; do not claim Linux was tested. Run `typos` on changed documentation. Preserve preexisting changes and create no containers merely to test this script.

## Observed results

- Direct `./bin/omp-backup --help` and inventory ran through the uv shebang.
- Seven standard-library unit checks passed through `uv run --script tests/omp_backup_test.py`.
- A real-source backup contained 483 files. Restore into a disposable home preserved configuration bytes; omp read the restored model roles and Vim mode. Dry-run wrote nothing; a repeated restore changed zero files.
- Dotfiles instruction links were skipped, two dangling skill links were reported, and credential databases and sessions were absent from the restored home.
- Temporary archives and homes were removed. Linux and plugin reconstruction were not run; macOS/Ubuntu checks are configured in CI.
- `typos` passed for the script, tests, inventory, plan, README, and workflow.
