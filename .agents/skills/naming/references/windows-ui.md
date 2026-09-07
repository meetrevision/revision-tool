# Windows-style UI text

Use the visual language of Windows Settings and ASD-STE100 Simplified Technical English. Keep official Windows, product, feature, and option names unchanged.

## Voice and structure

- Use sentence case. Capitalize only the first word and proper names: Color theme, Memory integrity, Windows Update.
- Use active voice, simple present tense, and direct instructions.
- Use one action or topic per sentence.
- Keep procedural sentences to 20 words or fewer and descriptive sentences to 25 words or fewer.
- Do not use contractions.
- Include necessary articles such as a, an, and the.
- Use this with a clear noun when a bare pronoun could be ambiguous: This setting can reduce performance.
- Use can for capability or a possible effect. Avoid vague qualifiers such as might, possibly, and usually unless the distinction is necessary.
- Prefer turn on and turn off in user-facing text. Keep enable and disable only when they are established technical terms.

## UI element names

- Page and section titles: use a short noun phrase.
- Setting names: name the controlled feature or the state that is on when the toggle is on.
- Action names and buttons: start with a direct verb, such as Check for updates, Choose packages, or Turn off protections.
- Category-card descriptions: use a short list of concepts when a sentence adds no useful information, such as Caching, compression, and NTFS overhead.
- Setting descriptions: state the purpose first. Add a separate short sentence for an important side effect or limitation.
- Status text: state the current condition, such as Update available, No packages found, or Revision Tool is up to date.
- Dialog text: state the required action and its reason. Use a question only when the user must make a decision.

## Localization constraints

- Preserve interpolation variables, markup, escape sequences, and plural or selection syntax exactly.
- Check whether the UI adds punctuation, ellipses, a question mark, or neighboring text before you edit a fragment.
- Keep a localization key unchanged when its meaning is unchanged.
- When a meaning changes, update the key and all locale or generated-code consumers in the authorized scope.
- Use one English term consistently so translators receive a stable source phrase.

## Examples

| Avoid | Prefer |
|---|---|
| System Requirements | System requirements |
| Would you like to install the following packages? | Install these packages? |
| Drivers install through Windows Updates | Get drivers through Windows Update |
| This will have a performance impact due to constantly running in the background | Background protection can reduce performance |
| It can cause problems | This setting can cause problems |

ASD-STE100 permits established technical names and technical verbs. Treat identifiers, Windows feature names, and product-specific settings as technical terms, but keep the surrounding grammar simple and unambiguous.
