---
applyTo: "setup.sh,scripts/**"
description: "Use when: changing bootstrap scripts, setup flow, install/update/link logic, dry-run behavior, package installation, or linker mechanics in setup.sh and scripts/."
---

# Bootstrap Instructions

- Start with `setup.sh` or the specific file in `scripts/` named by the task.
- Treat bootstrap changes as behavior changes to install, update, link, dry-run, or validation flow.
- If install behavior or linked paths change, inspect `profiles/` before editing.
- Keep fixes in the bootstrap layer; do not rewrite config files to compensate for script defects unless that is clearly the correct fix.
- Prefer validating bootstrap or linker changes with dry-run or the update harness when practical.
- Do not broaden bootstrap scope into shell, desktop, or editor folders unless the task explicitly crosses those domains.

## Sudo and privileged operations

`ensure_prerequisites()` in `utils.sh` installs `git` and `curl` if either is absent. It is called before `ensure_sudo()` at the start of any install or update phase. It invokes the distro package manager directly (not via `checkinstall`) and handles both root and non-root contexts. It is a no-op when both tools are already present or when `is_dry_run` is true. Alpine exits at this point before reaching `checkinstall`.

`preflight_check()` in `utils.sh` runs before `ensure_prerequisites()` on any install or update. It checks: distro support (hard-exits on Alpine or unknown-with-no-package-manager), architecture (warns if not x86_64/aarch64), sudo availability (hard-exits if absent as non-root), and GitHub reachability (warns if unreachable). It is a no-op in dry-run mode.

`ensure_sudo()` in `utils.sh` is the single entry point for sudo. It:
- Checks `sudo` is available and exits with a clear message if not
- Prints a user-visible explanation before prompting
- Calls `sudo -v` once to authenticate upfront
- Starts a background keepalive (`sudo -n true` every 30s, watching parent PID) so slow downloads do not expire the ticket
- Is a no-op when `$EUID -eq 0` (root / Docker) or `is_dry_run` is true

Call `ensure_sudo` once at the start of any flow that will invoke `checkinstall`, before any package installs. `initiate.sh` calls it whenever `is_install=true` or `is_update=true`. Link-only runs skip it.

Never call `sudo` directly in new code — use `run_cmd sudo <cmd>` so dry-run suppresses it. The test harness mocks `sudo` with a passthrough; `-v` and `-n` are handled as no-ops.

`whichdistro()` in `utils.sh` maps `/etc/*-release` files to: `debian`, `redhat`, `arch`, `alpine`. Use these four values everywhere.

`checkinstall()` dispatches to the correct package manager. Always use `checkinstall` instead of calling `apt-get`/`yum`/`pacman` directly — it handles `sudo`, RHEL EPEL/CRB setup, and package name aliases (e.g. `python-pip` → `python3-pip` on Debian). Alpine is detected but **not supported**: `checkinstall` exits immediately with a clear error message.

## is_wsl() behaviour

`is_wsl()` requires **both**: `/proc/version` containing `microsoft` AND `/proc/sys/fs/binfmt_misc/WSLInterop` existing. Docker-on-WSL2 shares the kernel so the string matches inside containers, but `WSLInterop` is absent — `is_wsl()` correctly returns false in Docker.

## Script call-site conventions

- `helix.sh` and `nvim.sh` contain top-level install calls guarded by `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` — they only run when executed directly. When `initiate.sh` sources them to load functions, it **must** call the install function explicitly afterwards:
  ```bash
  source "$current_dir"/helix.sh
  install_helix || print_warning "..."
  source "$current_dir"/nvim.sh
  neovim_nightly || print_warning "..."
  ```
- Both install calls are non-fatal (`|| print_warning`) because network download failures should not abort the rest of bootstrap.

## Idempotency

Every bootstrap phase is safe to re-run after a `git pull`. Key properties:

- **Linker** (`home-dir.sh`): `symlink_points_to()` skips entries that are already correctly linked. A pre-scan fast path prints "All N entries already linked — nothing to do" and returns early without creating a backup dir when every entry is already in place.
- **Package installs**: `apt-get install -y`, `pacman -S --noconfirm --needed`, and `yum install -y` are all idempotent by design.
- **`ensure_zsh_default_shell`**: checks the current shell before calling `chsh`.
- **`neovim_nightly`**: GitHub API mtime check — skips download if installed binary is at least as new as the latest published nightly.
- **`install_helix`**: GitHub releases API version check — compares `hx --version` against the latest tag. Fail-open: if the API call fails or the version cannot be parsed, the code falls through and re-installs. `get_latest_helix_version()` in `helix.sh` encapsulates this API call.
- **`checkinstall` RHEL path**: `yum clean all` and EPEL/CRB repo setup run only once per bootstrap session, guarded by `_DOTFILES_CHECKINSTALL_RHEL_INIT`. Subsequent `checkinstall` calls within the same session skip the one-time setup and go straight to the package install.

## Profile switching

When a user switches from one profile to another (e.g. `full` → `hypr-minimal`), the linker:

1. Reads the previously-active profile from `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/active-profile`.
2. Detects the mismatch and calls `unlink_removed_entries()`, which computes the diff between the old and new profile manifests and removes any symlink that:
   - exists at the expected destination path, **and**
   - points exactly into the dotfiles repo (verified by `symlink_points_to()`).
   Symlinks the user created themselves, or entries managed by `_install.sh` installer hooks (which nest multiple files under the destination directory), are never touched.
3. Writes the new profile name to the state file before starting the link loop, so future runs detect further switches correctly even if the current run is interrupted.

**Important constraints:**
- Entries that use `_install.sh` hooks (e.g. `config/core/Code/`) are now handled automatically: `unlink_hook_entry()` scans the destination directory for any symlinks whose resolved path falls inside the old entry's source directory, and removes them. Empty directories left behind are also removed. This covers any hook that follows the `$dest_dir/<basename>/...` convention.
- `run_autoremove()` in `initiate.sh` calls the distro-specific package autoremove (`apt-get autoremove -y` on Debian/Ubuntu, `yum autoremove -y` on RHEL, `pacman -Rns $(pacman -Qdtq)` on Arch) at the end of the `is_update` phase when `DOTFILES_PROFILE_SWITCHED=true`. It removes all orphaned packages, not just dotfiles-related ones, which is the standard system-level cleanup after a desktop-session change.
- On a `link`-only run, the linker still performs the symlink and hook cleanup but the package phase is skipped. The user is reminded to run `./setup.sh --profile <new>` to trigger the full switch including autoremove. (`setup.sh` is the public interface for all user-facing profile operations; `initiate.sh` sub-commands are internal/power-user.)
- The state file path honours `XDG_DATA_HOME` when set; test harnesses must pass `XDG_DATA_HOME` explicitly to avoid polluting the real user home.

## Architecture support

Neovim (`nvim.sh`) and Helix (`helix.sh`) detect `uname -m` and download:
- `x86_64` / `amd64` → `nvim-linux-x86_64.tar.gz` / `x86_64-linux.tar.xz`
- `aarch64` / `arm64` → `nvim-linux-arm64.tar.gz` / `aarch64-linux.tar.xz`

## Bare metal vs Docker differences

| Context | sudo required | chsh works | is_wsl() | Package install |
|---|---|---|---|---|
| Bare metal (non-root) | Yes | Yes (needs auth) | `true` only on WSL2 | Needs distro pkgs first |
| Docker (root) | sudo is a no-op | Mocked in harness | Always false | Image-dependent |
| WSL2 | Yes | Yes (needs auth) | true | Same as bare metal |

## Test harness

`scripts/test-update-harness.sh` mocks: `apt-get`, `yum`, `dnf`, `pacman`, `curl`, `tar` (smart: creates fake extracted dirs), `chsh`, `sudo` (passthrough exec so mocked commands remain reachable within sudo calls). Run it after any change to `initiate.sh`, `home-dir.sh`, `utils.sh`, `helix.sh`, or `nvim.sh`. The harness also asserts the active-profile state file is written correctly and verifies the full profile-switch path (link → detect switch → unlink removed entries → autoremove).
