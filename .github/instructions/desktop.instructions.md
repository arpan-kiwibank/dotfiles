---
applyTo: "config/desktop/**"
description: "Use when: changing Hyprland, Sway, Waybar, Dunst, portal integration, desktop keybindings, launch commands, environment.d, or other desktop-session behavior."
---

# Desktop Instructions

- Stay within the relevant desktop subtree first, such as Hyprland or Sway, instead of loading the whole desktop folder.
- Keep desktop changes desktop-scoped unless they clearly alter shared shell or bootstrap behavior.
- If a launch command or terminal integration changes, inspect shell or bootstrap files only when the dependency is real.
- Preserve the existing desktop layout and avoid moving config across desktop domains.
- Do not touch optional desktop-adjacent tools unless the request explicitly includes them.
- **WSL2 limitation:** Neither Hyprland nor Sway runs as a full compositor inside WSL2. WSL2 has no DRM/KMS GPU device (`/dev/dri/` is absent). Sway can run individual apps via WSLg (`WLR_BACKENDS=wayland WLR_RENDERER=pixman sway`) but is not a supported configuration. The bootstrap skips all `config/desktop/**` entries in WSL automatically. Do not change this behaviour without updating `scripts/initiate.sh` and `README.md`.
