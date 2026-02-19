# Repository Guidelines (AGENTS.md)

## What this repo is
This repository is a Quickshell configuration (QML) targeting Arch Linux + Hyprland (AUR `quickshell-git` / master).

Primary entry point:
- `shell.qml` (root component, typically `ShellRoot`)

Local modules:
- `qmldir` files register local QML types; keep them in sync when adding/removing/renaming exported components.
- `menu/` contains the menu system and has its own `qmldir`.

## Authoritative references (use these; do not guess APIs)
- Quickshell docs (master): https://quickshell.org/docs/master
- Guided Introduction (config layout / `-c` / `-p`): https://quickshell.org/docs/guide/introduction
- Installation & Setup (Arch + quickshell-git notes): https://quickshell.org/docs/guide/install-setup
- Types reference (master): https://quickshell.org/docs/types
- Hyprland module types: https://quickshell.org/docs/types/Quickshell.Hyprland/Hyprland
- QML language overview (Quickshell): https://quickshell.org/docs/guide/qml-language

## Quickshell config selection model (critical)
Quickshell discovers configs under XDG config dirs:
- `~/.config/quickshell/<configName>/shell.qml` is a named config
- If `~/.config/quickshell/shell.qml` exists, it becomes the `default` config and subfolders are ignored

Run by config name:
- `quickshell -c <configName>`

Run by explicit path (file or folder):
- `quickshell -p /path/to/shell.qml`
- `quickshell -p /path/to/config-folder`

## Development workflow (what to run)
There is no compile step; correctness is validated by running Quickshell, reading logs, and linting QML.

Recommended local checks:
- Lint:
  - `qmllint *.qml menu/*.qml`
- Format (only touch files you changed):
  - `qmlformat -i *.qml menu/*.qml`
- Review changes:
  - `git diff -- .`

Manual runtime verification on Hyprland:
- Start Quickshell with explicit selection:
  - `quickshell -c <configName>` OR `quickshell -p .` (repo folder) OR `quickshell -p ./shell.qml`
- Confirm:
  - Bar/panels render on all monitors (if using `Quickshell.screens`/`Variants`)
  - No unexpected focus-stealing
  - Menus open/close correctly; click targets and hover states work
  - Workspace/window updates behave correctly under Hyprland

## Logging and debugging runbook (required for troubleshooting)
### 1) Read logs for the active instance
- `quickshell log`
  - This prints logs and also reports the on-disk log path (commonly under `/run/user/<uid>/quickshell/by-id/.../log.qslog`).

Useful options:
- Follow live:
  - `quickshell log -f`
- Tail last N lines:
  - `quickshell log -t 200`
- Apply readout rules (Qt logging rules format) while reading:
  - `quickshell log -r "<QT_LOGGING_RULES>"`

### 2) Increase verbosity when reproducing bugs
- INFO-level internal logs:
  - `quickshell -v -c <configName>`
- DEBUG-level internal logs:
  - `quickshell -vv -c <configName>`
- Add timestamps:
  - `quickshell --log-times -vv -c <configName>`

### 3) Control Qt logging categories (signal over noise)
Quickshell accepts log rules in the same format as `QT_LOGGING_RULES`:
- At launch:
  - `quickshell --log-rules "<QT_LOGGING_RULES>" -vv -c <configName>`

Examples:
- Enable most debug (can be noisy):
  - `--log-rules "*.debug=true"`
- Enable debug but disable a specific noisy category:
  - `--log-rules "*.debug=true;qt.qpa.*=false"`

### 4) What to include when reporting an issue / opening a PR
- `quickshell --version`
- Exact run command used (`-c` vs `-p`)
- `quickshell log -t 200` output (or the `.qslog` file path plus a relevant excerpt)
- If the issue started after a system update, reinstall `quickshell-git` and re-test (Qt updates can break AUR builds).

## Coding style and conventions
- Use 4-space indentation; no tabs.
- Keep QML type/file names in PascalCase; properties/signals/functions in camelCase.
- Centralize theme tokens in `Theme.qml`; avoid duplicating constants across components.
- Prefer declarative bindings; keep JS imperative logic small and local.
- Avoid Quickshell “root imports” (`import "root:/..."`) because they can break LSP and singletons.

## Change boundaries
- Keep edits minimal and scoped to the requested behavior.
- Do not reformat unrelated files.
- Do not change public component APIs (properties/signals) unless necessary and documented.
- Do not add new runtime dependencies unless explicitly requested.

## Definition of done (every change must satisfy)
- Quickshell starts without “Failed to load configuration”.
- No new warnings/errors in the log related to the changed code paths.
- The UI behaves correctly on Hyprland with the current monitor layout.
- `qmllint` passes on touched QML files.
