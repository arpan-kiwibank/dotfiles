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

**Verifying the guard works after adding:**

```bash
# Confirm the block is inside the if-block, not outside it:
grep -n 'DOTFILES_ACTIVE_PROFILE\|fi$\|@<org>/<repo>' config/core/zsh/rc/pluginlist.zsh

# Simulate a minimal switch — the plugin dir should not be created:
DOTFILES_ACTIVE_PROFILE=minimal zsh -c 'source config/core/zsh/rc/pluginlist.zsh' 2>&1 | grep -i '<name>' || echo 'OK: not loaded'

# Run the full harness (profile-switch test asserts zinit dirs are cleaned):
./scripts/test-update-harness.sh
```

## Adding a core zinit plugin

Core plugins are always loaded regardless of profile. They live in the main body of `pluginlist.zsh` above the `if [[ "$DOTFILES_ACTIVE_PROFILE" == "full" ]]` block, grouped under the nearest relevant `#----------` section comment.

**Template — gh-r binary (archive, nested path):**

```zsh
zinit wait'1' lucid \
    from"gh-r" as"program" pick"<dir-prefix>*/<binary-name>" \
    atload"source $ZHOMEDIR/rc/pluginconfig/<name>_atload.zsh" \
    light-mode for @<org>/<repo>
```

**Template — zsh plugin with config file:**

```zsh
zinit wait'1' lucid \
    atinit"source $ZHOMEDIR/rc/pluginconfig/<name>_atinit.zsh" \
    atload"source $ZHOMEDIR/rc/pluginconfig/<name>_atload.zsh" \
    light-mode for @<org>/<repo>
```

Rules:
- Use `wait'1'` unless the plugin must be available before other `wait'1'` plugins (e.g. completion init uses `wait'0b'`, prompt uses `wait'0a'`).
- Always include `lucid` to suppress the download banner.
- Do **not** add core plugins inside the `if full` block — they must load on `minimal` too.
- After adding, run `zsh -c 'zprof' 2>&1 | head -20` to check it doesn't bloat startup.

## Adding a system package

System packages go in `scripts/basic-packages.sh`. The file branches on `whichdistro()` which returns `debian`, `redhat`, or `arch`.

```bash
# Debian/Ubuntu: add to the debian checkinstall line
checkinstall zsh git tmux ... <new-pkg-debian-name>

# Fedora/RHEL: add to the redhat checkinstall line
checkinstall zsh git tmux ... <new-pkg-rhel-name>

# Arch: add to the else (arch) checkinstall line
checkinstall zsh git tmux ... <new-pkg-arch-name>
```

Package names differ across distros — always check all three branches. Common differences:

| Package | debian | redhat | arch |
|---------|--------|--------|------|
| sqlite | `sqlite3` | `sqlite` + `sqlite-devel` | `sqlite` |
| pip | `python3-pip` | `python3-pip` | `python-pip` |

After editing, run the harness to confirm correct dispatch across distros:

```bash
./scripts/test-update-harness.sh          # verifies mocked apt-get/yum/pacman calls
./scripts/test-update-harness.sh --docker # verifies on each real distro image
```

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
