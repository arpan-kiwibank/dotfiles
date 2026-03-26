---
applyTo: "config/core/nvim/**,config/optional/Code/**,config/optional/Code - Insiders/**"
description: "Use when: changing Neovim config, VS Code settings, Copilot or CopilotChat editor integration, plugin setup, snippets, or editor-specific behavior."
---

# Editor Instructions

- Treat Neovim and VS Code as separate editor domains; inspect both only when the request is editor-wide.
- For Neovim changes, start from `config/core/nvim/` and preserve the existing Lua plugin/config structure.
- For VS Code changes, stay inside `config/optional/Code/` or `config/optional/Code - Insiders/` unless the task clearly requires Neovim context too.
- Keep editor changes scoped to editor behavior; do not use bootstrap or shell edits as the first resort.
- Prefer lightweight validation after edits, such as syntax checks or plugin-list sanity checks when practical.
