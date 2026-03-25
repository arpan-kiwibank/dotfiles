---
description: "Use when: changing zsh, zinit plugins, completions, .zshenv, prompt behavior, local shell helpers, or diagnosing shell startup issues in this dotfiles repo."
---

The task is:

${input:Describe the shell change or issue}

Work inside the dotfiles repository with a shell-first scope.

- Start in `config/core/zsh/`.
- Expand to `home/.zshenv` or `local-bin/` only if the task clearly crosses those boundaries.
- Do not load editor, desktop, or bootstrap context unless the shell behavior depends on them.
- Preserve existing zsh and zinit conventions.
- Validate shell edits with targeted zsh checks when practical.
- Do not commit unless the user explicitly asks for a commit.

At the end, summarize what changed, what was validated, and any remaining risks.
