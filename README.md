# Arpan's dotfiles

Bootstrap a Linux workspace in one command on Debian/Ubuntu, Fedora/RHEL, or Arch Linux.

## Install

```bash
git clone https://github.com/arpan-kiwibank/dotfiles
cd dotfiles
./setup.sh                    # minimal profile (default)
./setup.sh --profile full     # core + desktop + optional tools + misc
```

## Profiles

| Profile | What's linked |
|---------|---------------|
| `minimal` | core + misc **(default)** |
| `full` | core + desktop + optional tools + misc |

Switch at any time — cleanup is automatic:

```bash
./setup.sh --profile full      # switch to full
./setup.sh --profile minimal   # switch back
```

### Custom profiles

Create your own profile by copying the template:

```bash
cp profiles/TEMPLATE.list profiles/workstation.list
# Edit workstation.list — uncomment the entries you want
./setup.sh --profile workstation
```

Any `profiles/*.list` file is a valid profile. The harness can test them too:

```bash
./scripts/test-update-harness.sh workstation
```

## What you get

**System packages** (via distro package manager):
`zsh`, `git`, `tmux`, `curl`, `wget`, `jq`, `sqlite`, `python3-pip`, and more.

**Bootstrap tools** (installed at bootstrap alongside system packages):

| Tool | Command | How |
|------|---------|-----|
| Neovim nightly | `nvim` | GitHub releases |
| Helix | `hx` | GitHub releases / pkg manager |
| GitHub CLI | `gh` | Official pkg manager (apt/dnf/pacman/apk) |
| GitHub Copilot CLI | `copilot` | Official installer (`curl -fsSL https://gh.io/copilot-install \| bash`) |
| Claude Code | `claude` | Official installer (`curl -fsSL https://claude.ai/install.sh \| bash`) |

> First-run auth: `gh auth login`, `copilot /login`, `claude`.
> `gh` installs to the system via the distro package manager. Neovim, Helix, Copilot CLI, and Claude Code install to `~/.local/bin` for non-root users.

**Shell tools** (installed by [zinit](https://github.com/zdharma-continuum/zinit) on first zsh start):

_User-facing programs:_

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
| mmv | `mmv` | Bulk rename with glob patterns |
| translate-shell | `trans` | CLI translator |
| mocword | `mocword` | Word prediction (used by completions) |
| mise | `mise` | Polyglot version manager |
| direnv | `direnv` | Auto-load `.envrc` per directory |
| ghq | `ghq` | Structured git repo manager |
| ghg | `ghg` | Install GitHub release binaries |
| emojify | `emojify` | Replace `:emoji:` shortcodes in text |

_Shell plugins (zsh infrastructure):_

| Plugin | Purpose |
|--------|---------|
| powerlevel10k | Prompt theme |
| fast-syntax-highlighting | Command syntax colouring |
| zsh-autosuggestions | Fish-style inline suggestions |
| zsh-autocomplete | Real-time completion menu |
| zsh-completions | Extra completion definitions |
| zsh-history-substring-search | `↑`/`↓` search by typed prefix |
| zsh-abbrev-alias | Abbreviation expansion |
| zsh-autoenv | Auto-source `.autoenv.zsh` per directory |
| zsh-autopair | Auto-close brackets and quotes |
| zsh-async | Async worker framework (used by other plugins) |
| zsh-completion-generator | Generate completions from `--help` output |
| zsh-auto-notify | Desktop notification when long commands finish (non-SSH only) |
| cd-gitroot | `cd` to git repo root |
| zshmarks | Named directory bookmarks |
| zsh-git-sync | `git pull --rebase` alias helpers |
| fzf-extras | Extra fzf key bindings |
| zsh-plugin-fzf-finder | fzf-powered file finder widget |
| fzf-marks | fzf integration for zshmarks |
| fzf-zsh-completions | fzf-based tab completions |
| zsh-fzf-widgets | Additional fzf widgets (history, git, etc.) |
| emoji-cli | fzf emoji picker |
| git-extra-commands | Extra git subcommands |
| zinit-annex-readurl | zinit extension for URL-based installs |

**Optional tools** (`full` profile only):

_Config files linked by the profile:_

| Tool | What it does |
|------|-------------|
| Code | VS Code settings, extensions, keybindings |
| Code - Insiders | VS Code Insiders settings |
| pet | CLI snippet manager (`pet new`, `pet exec`, `pet search`) |
| zeno | fzf-powered snippet/completion engine (requires Deno) |
| gitui | Terminal UI for git |
| zk | Zettelkasten note manager |
| cspell | Spell checker config |
| efm-langserver | General-purpose LSP proxy for linters/formatters |
| pmy | Fuzzy completion rule engine |
| gdb | GDB init config |
| ideavim | JetBrains IdeaVim config |
| prs | Password manager CLI config |

_Additional shell plugins loaded for non-minimal profiles:_

| Plugin | Command | Purpose |
|--------|---------|---------|
| pet | `pet` | CLI snippet manager |
| zeno.zsh | — | fzf snippet/completion engine (requires Deno) |

> **WSL**: `config/desktop/**` is skipped automatically in WSL2. Pass `--allow-desktop` to override.

## Repository layout

| Path | Purpose |
|------|---------|
| `home/` | files linked into `$HOME` |
| `local-bin/` | scripts linked into `~/.local/bin` |
| `config/core/` | shell, editor, terminal, git |
| `config/desktop/` | Hyprland (`hypr/`), shared desktop tools (Waybar, Dunst, etc.) |
| `config/optional/` | repo-kept, not linked by default |
| `profiles/` | manifests controlling what gets linked |
| `scripts/` | bootstrap and maintenance scripts |

## Development

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for: dry-run, test harness, Docker distro tests, adding optional tools, and the WSL rebuild checklist.
