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
./setup.sh --profile full       # or --profile hypr-minimal
```

## Profiles

- `full` (default): links the active stack, language-manager configs, and misc config files.
- `hypr-minimal`: links the active stack with a reduced language-manager set.

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

Runs the `update` path with mocked package, download, and archive commands in a temporary HOME:

```bash
./scripts/test-update-harness.sh              # both profiles
./scripts/test-update-harness.sh hypr-minimal
./scripts/test-update-harness.sh full
./scripts/test-update-harness.sh --keep       # keep temp dir on success
```

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

Docker runs as root — `sudo` is a no-op. Fedora and Arch base images include bash and work without a package install step. Run the harness for a quick cross-distro check:

```bash
./scripts/test-update-harness.sh
```

## WSL rebuild checklist

**Before wipe:**

1. Push all changes: `git status && git log -1`
2. Save any notes outside WSL.
3. Note your profile (`full` or `hypr-minimal`).

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

- `config/core/Code/_install.sh` and `config/core/Code - Insiders/_install.sh` run as installer hooks instead of plain directory symlinking.
- `.linkignore` entries are honoured when they match a manifest entry or destination basename.

