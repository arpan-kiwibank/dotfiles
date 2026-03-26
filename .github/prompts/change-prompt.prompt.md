---
description: "Use when: changing the zsh prompt appearance, adding or removing prompt segments, modifying powerlevel10k config, or customizing the prompt for a specific machine."
---

The task is:

${input:Describe the prompt change or customization}

Work inside the dotfiles repository with a prompt-first scope.

- The default prompt config is `config/core/zsh/rc/pluginconfig/p10k.zsh`.
- `config/core/zsh/rc/pluginconfig/powerlevel10k_atload.zsh` wires p10k: it sources `p10k.zsh` then loads `~/.config/zsh/p10k.local.zsh` (machine-local, not in the repo).
- For machine-specific customizations, copy `config/core/zsh/p10k.local.zsh.template` → `~/.config/zsh/p10k.local.zsh` and edit there.
- Do **not** run `p10k configure` — the wizard overwrites `p10k.zsh` with its own output. Edit the file directly instead.
- After editing `p10k.zsh`, reload with: `source ~/.config/zsh/rc/pluginconfig/p10k.zsh` or `p10k reload`.
- After editing `p10k.local.zsh`, reload with: `source ~/.config/zsh/p10k.local.zsh`.
- Segments are controlled by `POWERLEVEL9K_LEFT_PROMPT_ELEMENTS` and `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS`.
- Do **not** set `PROMPT` or `RPROMPT` directly — p10k owns them.
- Run `zsh -n config/core/zsh/rc/pluginconfig/p10k.zsh` to syntax-check after editing.
- Do not pull in shell startup or bootstrap context unless the prompt behavior depends on them.
