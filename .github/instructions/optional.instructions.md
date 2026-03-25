---
applyTo: "config/optional/**"
description: "Use when: working on optional tool configs, repo-kept but not actively linked tools, or requests that explicitly mention config/optional/."
---

# Optional Config Instructions

- `config/optional/` is not part of the active profile surface unless the user explicitly asks to work there.
- Keep optional-tool changes isolated from core config and active profile manifests unless the task is to promote or remove an optional tool.
- If an optional config becomes linked or unlinked, inspect `profiles/` and `README.md` as needed.
- Do not use optional configs as the default place for fixes to core behavior.