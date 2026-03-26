# Arpan's dotfiles

Bootstrap a Linux workspace in one command on Debian/Ubuntu, Fedora/RHEL, or Arch Linux.

## Install

```bash
git clone https://github.com/arpan-kiwibank/dotfiles
cd dotfiles
./setup.sh                    # full profile (default)
./setup.sh --profile minimal  # core + desktop, no optional tools
```

## Profiles

| Profile | What's linked |
|---------|---------------|
| `full` | core + desktop + optional tools + misc |
| `minimal` | core + desktop + misc |

Switch at any time — cleanup is automatic:

```bash
./setup.sh --profile minimal   # switch from full
./setup.sh --profile full      # switch back
```

## What you get

**System packages** (via distro package manager):
`zsh`, `git`, `tmux`, `curl`, `wget`, `jq`, `sqlite`, `python3-pip`, and more.

**Editors** (downloaded from GitHub releases):

| Tool | Command |
|------|---------|
| Neovim nightly | `nvim` |
| Helix | `hx` |

**Shell tools** (installed by [zinit](https://github.com/zdharma-continuum/zinit) on first zsh start):

| Tool | Command | Purpose |
|------|---------|---------|
| zoxide | `z` | Smart `cd` with frecency |
| fzf | — | Fuzzy finder; `Ctrl-R`, `Ctrl-T`, `Alt-C` |
| eza | `ls` | Modern `ls` with icons and git status |
| ripgrep | `rg` | Fast recursive grep |
| fd | `fd` | Fast `find` replacement |
| bat | `cat` | `cat` with syntax highlighting |
| delta | `delta` | Syntax-highlighted git diffs |
| trashy | `rm` | Safe delete — moves to trash |
| tealdeer | `tldr` | Offline tldr pages |
| procs | `procs` | Modern `ps` replacement |
| mise | `mise` | Polyglot version manager |
| direnv | `direnv` | Auto-load `.envrc` per directory |
| gh | `gh` | GitHub CLI |
| ghq | `ghq` | Structured git repo manager |

**Optional tools** (`full` profile only): `pet`, `zeno`, and others in `config/optional/`.

> **WSL**: `config/desktop/**` is skipped automatically in WSL2. Pass `--allow-desktop` to override.

## Repository layout

| Path | Purpose |
|------|---------|
| `home/` | files linked into `$HOME` |
| `local-bin/` | scripts linked into `~/.local/bin` |
| `config/core/` | shell, editor, terminal, git |
| `config/desktop/` | Hyprland, Sway, Waybar, Dunst |
| `config/optional/` | repo-kept, not linked by default |
| `profiles/` | manifests controlling what gets linked |
| `scripts/` | bootstrap and maintenance scripts |

## Development

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for: dry-run, test harness, Docker distro tests, adding optional tools, and the WSL rebuild checklist.
