# Dotfiles Workspace Instructions

This repository is organized by folder domain. When working here, inspect the smallest relevant subtree first and only expand scope when the change clearly crosses domains.

## Architecture Map

- `scripts/` and `setup.sh`: bootstrap, install, update, dry-run, and linker flow.
- `profiles/`: manifest-driven linking; active profiles are `full` and `minimal`.
- `config/core/zsh/`, `home/.zshenv`, `local-bin/`: shell behavior, zsh startup, completions, and local helpers.
- `config/core/nvim/`: Neovim editor configuration.
- `config/optional/Code/`, `config/optional/Code - Insiders/`: VS Code configuration (optional).
- `config/desktop/`: Hyprland-specific (`hypr/`) and shared desktop tools (Waybar, Dunst, GTK, fonts, input method, etc.).
- `config/lang/`: language/version managers.
- `config/misc/`: active standalone config files.
- `config/optional/`: configs kept in the repo but not linked by active profiles unless explicitly requested.

## Routing Rules

- Start with the folder directly implied by the request.
- Do not load unrelated desktop, editor, or shell context unless the task crosses those boundaries.
- If a task changes install behavior or what gets linked, inspect both `scripts/` and `profiles/`.
- If a task changes a profile's user-visible behavior, check whether `README.md` should also be updated.
- Treat `config/optional/` as out of scope unless the user explicitly asks to work there.

## Repo Conventions

- Linking is manifest-driven from `profiles/*.list`; do not assume recursive repository scanning.
- Preserve the existing folder layout; prefer routing work to the right domain over restructuring directories.
- Keep changes minimal and local to the relevant domain.
- Do not commit changes unless the user explicitly asks for a commit.

## Validation Expectations

- Bootstrap or manifest changes: prefer dry-run or harness validation before concluding.
- Shell changes: run targeted zsh syntax checks when practical.
- Editor changes: validate the changed config files with lightweight checks when practical.
- Do not fix unrelated failures outside the domain being changed.

## Cross-Domain Dependencies

- `scripts/` often depends on `profiles/`.
- `config/core/zsh/` may depend on `home/.zshenv` and `local-bin/`.
- `config/core/nvim/` and `config/optional/Code/` are separate editor domains; inspect both only when the request is editor-wide.
- `config/desktop/` changes should stay desktop-scoped unless they alter shared launch or shell behavior.