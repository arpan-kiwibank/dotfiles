---
description: "Use when: changing language manager configuration, mise, toolchain bootstrap, or version-manager behavior in this dotfiles repo."
---

The task is:

${input:Describe the language manager change or issue}

Work inside the dotfiles repository with a language-manager-first scope.

- Start in `config/lang/`.
- Keep language-manager work isolated unless the request clearly affects bootstrap or profile selection.
- Preserve the distinction between manager configuration and bootstrap logic.
- If a language manager must be linked differently, inspect `profiles/` to decide manifest changes rather than embedding linking assumptions.
- Do not pull in shell or editor context unless the toolchain integration explicitly depends on it.
- Prefer lightweight validation after edits when practical.
- Do not commit unless the user explicitly asks for a commit.

At the end, summarize what changed, what was validated, and any follow-up that may still be needed.
