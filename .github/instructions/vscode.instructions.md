---
applyTo: "config/core/Code/**,config/core/Code - Insiders/**"
description: "Use when: changing VS Code settings, extensions, keybindings, Copilot settings, snippets, or VS Code workspace behavior."
---

# VS Code Instructions

- Start from `config/core/Code/` or `config/core/Code - Insiders/` and stay within this domain unless the change clearly depends on shell, bootstrap, or Neovim context.
- VS Code and VS Code Insiders are treated as separate profiles; check both profiles only if the request spans both.
- Preserve the existing VS Code settings structure (`User/settings.json`, keybindings, extensions list).
- Copilot and CopilotChat configuration lives here; keep Copilot settings isolated from Neovim.
- Do not assume Neovim plugin or Lua logic applies; VS Code uses extensions, not Lua.
- Prefer lightweight validation after edits, such as JSON syntax checks or settings reload when practical.
- Do not commit unless the user explicitly asks for a commit.
