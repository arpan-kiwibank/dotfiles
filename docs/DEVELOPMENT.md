# Development Reference

## Dry-run

Preview all changes without modifying the system:

```bash
./setup.sh --dry-run
./scripts/initiate.sh link --dry-run    # link only
./scripts/initiate.sh update --dry-run  # update only
```

## Test harness

Mocked pipeline in a sandboxed `$HOME`:

```bash
./scripts/test-update-harness.sh            # both profiles
./scripts/test-update-harness.sh minimal
./scripts/test-update-harness.sh full
./scripts/test-update-harness.sh --keep     # keep tmp dirs on success
./scripts/test-update-harness.sh --docker   # + in-container distro tests
```

Verifies: package dispatch, symlinks, idempotent re-run, state file, full profile-switch path (unlink → cache purge → autoremove), and manifest lint (`minimal.list` must have no `config/optional/` entries).

## Docker distro tests

```bash
./scripts/test-update-harness.sh --docker
```

Runs `scripts/test-docker-distro.sh` inside `fedora:latest`, `archlinux:latest`, and `debian:stable-slim`. Nothing is installed — all package managers and download tools are stubbed. Images are pulled on first run (~70–150 MB each, then cached). Skips gracefully when Docker is unavailable.

## Supported distros

| Distro | Detected as | Package manager |
|--------|-------------|-----------------|
| Ubuntu / Debian | `debian` | `apt-get` |
| Fedora / RHEL / CentOS | `redhat` | `yum` / `dnf` |
| Arch Linux | `arch` | `pacman` |
| Alpine | `alpine` | ❌ not supported |

`git` and `curl` are installed automatically if absent — no manual prerequisites needed.

## Adding an optional tool

1. Create `config/optional/<name>/` with the tool's config.
2. Add `config/optional/<name>` to `profiles/full.list` only — never `minimal.list`.
3. Add the zinit block inside the `if [[ "$DOTFILES_ACTIVE_PROFILE" == "full" ]]` section in `config/core/zsh/rc/pluginlist.zsh`. See the template below.
4. Run `./scripts/test-update-harness.sh` — the manifest lint test catches accidental `minimal.list` additions.

**If the tool is a GitHub Release binary** (most common):

```zsh
# <description>
zinit wait'1' lucid \
    from"gh-r" as"program" pick"<binary-name>" \
    atclone'chmod +x <binary-name>' atpull'chmod +x <binary-name>' \
    atload"source $ZHOMEDIR/rc/pluginconfig/<name>_atload.zsh" \
    for @<org>/<repo>
```

> `atclone'chmod +x'` + `atpull'chmod +x'` are required for raw binaries (not archives). Archive-based entries (with `pick"dir/binary"`) are unaffected because tar preserves the execute bit.

**If the tool is a zsh-only plugin** (no binary):

```zsh
zinit wait'1' lucid \
    atload"source $ZHOMEDIR/rc/pluginconfig/<name>_atload.zsh" \
    light-mode for @<org>/<repo>
```

**Verifying the guard works:** run `./scripts/test-update-harness.sh` — the profile-switch test asserts zinit dirs for removed entries are cleaned.

## Adding a core zinit plugin

Core plugins live in the main body of `pluginlist.zsh` above the `if full` block, under the nearest `#------` section comment. Use the same templates as above but **outside** the guard. Use `wait'1'` by default (`wait'0a'`/`wait'0b'`/`wait'0c'` are reserved for prompt/completion/syntax-highlighting). Always include `lucid`.

## Adding a system package

Add to `scripts/basic-packages.sh`, updating all three distro branches (`debian`/`redhat`/`arch`). Use `checkinstall <pkg>` — never call package managers directly. Package names differ (e.g. `sqlite3` on Debian, `sqlite` on RHEL/Arch). Run the harness after editing.

## Adding a bootstrap tool (standalone script)

Bootstrap tools are installers that live in `scripts/` and are sourced from the `update` phase of `scripts/initiate.sh`. The existing examples are `gh.sh`, `helix.sh`, `nvim.sh`, and `ai-tools.sh`.

1. Create `scripts/<name>.sh` with `set -euo pipefail`, `source utils.sh`, and an idempotent install function.
2. Check if already installed using the **exact binary path** (e.g. `$HOME/.local/bin/<name>`), not `command -v`, to avoid false positives from shadowed names (see `ai-tools.sh` for the pattern).
3. Make network failures **non-fatal**: capture curl exit codes with `|| exit_code=$?` and print a manual-install hint on failure. Never let curl errors propagate through `set -e` into the parent bootstrap.
4. Add `source "$current_dir"/<name>.sh` and the function call in `initiate.sh`'s `is_update` block, after `basic-packages.sh` and before `nvim.sh`.
5. Add a dry-run guard: `if is_dry_run; then print_notice "[dry-run] ..."; return 0; fi`.
6. Add the tool to the `README.md` bootstrap tools table.
7. Run `bash scripts/test-update-harness.sh` — harness passes as-is since the curl mock covers network calls; add a specific `assert_file_contains` only if you want to verify the new curl URL was invoked.

## WSL rebuild checklist

**Before wipe:** `git status && git log -1` — push all changes. Note your profile.

**After reinstall:**

```bash
sudo apt-get install -y git curl wget
git clone https://github.com/arpan-kiwibank/dotfiles && cd dotfiles
./setup.sh --profile full
exec zsh
# Authenticate tools that require first-run login:
gh auth login
copilot /login           # GitHub Copilot CLI (only if installed — may be blocked by corporate proxy)
# claude                 # Claude Code (only if installed — may be blocked by corporate proxy)
tldr --update
nvim --headless -c 'Lazy! sync' -c 'qall'
hx --version && nvim --version | head -1
```

> `config/desktop/**` is not linked in WSL. Pass `--allow-desktop` only if needed.
>
> **Nerd Font (WSL):** `scripts/fonts.sh` detects WSL and skips the Linux install; it prints a PowerShell one-liner (`winget install --id DEVCOM.JetBrainsMonoNerdFont`) instead. Run that on the Windows side, then set your terminal font to `JetBrainsMono Nerd Font Mono`.
>
> **Corporate proxy (Zscaler):** `claude.ai` and `gh.io` may be blocked. If `copilot` or `claude` are missing after setup, install manually on a non-proxied connection:
> ```bash
> curl -fsSL https://gh.io/copilot-install | bash
> curl -fsSL https://claude.ai/install.sh | bash
> ```
> The Nerd Font download also goes through GitHub Releases and may be blocked. Re-run `bash scripts/fonts.sh` once off proxy.

## Notes

- **VS Code / Insiders hooks**: `_install.sh` symlinks individual settings files rather than the whole directory. `unlink_hook_entry()` cleans these automatically on profile switch.
- **`.linkignore`**: entries in this file are skipped by the linker when they match a manifest entry or destination basename.
- **State file**: the active profile is persisted at `~/.local/share/dotfiles/active-profile` (XDG_DATA_HOME-aware). `setup.sh` reads this on every run and performs cleanup automatically when the profile changes.
- **Binary re-install**: if Helix or Neovim fail to download, re-run `bash scripts/helix.sh` or `bash scripts/nvim.sh`. Both are idempotent.
