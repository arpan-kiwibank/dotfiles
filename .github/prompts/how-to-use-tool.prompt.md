---
name: "How do I use tool"
description: "Use when: asking how to use a specific tool, plugin, or command installed in this dotfiles setup. Looks up the pluginconfig, aliases, and keybindings for the named tool and fetches live tldr examples."
---

# How do I use `${input:tool:Name of the tool or plugin, e.g. zoxide, fzf, mise, pet}`?

Show me:

1. **What it does** — one sentence description
2. **Key commands / keybindings** — the most useful invocations
3. **How it's configured in this dotfiles** — read the relevant pluginconfig file at `config/core/zsh/rc/pluginconfig/` if one exists, and show any aliases or env vars set at load time
4. **Live examples** — run `tldr ${input:tool}` to fetch community examples; if tldr has no page, fall back to `${input:tool} --help | head -40`

Keep the output concise and practical.
