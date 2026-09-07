---
name: naming
description: Choose or review names for Dart code identifiers and user-facing UI text. Use when naming or renaming variables, properties, methods, types, files, settings, controls, localization keys, labels, descriptions, actions, statuses, or dialogs.
metadata:
  short-description: Name code and UI text consistently
---

# Naming

Choose names that make purpose and behavior clear at the point of use. Preserve established domain terms and public contracts unless the user requests a broader rename.

## Select the applicable guidance

- For Dart identifiers, read [references/dart-code.md](references/dart-code.md).
- For user-facing UI or localization text, read [references/windows-ui.md](references/windows-ui.md).
- Read both references when a change affects code identifiers and UI text.

## Shared decisions

- Inspect nearby names and call sites before you choose a name.
- Use one term for one concept. Do not introduce synonyms for an established term.
- Prefer familiar domain and product terminology over a novel abstraction.
- Name the user-visible concept, not an incidental implementation detail.
- Distinguish items only when the distinction helps a reader or caller.
- Keep localization keys stable when only the displayed text changes.
- Before you rename a public API, serialized field, route, database column, or localization key, trace its consumers and compatibility requirements.
- For a review, show the current name, the proposed name, and the specific ambiguity that the proposal removes.
- For an implementation, update all in-scope references and run the relevant formatter, analyzer, generator, or tests.
