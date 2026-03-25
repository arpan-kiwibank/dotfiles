---
applyTo: "config/lang/**"
description: "Use when: changing language manager configuration, mise, toolchain bootstrap, or version-manager behavior under config/lang/."
---

# Language Manager Instructions

- Keep language-manager work inside `config/lang/` unless the request clearly affects bootstrap or profile selection.
- Preserve the distinction between manager configuration and bootstrap logic.
- If a language manager must be linked differently, inspect `profiles/` rather than embedding linking assumptions into the config itself.
- Avoid unrelated editor or shell changes unless the toolchain integration explicitly depends on them.
