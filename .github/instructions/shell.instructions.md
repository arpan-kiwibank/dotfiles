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

## Optional-tool zinit plugins

`DOTFILES_ACTIVE_PROFILE` is loaded at the top of `pluginlist.zsh` from the bootstrap state file (`${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/active-profile`), defaulting to `full` when the file does not exist (first run before bootstrap).

All zinit blocks tied to optional tools (entries in `config/optional/` that the `full` profile links but `minimal` does not) **must** live inside the guarded block:

```zsh
if [[ "$DOTFILES_ACTIVE_PROFILE" == "full" ]]; then
    # add new optional-tool zinit blocks here
fi
```

This single gate prevents zinit from re-downloading tools that were cleaned up during a profile switch. **Do not add per-tool symlink guards** (`[[ -L ~/.config/<tool> ]]`) for optional plugins — put the block inside the `full`-only section instead.

To add a new optional tool with a zinit integration:
1. Add the config dir to `config/optional/<toolname>/`.
2. Add `config/optional/<toolname>` to `profiles/full.list` (only).
3. Add the zinit block inside the `if [[ "$DOTFILES_ACTIVE_PROFILE" == "full" ]]` section in `pluginlist.zsh`.
4. Run the harness — `run_manifest_lint_test()` will catch it if you accidentally add it to `minimal.list` too.
