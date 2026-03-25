---
description: "Use when: changing Neovim config, VS Code settings, Copilot or CopilotChat integration, snippets, or editor plugin behavior in this dotfiles repo."
---

The task is:

${input:Describe the editor change or issue}

Work inside the dotfiles repository with an editor-first scope.

- Start in the smallest relevant editor subtree: `config/core/nvim/`, `config/core/Code/`, or `config/core/Code - Insiders/`.
- Treat Neovim and VS Code as separate editor domains and inspect both only when the request is editor-wide.
- Do not pull in shell or bootstrap context unless the editor behavior truly depends on it.
- Preserve the existing Neovim Lua structure and existing VS Code settings layout.
- Prefer lightweight validation after edits when practical.
- Do not commit unless the user explicitly asks for a commit.

At the end, summarize what changed, what was validated, and any follow-up that may still be needed.
