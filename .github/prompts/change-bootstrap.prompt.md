---
description: "Use when: changing setup.sh, scripts/, install or update flow, link behavior, dry-run behavior, or debugging bootstrap and manifest-driven linking in this dotfiles repo."
---

The task is:

${input:Describe the bootstrap or linking change}

Work inside the dotfiles repository with a bootstrap-first scope.

- Start in `setup.sh` or the smallest relevant file under `scripts/`.
- If install behavior or linked paths change, inspect `profiles/` as part of the task.
- Keep the fix in bootstrap or manifest logic instead of patching unrelated config where possible.
- Use dry-run or harness validation when practical.
- Check `README.md` only when user-visible setup behavior or supported profile behavior changes.
- Do not commit unless the user explicitly asks for a commit.

At the end, summarize the root cause, the files changed, the validation performed, and any remaining limitations.