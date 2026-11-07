# Omp settings inventory

Inventory date: 2026-11-07. Installed versions: omp 18.17.0, Plannotator extension 0.28.21, Ponytail/Caveman plugin 0.3.4.

## What this repository already manages

- `envy/local.omp@r0.lua` installs Bun, omp, and `github:phenome/omp-ponytail-caveman`.
- `envy.lua` links `ai/CLAUDE.md` to `~/.omp/agent/AGENTS.md` and `~/.agents/AGENTS.md`.
- `bin/update` refreshes the Ponytail/Caveman Git plugin.
- Plannotator installation, personal omp settings, and installed shared skills are not tracked here.
- Repository-local `.omp/*` is ignored. The global `~/.omp` directory is outside this checkout.

## Backup and restore

`bin/omp-backup` invokes **uv directly** through `#!/usr/bin/env -S uv run --script`. PEP 723 metadata declares Python >=3.11 and no Python package dependencies. Install [uv](https://docs.astral.sh/uv/getting-started/installation/) on both machines and put it on `PATH`; uv selects or downloads a compatible Python. Initial Python provisioning can need network access. Repository setup does not install uv, and this change does not modify `bin/update`.

On the source machine, from this checkout:

```sh
./bin/omp-backup inventory
./bin/omp-backup backup "$HOME/omp-settings.tar.gz"
```

Transfer the archive privately, along with access to this repository. Keep the archive outside Git and outside the configuration directories being backed up. Archive creation refuses an existing output path. The archive is owner-readable/writable only. No permanent backup archive was created during implementation.

On the destination machine:

```sh
# Install uv separately, then use this repository's setup for omp, Bun, and links.
./setup
./bin/omp-backup restore "$HOME/omp-settings.tar.gz" --dry-run
./bin/omp-backup restore "$HOME/omp-settings.tar.gz"
```

Dry-run lists planned changes and conflicts without changing files. A normal restore refuses differing existing files before changing anything. To replace differing files deliberately:

```sh
./bin/omp-backup restore "$HOME/omp-settings.tar.gz" --replace
```

Replacement moves displaced originals into a private `~/omp-before-restore-*` directory and prints its path. It does not delete unrelated files. Identical files and dotfiles-managed links remain unchanged. Newly restored regular files use mode `0600`; executable support scripts use `0700`. Backup resolves non-dotfiles skill links into regular files; dotfiles-owned links are skipped so `./setup` retains ownership. Dangling links are reported as unavailable. A real, nonlinked `.omp/agent/AGENTS.md` is included.

Archives contain only allowlisted home-relative regular files. Restore rejects links, traversal, unexpected archive paths, duplicate entries, and linked destination parents. It validates archive contents and destination conflicts before writing; it does not provide a transaction across every file if a later filesystem operation fails. Original displaced files remain available at the printed recovery path.

Use `--home` before the command to select another source or destination home:

```sh
./bin/omp-backup --home "/path/to/target home" restore "$HOME/omp-settings.tar.gz" --dry-run
```

The script covers default locations in this inventory. It reports unsupported named profiles and effective agent/Plannotator directory overrides instead of silently missing them. `PI_CODING_AGENT_DIR` and `PLANNOTATOR_DATA_DIR` may explicitly select their default directories. An existing `~/.plannotator` takes precedence over `XDG_DATA_HOME`; an effective XDG Plannotator location needs separate migration. Do not unset an override and assume its alternate configuration was captured.

After restoring, follow [plugin reconstruction](#plugin-reconstruction), run `omp login`, and complete the [browser preference checklist](#plannotator-browser-preferences). Restore does not execute plugin installers, migrate credentials, rewrite absolute paths, or configure the browser relay.

## Existing configuration outside Git

Paths below are relative to the home directory. Keep repository-owned symlinks managed by `./setup`; do not restore them as regular files. Preserve other installed skill contents and support files rather than machine-specific absolute links.

| Path | Purpose | Backup treatment |
| --- | --- | --- |
| `.omp/agent/config.yml` | Written global omp settings: models, thinking, theme, Vim, tools, memory backend, browser relay, updates | Include |
| `.omp/agent/AGENTS.md` | Symlink to this checkout's `ai/CLAUDE.md` | Recreate with `./setup`; preserve the checkout separately, including uncommitted instruction changes |
| `.omp/agent/extensions/herdr-omp-agent-state.ts` | Herdr integration | Include; activates only inside an appropriate Herdr environment |
| `.omp/plugins/package.json` | Both plugin installation sources | Include |
| `.omp/plugins/bun.lock` | Exact dependency resolution, including Ponytail Git revision `51319d4` | Include; rebuild dependencies on the target OS |
| `.omp/plugins/omp-plugins.lock.json` | Plugin enabled state, features, and settings | Include; both plugins currently enabled |
| `.agents/skills/` | Shared installed skills used by omp and Ponytail/Caveman | Include files and support directories, except links into this dotfiles checkout; recreate those through setup |
| `.agents/.skill-lock.json` | Sources for seven public skill installations | Include |
| `.agents/skills.yaml` | Legacy skill-manager metadata | Include as metadata, not as authoritative omp discovery configuration |
| `.agents/personal-skills/hjz-linear-to-pr/` | Original personal skill source | Include |
| `.plannotator/config.json` | Server-persisted Plannotator preferences | Include; private, potentially credential-bearing |

Current Plannotator file preferences: system theme, `plannotator` light/dark palettes, default terminal agent `codex`, semantic diff enabled, call flow disabled.

Two shared skill links are broken:

- `.agents/skills/checking-ci-jobs` targets `~/.dotfiles/ai/skills/checking-ci-jobs`.
- `.agents/skills/docs-with-mermaid` targets `~/.dotfiles/ai/skills/docs-with-mermaid`.

The target directories are absent. A backup must report these as unavailable, not claim to preserve usable skills.

## Optional configuration locations

These were absent from the inspected installation. Include them if created later:

- `.omp/agent/ponytail-caveman.json`: global plugin mode defaults.
- `.omp/agent/skills/`, `managed-skills/`, `agents/`, `commands/`, `themes/`: user customization directories.
- `.pi/agent/plannotator.json`: Plannotator phase behavior, models, tools, and instructions.
- `.plannotator/review-skills.json`: selected review skills.
- `.plannotator/guide-instructions.md`: standing Guided Review instructions.
- `.plannotator/hooks/compound/enterplanmode-improve-hook.txt`: improvement hook. Legacy fallback: `.plannotator/compound/enterplanmode-improve-hook.txt`.

No named omp profiles, custom model/keybinding/MCP files, or user commands/agents were found. The existing `.pi/agent/settings.json`, `.pi/agent/extensions/`, and `.pi/agent/skills/` belong to standalone Pi; do not confuse them with omp's active agent directory. The Plannotator phase override above is an exception because the extension explicitly uses that location.

## Plannotator browser preferences

**Copying `.plannotator/config.json` does not preserve every preference.** Installed Plannotator source stores substantial preferences in browser cookies. Keep the backup script file-only. Before migration, record these values in the source browser; after migration, reapply them in the destination Plannotator UI:

- [ ] Vim mode and HUD controls.
- [ ] Review panel layout, viewed controls, automatic viewed marking, staging controls.
- [ ] Token hover trigger and delay.
- [ ] Grid, diagram shadow, experimental edit suggestions.
- [ ] Auto-close, open-in-app, quick labels, annotation scope.
- [ ] AI provider/model selections, agent switch/custom agent.
- [ ] Table of contents, sticky actions, plan width, file browser preferences.

Other preferences mirror between cookies and server configuration. Existing server values take precedence. Cookies are hostname-scoped: a new browser profile or a switch between `localhost` and `127.0.0.1` can change which preferences appear. Browser preferences require this separate manual migration; the file archive does not capture them. Never copy an entire Chrome profile or all browser cookies to solve this.

Actual `localStorage` also holds per-review hidden-artifact state under `plannotator-pr-artifacts:hidden:<identity>`. That is review state, not a global preference. Local storage includes the port in its origin; changing ports can hide previous state. Session storage and optional editor IndexedDB state are also not portable global preferences.

Current browser values were not read: browser relay target discovery timed out. The storage behavior above was verified from the installed plugin source, not inferred from cookie names alone.

## Runtime state and credentials: exclude

Do not recursively copy `.omp`, `.pi`, `.agents`, or `.plannotator` wholesale.

- `agent.db` contains provider credentials together with caches, usage, jobs, and memory/thread metadata. Its `settings` table had **zero rows** during inspection; no preference export from that DB is currently needed.
- Exclude all DB/WAL/SHM files, `auth-broker.token`, standalone Pi `auth.json`, and installation identifiers.
- Exclude sessions, prompt history, memories, blobs, terminal state, plans, drafts, feedback, guides, review progress, and semantic-diff caches.
- Exclude plugin `node_modules`, native binaries/grammars, browser downloads, caches, logs, locks, update state, worktrees, SSH controls, remote-host records, and runtime sockets.
- `.plannotator/guide-schema.json` is generated support data, not standing review instructions.
- Exclude `.agents` telemetry, rollout, upload, and registry bookkeeping.
- Session-only `/ponytail` and `/caveman` choices live in session entries. Use the plugins' `global` scope to persist desired defaults; do not migrate sessions merely to retain a mode.

Configuration is not necessarily secret-free. Plannotator supports a plaintext `bitbucketToken`; custom provider, MCP, or skill files can contain credentials or internal material. Keep backups private and outside Git, even when known credential stores are excluded. Authenticate separately with `omp login` on the target. Omp also has `omp auth export/import` for deliberate credential migration; that is a separate sensitive operation.

## Machine and project boundaries

- `omp config path` currently resolves to `~/.omp/agent`. Back up written configuration, not `cfg://` or a dump of effective defaults: those include session-specific overrides.
- `PI_CODING_AGENT_DIR` overrides the agent directory. Named profiles normally use `~/.omp/profiles/<name>/agent`; the current machine has none.
- Ponytail also checks `OMP_PROFILE` or `PI_PROFILE` and repository `.omp/ponytail-caveman.json`.
- Plannotator phase configuration uses `$PI_CODING_AGENT_DIR/plannotator.json` when set, otherwise `~/.pi/agent/plannotator.json`. It does not independently select an omp profile directory.
- Plannotator data uses `PLANNOTATOR_DATA_DIR`, then an existing `~/.plannotator`, then an absolute `$XDG_DATA_HOME/plannotator`, otherwise `~/.plannotator`.
- `PLANNOTATOR_BROWSER`, `PLANNOTATOR_REMOTE`, `PLANNOTATOR_PORT`, `PLANNOTATOR_AGENT_TOOL`, and related environment overrides are separate from files. Reconfigure them on the target; do not export the full environment and its secrets.
- Repository settings, `.pi/plannotator.json`, project MCP files, explicit `--config` overlays, and project skill/command directories travel with their own repositories. They were not found as active overrides in this checkout. A home backup is not a backup of every development repository.
- Existing `symbolPreset: nerd` requires a Nerd Font. `browser.relay: true` requires Chrome and relay setup. `agentTerminalDefaultAgent: codex` requires the Codex executable and its own login. Herdr's socket/pane environment is supplied at runtime.
- Absolute paths inside configuration or scripts need review on Linux. Do not blindly replace every occurrence of the old home directory in code or prose.

## Plugin reconstruction

Install omp and Bun for the target OS before restoring preferences. This repository's setup handles both, but installs only the Ponytail plugin by default.

Preserve the plugin manifests and Bun lock together, then reconstruct dependencies on the destination:

```sh
bun install --frozen-lockfile --cwd "$HOME/.omp/plugins"
omp plugin list --json
omp plugin doctor
```

Do not transfer macOS `node_modules` to Linux. Plannotator dependencies include native modules. Plugin installation can execute lifecycle scripts; restore only trusted backups. Ponytail's skill installer needs Node plus `bunx` or `npx` and network access. Keeping resolved skill contents preserves the actual installed instructions without relying on an unpinned upstream skill reinstall.

## Inspection evidence

The inventory used `omp --help`, `omp config path`, `omp plugin list --json`, `omp config --help`, `omp auth --help`, repository setup files, directory metadata, DB schema/counts, and installed plugin source:

- `omp-ponytail-caveman/index.js`: mode precedence, global/repository files, detached skill lookup.
- `@plannotator/pi-extension/config.ts`: phase override locations.
- `@plannotator/pi-extension/generated/data-dir.ts`: data-directory precedence.
- `@plannotator/pi-extension/generated/config.ts`: server preferences and sensitive fields.
- `@plannotator/pi-extension/plannotator.html`: cookie adapter and preference registry.
- `@plannotator/pi-extension/review-editor.html`: per-review browser storage.

## Verification

Run the standard-library checks through uv:

```sh
uv run --script tests/omp_backup_test.py
```

Seven unit checks passed on macOS: file selection and resolved skills, permissions and repeat restores, conflict/dry-run/recovery behavior, managed/external links, linked destination parents, unsafe archives, and empty/cyclic sources. The actual executable backed up 483 files from the current home and restored them into a disposable home. Dry-run made no destination; repeat restore changed zero files. Omp read the restored `modelRoles` and `tui.vimMode: true` successfully. Credential DBs and sessions were absent, and source Plannotator and omp configuration matched restored bytes.

Temporary archives and restored homes were removed. No real-home restore, plugin reinstall, or Linux run was performed. CI now runs these checks with uv on macOS and Ubuntu; that is configured coverage, not a claim that CI has run.
