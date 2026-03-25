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
- Do not pull in desktop or editor context unless the shell behavior clearly integrates with them.
