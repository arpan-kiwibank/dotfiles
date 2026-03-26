---
description: "Use when: changing Hyprland, Waybar, Dunst, portal integration, desktop keybindings, launch commands, environment.d, or other desktop-session behavior in this dotfiles repo."
---

The task is:

${input:Describe the desktop change or issue}

Work inside the dotfiles repository with a desktop-first scope.

- Start in the smallest relevant subtree under `config/desktop/` instead of loading the whole desktop stack.
- Keep the change desktop-scoped unless it clearly alters shared shell or bootstrap behavior.
- If launch commands or terminal integration are involved, inspect shell or bootstrap files only when the dependency is real.
- Preserve the existing desktop layout and avoid moving config across desktop domains.
- Do not touch optional desktop-adjacent tools unless the request explicitly includes them.
- Do not commit unless the user explicitly asks for a commit.

At the end, summarize what changed, what was validated, and any cross-domain dependencies that were actually needed.
