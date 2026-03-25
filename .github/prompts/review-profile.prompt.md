---
description: "Use when: reviewing full or hypr-minimal manifests, deciding what gets linked, auditing profile contents, or checking whether manifest changes also require script or README updates in this dotfiles repo."
---

The task is:

${input:Describe the profile or manifest review request}

Work inside the dotfiles repository with a manifest-first scope.

- Start in `profiles/`.
- Treat `profiles/*.list` as the source of truth for what gets linked.
- Inspect `scripts/` only when link behavior, installer hooks, or special handling are relevant.
- Check `README.md` only when the reviewed profile changes user-visible behavior or documented profile expectations.
- Treat `config/optional/` as out of scope unless the review explicitly includes optional tools.
- Prefer reporting mismatches, risks, and missing validation before suggesting broad cleanup.
- Do not commit unless the user explicitly asks for a commit.

At the end, summarize the reviewed scope, findings, affected files, and any recommended follow-up work.