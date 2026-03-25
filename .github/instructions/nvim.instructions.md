---
applyTo: "config/core/nvim/**"
description: "Use when: changing Neovim config, plugins, Lua settings, snippets, lazy-lock, keybindings, or Neovim-specific editor behavior."
---

# Neovim Instructions

- Start from `config/core/nvim/` and stay within this domain unless the change clearly depends on shell, language managers, or bootstrap behavior.
- Preserve the existing Lua plugin structure (lazy.nvim ecosystem, luasnip snippets, lua/ modules).
- Do not assume VS Code or system-wide editor settings apply; Neovim is standalone.
- Prefer lightweight validation after edits, such as `lua -c "dofile(...)"` syntax checks or lazy.nvim load tests when practical.
- Test keybindings or plugin interactions locally if the change is non-trivial.
- Do not commit unless the user explicitly asks for a commit.
