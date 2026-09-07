# Dart code identifiers

Use the naming guidance in [Effective Dart: Design](https://dart.dev/effective-dart/design). Existing project and domain conventions take priority when they are clear and consistent.

## General rules

- ASD-STE100 Simplified Technical English for code comments.
- Use the same term for the same concept throughout the code.
- Avoid abbreviations unless the abbreviation is more familiar than its full form. Capitalize accepted abbreviations correctly.
- Put the most descriptive noun last: pageCount, updateStatus, userSettingsRepository.
- Read the identifier at its call site. The code should read naturally without forcing articles into names.
- Do not use names such as theErrorList or thisUserSettings.
- Do not encode type information that the declaration already makes clear.
- Replace vague names such as data, item, value, manager, or helper when the surrounding scope does not make the meaning clear.

## Variables and properties

- Use a noun phrase for a non-boolean value: releaseMetadata, downloadProgress.
- Use a non-imperative verb phrase for a boolean value: isEnabled, hasUpdates, canRestart.
- Prefer a positive boolean name. Choose the negative form only when callers overwhelmingly use that state.
- A named boolean parameter can omit is or another verb when the call reads better: paused: false, caseSensitive: true.
- Include units when a numeric value would otherwise be ambiguous: timeoutSeconds, widthPixels.

## Functions and methods

- Use an imperative verb phrase when the main purpose is a side effect: saveSettings(), refreshWindow().
- Use a noun phrase or a non-imperative verb phrase when the main purpose is to return a value.
- Do not start a method with get by default. Use a getter, a noun phrase, or a precise verb such as fetch, download, calculate, or request.
- Use toX() when the result is an independent copy in another representation.
- Use asX() when the result is a view backed by the original object.
- Do not repeat parameter names in the method name unless that text distinguishes otherwise similar operations.

## Types and type parameters

- Name a type for the concept that its instances represent, not for the pattern used to implement it.
- Use established type-parameter conventions: E for an element, K and V for map keys and values, and R for a return type.
- Use T, S, and U when the surrounding type makes the role clear. Otherwise, use a descriptive type-parameter name.

## Review checks

- Does the name describe the value or behavior at the call site?
- Does a boolean read as a true-or-false statement?
- Does a side-effecting method read as a command?
- Does the name use the same vocabulary as related APIs and UI text?
- Would a more precise name remove the need for a comment?
