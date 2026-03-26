---
applyTo: "config/core/zsh/**,home/.zshenv,local-bin/**"
description: "Use when: changing zsh startup, zinit plugins, shell functions, completions, prompt behavior, .zshenv, or local shell helper scripts."
---

# Shell Instructions

- Start in `config/core/zsh/` and expand to `home/.zshenv` or `local-bin/` only if the shell change crosses those boundaries.
- Preserve existing zsh and zinit conventions, including plugin grouping, atload/atinit patterns, and completion layout.
- Fix shell issues at the correct layer: startup files, plugin declarations, completions, or local helpers.
- Be careful with WSL and missing system dependencies; guard optional shell behavior when practical.
- Prefer targeted zsh syntax checks after editing shell files.
- For zinit `gh-r` entries that download a raw binary (not a tarball), always add `atclone'chmod +x <name>' atpull'chmod +x <name>'` — `mv` renames but does not set the execute bit. Archive-based entries (with `pick'*/name'`) are unaffected because tar preserves the bit.
- Do not define aliases that shadow bootstrap-installed binaries. For example, `alias hx="helix"` was removed because bootstrap installs the `hx` binary at `~/.local/bin/hx` — the alias caused `zsh: command not found: helix`. Rule: if bootstrap (or any `gh-r` zinit entry) installs a binary by a specific name, do not alias that name to a different command.
- After bootstrap, installed binaries (`hx`, `nvim`, `tldr`, etc.) are only on PATH in a **zsh session** — `.zshenv` adds `~/.local/bin` to PATH when zsh starts. The bootstrap bash session does not have this. New users must run `exec zsh` before testing installed tools.
- Do not pull in desktop or editor context unless the shell behavior clearly integrates with them.

## Zinit patterns

- For `gh-r` raw binaries: add `atclone'chmod +x <name>' atpull'chmod +x <name>'`. Archive-based entries (with `pick"dir/binary"`) don't need this — tar preserves the execute bit.
- Always use `lucid` to suppress the download banner.
- Use `wait'1'` by default. `wait'0a'`/`wait'0b'`/`wait'0c'` are reserved for prompt, completion, and syntax-highlighting — do not promote a new plugin into `wait'0'`.
- Core plugins go above the `if full` block; optional-tool plugins go inside it.
- Core plugins go above the optional block; optional-tool plugins go inside it.

## Optional-tool zinit plugins

`DOTFILES_ACTIVE_PROFILE` is loaded at the top of `pluginlist.zsh` from `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/active-profile`, defaulting to `minimal` on first run.

All optional-tool zinit blocks must live inside:

```zsh
if [[ "$DOTFILES_ACTIVE_PROFILE" != "minimal" ]]; then
    # add new optional-tool zinit blocks here
fi
```

This loads optional plugins for `full` and any custom profile, but keeps `minimal` bare. Do not use per-tool symlink guards — put the block here instead.

To add a new optional-tool plugin: (1) add config to `config/optional/<name>/`, (2) add `config/optional/<name>` to `full.list` only, (3) add the zinit block inside the optional guard, (4) run the harness. See `docs/DEVELOPMENT.md` for full templates and guard-verification commands.

## System packages

System packages go in `scripts/basic-packages.sh`, which branches on `whichdistro()` (`debian` / `redhat` / `arch`). Always update all three branches — package names differ (e.g. `sqlite3` on Debian, `sqlite` on RHEL/Arch). Use `checkinstall <pkg>` — never call `apt-get`/`yum`/`pacman` directly.
