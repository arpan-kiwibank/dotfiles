---
description: "Use when: changing Neovim config, Lua plugins, lazy.nvim settings, keybindings, snippets, or Neovim editor behavior in this dotfiles repo."
---

The task is:

${input:Describe the Neovim change or issue}

Work inside the dotfiles repository with a Neovim-first scope.

- Start in `config/core/nvim/`.
- Preserve the existing Lua plugin structure (lazy.nvim, luasnip, lua/ modules).
- Do not pull in VS Code context unless the task is genuinely editor-wide.
- Do not pull in shell or bootstrap context unless Neovim behavior truly depends on it.
- Prefer lightweight validation after edits, such as `lua -c "dofile(...)"` syntax checks when practical.
- Do not commit unless the user explicitly asks for a commit.

At the end, summarize what changed, what was validated, and any follow-up that may still be needed.
