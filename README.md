# Arpan's dotfiles

## Overview

This repository bootstraps a Linux workspace with a profile-driven linker and a repository layout that separates active configs from optional and historical ones.

Supported stack:

- Core: zsh, neovim, tmux, git, VS Code
- Primary desktop: Hyprland, Waybar, Dunst, portal integration
- Alternate desktop: Sway
- Historical archive: retained in git as reference only

## Supported OS

- Ubuntu

## Repository layout

```text
home/        direct links into $HOME
local-bin/   links into ~/.local/bin
config/      active and optional ~/.config entries
profiles/    manifest files that define what each install profile links
scripts/     bootstrap and maintenance scripts
```

The linker no longer scans the repository tree heuristically. It links the entries declared in the profile manifests under `profiles/`.

## Install

1. Download

   ```bash
   git clone https://github.com/arpan-kiwibank/dotfiles
   cd dotfiles
   ```

1. Install

   ```bash
   ./setup.sh
   ```

## Profiles

- `full` (default): links the active stack, language-manager configs, and misc config files.
- `hypr-minimal`: links the active stack with a reduced language-manager set.

> **WSL note:** When bootstrapping inside WSL2, `config/desktop/**` entries are automatically skipped regardless of profile. Hyprland and Sway both require direct DRM/GPU access that WSL2 does not expose. The core shell, editor, git, and tool configs are linked normally. Pass `--allow-desktop` to override this behaviour.

Examples:

```bash
# default profile
./setup.sh

# reduced profile for a cleaner Hyprland setup
./setup.sh --profile hypr-minimal
```

## Dry-run verification

Use dry-run mode to verify install, link, and update phases without changing your system:

```bash
./setup.sh --dry-run
```

You can also run a single phase:

```bash
./scripts/initiate.sh link --dry-run
./scripts/initiate.sh update --dry-run
```

## Mocked update harness

Use the reusable harness below to exercise the real `update` path with mocked package, download, and archive commands inside a temporary HOME:

```bash
./scripts/test-update-harness.sh
```

Useful variants:

```bash
./scripts/test-update-harness.sh hypr-minimal
./scripts/test-update-harness.sh full
./scripts/test-update-harness.sh --keep
```

## WSL rebuild checklist

Use this checklist before and after deregistering a WSL distro.

Before wipe:

1. Ensure all repo changes are pushed:

   ```bash
   git status
   git log -1
   ```

1. Export or copy important chat notes to a file outside WSL (for example in your Windows Documents folder).
1. Record the profile you plan to bootstrap (`full` or `hypr-minimal`).

After reinstall:

1. Reinstall basic prerequisites (`git`, `curl`, `wget`) on the new distro.
1. Clone and bootstrap:

   ```bash
   git clone https://github.com/arpan-kiwibank/dotfiles
   cd dotfiles
   ./setup.sh --profile full
   ```

   > Desktop entries (`config/desktop/**`) are **not** linked in WSL — this is intentional. Pass `--allow-desktop` only if you have a specific reason.

1. Start a fresh shell session:

   ```bash
   exec zsh
   ```

1. Populate the `tldr` cache (empty on a fresh install):

   ```bash
   tldr --update
   ```

1. Validate key tooling:

   ```bash
   hx --version
   nvim --version | head -1
   git --version
   ```

1. Validate links:

   ```bash
   ls -la ~/.config/helix
   ls -la ~/.config/zsh
   ```

1. (Optional) Run a no-change verification:

   ```bash
   ./setup.sh --dry-run --profile full
   ```

## Controlled real link test

Run the link phase against a temporary HOME directory to validate actual symlink creation safely:

```bash
tmp_root=/tmp/dotfiles-real-link
mkdir -p "$tmp_root/home/.config" "$tmp_root/cache"
HOME="$tmp_root/home" XDG_CACHE_HOME="$tmp_root/cache" ./scripts/initiate.sh link --profile hypr-minimal
```

## Neovim nightly notes

The bootstrap script installs Neovim nightly from GitHub release assets and currently supports Linux architectures:

- x86_64 (amd64)
- arm64 (aarch64)

After bootstrap:

1. Start a new zsh session

   ```bash
   exec zsh
   ```

1. Install Neovim plugins

   ```bash
   nvim --headless -c 'Lazy! sync' -c 'qall'
   ```

## Supported stack table

| area | status | repo path |
| ---- | ------ | --------- |
| shell | core | `config/core/zsh`, `home/.zshenv` |
| editor | core | `config/core/nvim`, `config/core/Code` |
| terminal | core | `config/core/tmux` |
| git | core | `config/core/git`, `config/core/gh` |
| desktop | primary | `config/desktop/hypr/*` |
| desktop | alternate | `config/desktop/sway/sway` |
| optional tools | available in repo (not linked by active profiles) | `config/optional/*` |
| language managers | active | `config/lang/*` |
| misc | active | `config/misc/*` |
## Notes

- Installer hooks such as `config/core/Code/_install.sh` and `config/core/Code - Insiders/_install.sh` still run instead of plain directory symlinking.
- Existing `.linkignore` entries are still honored when they match a manifest entry or the destination basename.



