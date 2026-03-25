# Arpan's dotfiles

## Overview

This repository bootstraps a Linux workspace with a profile-driven linker and a repository layout that separates active configs from optional ones.

## Repository layout

```text
home/        direct links into $HOME
local-bin/   links into ~/.local/bin
config/      active and optional ~/.config entries
profiles/    manifest files that define what each install profile links
scripts/     bootstrap and maintenance scripts
```

Linking is manifest-driven from `profiles/*.list`.

## Install

```bash
git clone https://github.com/arpan-kiwibank/dotfiles
cd dotfiles
./setup.sh --profile full       # or --profile minimal
```

## Profiles

- `full` (default): links the active stack, language-manager configs, optional tools, and misc config files.
- `minimal`: links the active stack without optional tools — a leaner setup that still includes all core and desktop config.

## Switching profiles

To move from one profile to another, just re-run `setup.sh` with the new profile:

```bash
./setup.sh --profile minimal   # switching from full
./setup.sh --profile full            # switching back
```

This performs the complete switch in one step:

1. **Unlinks** config symlinks that belong only to the old profile.
2. **Cleans up** entries managed by `_install.sh` hooks (e.g. VS Code settings).
3. **Links** the new profile's entries into `$HOME`.
4. **Removes orphaned packages** via the distro's autoremove mechanism (`apt-get autoremove`, `yum autoremove`, or `pacman -Rns`).

The previously-active profile is recorded in `~/.local/share/dotfiles/active-profile` so the switch is detected automatically — no manual bookkeeping needed.

## What gets installed

**System packages** (via distro package manager):
`zsh`, `git`, `tmux`, `curl`, `wget`, `gawk`, `jq`, `unzip`, `sqlite`, `gettext`, `procps`, `python3-pip`, `gcc`

**Binaries** (downloaded from GitHub releases by bootstrap scripts):

| Tool | Command | Purpose |
|---|---|---|
| Neovim nightly | `nvim` | Text editor — nightly build, version-checked on each run |
| Helix | `hx` | Modal terminal editor |

**Shell tools** (installed by [zinit](https://github.com/zdharma-continuum/zinit) on first zsh load):

| Tool | Command | Purpose |
|---|---|---|
| zoxide | `z` | Smart `cd` replacement with frecency |
| fzf | — | Fuzzy finder; powers `Ctrl-R`, `Ctrl-T`, `Alt-C` |
| eza | `ls` | Modern `ls` with icons and git status |
| ripgrep | `rg` | Fast recursive grep |
| fd | `fd` | Fast `find` replacement |
| bat | `cat` | `cat` with syntax highlighting |
| delta | `delta` | Syntax-highlighted git diff pager |
| trashy | `rm` | Safe delete — moves to trash |
| tealdeer | `tldr` | Fast offline tldr pages |
| procs | `procs` | Modern `ps` replacement |
| mise | `mise` | Polyglot version manager (node, python, ruby…) |
| direnv | `direnv` | Auto-load `.envrc` per directory |
| gh | `gh` | GitHub CLI |
| ghq | `ghq` | Structured git repo manager |
| pet | `pet` | CLI snippet manager |
| mmv | `mmv` | Multi-file rename |
| mocword | `mocword` | Offline word prediction |
| translate-shell | `trans` | Terminal translator |

**Custom local scripts** (linked to `~/.local/bin`):

| Script | Purpose |
|---|---|
| `alarm` | Countdown alarm — fires a desktop notification (Windows toast in WSL, `notify-send` on bare metal) |
| `hyprland-wrap.sh` | Hyprland launcher wrapper (bare metal only, skipped in WSL) |

> **WSL note:** `config/desktop/**` entries are automatically skipped in WSL2 (no DRM/GPU access). Pass `--allow-desktop` to override.

## Dry-run

```bash
./setup.sh --dry-run                      # all phases
./scripts/initiate.sh link --dry-run      # link only
./scripts/initiate.sh update --dry-run    # update only
```

## Update harness

Runs the full update pipeline with mocked package managers, download commands, and archive tools in a sandboxed temporary `$HOME`:

```bash
./scripts/test-update-harness.sh              # both profiles
./scripts/test-update-harness.sh minimal
./scripts/test-update-harness.sh full
./scripts/test-update-harness.sh --keep       # keep temp dir on success
./scripts/test-update-harness.sh --docker     # + in-container distro tests
```

The harness verifies: package installs dispatched correctly, local-bin symlinks created, idempotent re-run fast-path, active-profile state file written, full profile-switch path (unlink removed entries → cache/compdump/zinit purge → autoremove), and **manifest lint** (`minimal.list` must not contain `config/optional/` entries, verified both statically and by a live runtime guard check).

The `--docker` flag additionally runs `scripts/test-docker-distro.sh` inside `fedora:latest`, `archlinux:latest`, and `debian:stable-slim` — verifying distro detection, bash syntax compatibility, and correct package manager dispatch on each platform. Requires Docker. Skips gracefully if Docker is not available.

## Bare metal Linux

Distros detected automatically via `/etc/os-release`:

| Distro family | Detected as | Package manager |
|---|---|---|
| Ubuntu / Debian | `debian` | `sudo apt-get` |
| Fedora | `redhat` | `sudo yum / dnf` |
| RHEL / CentOS 8 | `redhat` | `sudo dnf` + `epel-release` + `powertools` |
| RHEL / CentOS 9+ | `redhat` | `sudo dnf` + `epel-release` + `crb` |
| Arch Linux | `arch` | `sudo pacman` |
| Alpine | `alpine` | ❌ not supported — exits with a clear error |

`git` and `curl` are installed automatically if absent — no manual prerequisites needed.

**Sudo prompt** — `ensure_sudo()` authenticates once upfront and keeps the ticket alive for the full bootstrap run. You are prompted exactly once. Skipped when running as root or with `--dry-run`.

**Architecture** — x86_64 and aarch64 are both supported, detected automatically via `uname -m`.

**If helix or neovim fails to download** (network or proxy issues), bootstrap warns and continues. Re-run manually:

```bash
bash scripts/helix.sh
bash scripts/nvim.sh
```

## Docker (testing / CI)

Docker runs as root — `sudo` is a no-op. Fedora and Arch base images include bash and work without additional setup.

Run the harness with `--docker` to test all three supported distro families in containers:

```bash
./scripts/test-update-harness.sh --docker
```

This mounts the repo read-only and runs `scripts/test-docker-distro.sh` inside each container. Nothing is actually installed — all package managers and download tools are stubbed. Images are pulled on first run (~70–150 MB each, then cached).

## WSL rebuild checklist

**Before wipe:**

1. Push all changes: `git status && git log -1`
2. Save any notes outside WSL.
3. Note your profile (`full` or `minimal`).

**After reinstall:**

1. Install prerequisites: `sudo apt-get install -y git curl wget`
1. Clone and bootstrap:

   ```bash
   git clone https://github.com/arpan-kiwibank/dotfiles && cd dotfiles
   ./setup.sh --profile full
   ```

   > `config/desktop/**` is not linked in WSL. Pass `--allow-desktop` only if needed.

1. Start a new shell (`~/.local/bin` is on `PATH` only after zsh loads `.zshenv`):

   ```bash
   exec zsh
   ```

1. Populate the tldr cache: `tldr --update`
1. Install Neovim plugins: `nvim --headless -c 'Lazy! sync' -c 'qall'`
1. Validate: `hx --version && nvim --version | head -1`
1. (Optional) Dry-run verify: `./setup.sh --dry-run --profile full`

## Stack

| area | repo path |
|---|---|
| shell | `config/core/zsh`, `home/.zshenv` |
| editor | `config/core/nvim`, `config/core/Code` |
| terminal | `config/core/tmux` |
| git | `config/core/git`, `config/core/gh` |
| desktop (primary) | `config/desktop/hypr/*` |
| desktop (alternate) | `config/desktop/sway/sway` |
| optional tools | `config/optional/*` |
| language managers | `config/lang/*` |
| misc | `config/misc/*` |

## Notes

- `config/core/Code/_install.sh` and `config/core/Code - Insiders/_install.sh` run as installer hooks instead of plain directory symlinking. On a profile switch, `unlink_hook_entry()` cleans up these internal symlinks automatically.
- `.linkignore` entries are honoured when they match a manifest entry or destination basename.
- The active profile is persisted in `~/.local/share/dotfiles/active-profile` (XDG_DATA_HOME-aware). `setup.sh` reads this on every run and performs cleanup automatically when the profile changes.
- **`config/optional/` entries belong only in `full.list`** — never in `minimal.list`. Bootstrap enforces this at link time and the harness enforces it statically; both will abort if the rule is violated. `zsh` reads `DOTFILES_ACTIVE_PROFILE` from the same state file so optional-tool zinit plugins (pet, zeno, etc.) are not loaded at all on `minimal`.
- **Adding a new optional tool**: (1) create `config/optional/<name>/`, (2) add `config/optional/<name>` to `profiles/full.list`, (3) add any zinit plugin inside the `if [[ "$DOTFILES_ACTIVE_PROFILE" == "full" ]]` block in `config/core/zsh/rc/pluginlist.zsh`, then run the harness.

