---
description: "Use when: changing VS Code settings, extensions, Copilot settings, keybindings, or VS Code workspace behavior in this dotfiles repo."
---

The task is:

${input:Describe the VS Code change or issue}

Work inside the dotfiles repository with a VS Code-first scope.

- Start in `config/core/Code/` or `config/core/Code - Insiders/`.
- Treat VS Code and VS Code Insiders as separate profiles; inspect both only when the request spans both.
- Copilot and CopilotChat configuration lives here; isolate it from Neovim context.
- Do not pull in Neovim context unless the task is genuinely editor-wide.
- Do not pull in shell or bootstrap context unless VS Code behavior truly depends on it.
- Prefer lightweight validation after edits, such as JSON syntax checks when practical.
- Do not commit unless the user explicitly asks for a commit.

At the end, summarize what changed, what was validated, and any follow-up that may still be needed.
