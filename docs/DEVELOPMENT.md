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
3. Add any zinit plugin inside the `if [[ "$DOTFILES_ACTIVE_PROFILE" == "full" ]]` block in `config/core/zsh/rc/pluginlist.zsh`.
4. Run `./scripts/test-update-harness.sh` — the manifest lint test catches accidental `minimal.list` additions.

## WSL rebuild checklist

**Before wipe:** `git status && git log -1` — push all changes. Note your profile.

**After reinstall:**

```bash
sudo apt-get install -y git curl wget
git clone https://github.com/arpan-kiwibank/dotfiles && cd dotfiles
./setup.sh --profile full
exec zsh
tldr --update
nvim --headless -c 'Lazy! sync' -c 'qall'
hx --version && nvim --version | head -1
```

> `config/desktop/**` is not linked in WSL. Pass `--allow-desktop` only if needed.

## Notes

- **VS Code / Insiders hooks**: `_install.sh` symlinks individual settings files rather than the whole directory. `unlink_hook_entry()` cleans these automatically on profile switch.
- **`.linkignore`**: entries in this file are skipped by the linker when they match a manifest entry or destination basename.
- **State file**: the active profile is persisted at `~/.local/share/dotfiles/active-profile` (XDG_DATA_HOME-aware). `setup.sh` reads this on every run and performs cleanup automatically when the profile changes.
- **Binary re-install**: if Helix or Neovim fail to download, re-run `bash scripts/helix.sh` or `bash scripts/nvim.sh`. Both are idempotent.
