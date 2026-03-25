---
description: "Use when: working on optional tool configs, repo-kept but not actively linked tools, or tooling that should stay in config/optional/ in this dotfiles repo."
---

The task is:

${input:Describe the optional tool change or issue}

Work inside the dotfiles repository with an optional-tools-first scope.

- Start in `config/optional/`.
- Remember that optional tools are not part of the active profile surface unless user explicitly asks to link them.
- Keep optional-tool changes isolated from core config and active profile manifests.
- If the task is to promote an optional config to active profile status, inspect `profiles/` and `README.md` to decide manifest changes.
- Do not use optional configs as the default place for fixes to core behavior.
- Do not pull in shell or bootstrap context unless the optional tool integration explicitly depends on it.
- Prefer lightweight validation after edits when practical.
- Do not commit unless the user explicitly asks for a commit.

At the end, summarize what changed, what was validated, and any follow-up that may still be needed.
