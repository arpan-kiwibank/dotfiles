# Bootstrap Internals

Reference for developers working on `scripts/` and `setup.sh`.

## Sudo and privileged operations

`ensure_prerequisites()` installs `git` and `curl` if absent, calling the distro package manager directly (before `ensure_sudo()` is available). No-op when both tools are present or `is_dry_run` is true.

`preflight_check()` runs before `ensure_prerequisites()` on any install or update. Hard-exits on Alpine or unknown distro with no package manager; warns on unsupported arch or unreachable GitHub; no-op in dry-run.

`ensure_sudo()` authenticates once upfront (`sudo -v`), prints a user-visible explanation, and keeps the ticket alive in background (`sudo -n true` every 30s, watching parent PID). No-op when `$EUID -eq 0` (root/Docker) or `is_dry_run`.

## is_wsl() behaviour

Requires **both**: `/proc/version` containing `microsoft` AND `/proc/sys/fs/binfmt_misc/WSLInterop` existing. Docker-on-WSL2 shares the kernel string but lacks `WSLInterop` — correctly returns false in Docker.

## Script call-site conventions

`helix.sh` and `nvim.sh` are guarded by `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` so they run only when executed directly. When `initiate.sh` sources them, it must call the function explicitly:

```bash
source "$current_dir"/helix.sh
install_helix || print_warning "..."
source "$current_dir"/nvim.sh
neovim_nightly || print_warning "..."
```

Both are non-fatal (`|| print_warning`) — network failures warn and continue.

## GitHub CLI (`gh.sh`)

`install_gh()` uses the **official package-manager method** per distro (no zinit):
- `debian`: adds `cli.github.com` apt keyring via `wget` + sets apt source, then `apt-get install gh`
- `redhat`: detects `dnf5` / `dnf4` / `yum`, adds the repo, installs `gh`
- `arch`: `pacman -S github-cli`
- `alpine`: `apk add github-cli` (despite alpine being unsupported overall — `checkinstall` would abort first, but `install_gh` may be reached before that; the `gh.sh` branch is safe)
- other: prints a manual URL and returns successfully (non-fatal)

Idempotency guard: `command -v gh`, which is reliable since `gh` is always installed to a system path (not shadowed by VS Code or other tools).

## AI tools (`ai-tools.sh`)

`install_gh_copilot()` and `install_claude_code()` use curl pipe-to-bash installers.

**Idempotency**: checks the **exact install path** (`~/.local/bin/copilot`, `~/.local/bin/claude` for non-root; `/usr/local/bin/` for root) rather than `command -v`, because other tools (e.g. the VS Code Copilot Chat CLI shim) shadow these names on PATH and hang on `--version`.

**Non-fatal network failures**: curl exit codes are captured with `|| exit_code=$?`. On any non-zero exit (corporate proxy 403, offline, etc.), a warning is printed with manual install instructions and bootstrap continues.

**Known proxy issue**: Zscaler and similar corporate proxies block `claude.ai` with a 403. The Copilot CLI installer at `gh.io` may also be blocked. Both skip gracefully and print:
```
Install manually once off the corporate network:
  curl -fsSL https://claude.ai/install.sh | bash
```

## Idempotency

- **Linker**: `symlink_points_to()` skips already-correct entries. Pre-scan fast path ("All N entries already linked") returns early without creating a backup dir.
- **Packages**: `apt-get install -y`, `pacman -S --noconfirm --needed`, `yum install -y` are idempotent by design.
- **`ensure_zsh_default_shell`**: checks current shell before calling `chsh`.
- **`neovim_nightly`**: GitHub API mtime check — skips download if binary is current.
- **`install_helix`**: compares `hx --version` against latest GitHub release tag. Fail-open: re-installs if version cannot be parsed.
- **`install_nerd_fonts`**: checks `fc-list` output for `JetBrainsMono.*Nerd` before downloading.
- **`checkinstall` RHEL**: EPEL/CRB setup runs once per session, guarded by `_DOTFILES_CHECKINSTALL_RHEL_INIT`.
- **p10k.local.zsh**: template copy is guarded by `[[ ! -f "$p10k_local" ]]` — never overwrites user edits.

## Fonts (`fonts.sh`)

`install_nerd_fonts()` installs JetBrainsMono Nerd Font:

- **Native Linux**: downloads `JetBrainsMono.zip` from `github.com/ryanoasis/nerd-fonts` releases, unzips to `~/.local/share/fonts/JetBrainsMono/`, runs `fc-cache -f`. Non-fatal on network failure.
- **WSL**: skips Linux install (Linux fonts are not used by Windows-based terminal renderers); prints a PowerShell `winget` one-liner and download URL instead.
- **No `fc-cache`**: if `fontconfig` is absent, font files are installed and a manual run hint is printed.

`unzip` is a prerequisite (in `basic-packages.sh`). If absent the step is skipped with a retry hint.

## p10k.local.zsh provisioning (link phase)

After the link phase creates `~/.config/zsh → <dotfiles>/config/core/zsh`, `initiate.sh` checks whether `~/.config/zsh/p10k.local.zsh` exists. If not, it copies the template:

```bash
cp ~/.config/zsh/p10k.local.zsh.template ~/.config/zsh/p10k.local.zsh
```

The copy lands inside the repo directory (the dir is a symlink, not a copy) and is gitignored. This means Nerd Font settings are active from the first `exec zsh` — no manual template copy needed. Existing files are never overwritten.

## Profile switching internals

1. Previous profile read from `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/active-profile`.
2. `unlink_removed_entries()` — removes symlinks pointing into the dotfiles repo for entries absent in the new profile. Never touches user-created symlinks.
3. `unlink_hook_entry()` — for `_install.sh`-managed entries: scans `$dest_dir/<basename>/` for symlinks resolving into the old source, removes them, prunes empty dirs.
4. `purge_switch_residues()` — deletes zsh compdump files, `$XDG_CACHE_HOME/<basename>/` dirs, and zinit plugin dirs (`*---<basename>`) for each removed entry.
5. `validate_no_optional_in_minimal()` — hard-aborts if `minimal.list` contains `config/optional/` entries.
6. `run_autoremove()` — runs distro autoremove when `DOTFILES_PROFILE_SWITCHED=true` at end of update phase.

State file is written before the link loop so interrupted runs leave the state correct.

## Cross-platform package names

Handled in `basic-packages.sh`:

| Package | debian | redhat | arch |
|---------|--------|--------|------|
| sqlite | `sqlite3` | `sqlite` + `sqlite-devel` | `sqlite` |
| pip | `python3-pip` | `python3-pip` | `python-pip` |
| clipboard | *(not installed)* | *(not installed)* | `xsel` |
| tar/xz | *(base)* | *(base)* | explicit `checkinstall tar` |

`xsel` is only on Arch; all usages are guarded by `command -v xsel`.

`install_helix_binary_fallback()` uses `jq` when available, falls back to `grep`+`sed` — safe to run before `basic-packages.sh`.

## Architecture support

Neovim and Helix detect `uname -m`:
- `x86_64` / `amd64` → `nvim-linux-x86_64.tar.gz` / `x86_64-linux.tar.xz`
- `aarch64` / `arm64` → `nvim-linux-arm64.tar.gz` / `aarch64-linux.tar.xz`

## Bare metal vs Docker

| Context | sudo | chsh | is_wsl() | Packages |
|---------|------|------|----------|----------|
| Bare metal (non-root) | required | yes | WSL2 only | distro pkgs first |
| Docker (root) | no-op | mocked in harness | always false | image-dependent |
| WSL2 | required | yes | true | same as bare metal |

## Harness environment isolation

The switch test passes `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, and `XDG_DATA_HOME` explicitly to prevent real user env from leaking into `purge_switch_residues()`. Any test exercising cache cleanup must also pass `XDG_CONFIG_HOME`.

`run_manifest_lint_test()` — three checks:
1. Static: `minimal.list` has no `config/optional/` entries.
2. Coverage: warns about `config/optional/` dirs absent from `full.list`.
3. Dynamic: patches a temp repo with a forbidden entry; asserts `initiate.sh link --profile minimal` exits non-zero with an error mentioning `config/optional`.
