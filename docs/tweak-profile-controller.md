# Tweak and profile controller

The controller applies optimization profiles and individual tweaks through one path. Profiles are preset groups. Tweaks can still be enabled, disabled, verified, and rolled back one at a time.

The UI route is `/tweaks/controller`.

## Profiles

Profiles:

- `compatibility`
- `gaming`
- `performance`
- `extreme`

Use `gaming` for the first real PC pass. Use `performance` and `extreme` only after a VM pass. Do not combine host testing with `--include-dangerous` until rollback has been checked in a snapshot-backed VM.

Commands:

```powershell
revitool profile list
revitool profile apply <compatibility|gaming|performance|extreme> [--dry-run] [--yes] [--include-dangerous] [--ignore-overrides] [--json]
revitool profile status [--json]
revitool profile rollback [--last|--application <id>] [--json]
```

Notes:

- `--dry-run` plans the profile without applying changes.
- `--yes` confirms non-interactive execution.
- `--include-dangerous` only allows dangerous tweaks when paired with `--yes`.
- `--ignore-overrides` lets a profile overwrite manual tweak choices.
- `--json` prints machine-readable output for logs or automation.

## Tweaks

Use individual tweak commands when one setting needs inspection or rollback without applying a full profile.

Commands:

```powershell
revitool tweak list [--profile <name>] [--category <name>] [--risk <risk>] [--json]
revitool tweak enable <id> [--dry-run] [--yes] [--include-dangerous] [--json]
revitool tweak disable <id> [--dry-run] [--json]
revitool tweak verify <id> [--json]
revitool tweak rollback <id> [--json]
```

Rules:

- `tweak enable <id>` turns on the optimization.
- `tweak disable <id>` rolls the tweak back to the compatible state.
- Dangerous tweaks stay pending unless `--include-dangerous --yes` is present.
- Blocked tweaks report a reason instead of applying.

## Reports

Controller reports are stored locally with rollback state.

```powershell
revitool report [--last] [--json]
```

Use `report --last --json` after a dry run or profile application when the output needs to be kept with validation notes.

## First pass on a real PC

Run only after the local build has passed in a clean VM.

```powershell
& "$env:ProgramFiles\Revision Tool\revitool.exe" profile apply gaming --dry-run --json
& "$env:ProgramFiles\Revision Tool\revitool.exe" profile apply gaming --yes
& "$env:ProgramFiles\Revision Tool\revitool.exe" profile status --json
```

Check login, internet, audio, Windows Update, Store, Xbox, Game Pass, and rollback before moving to a stronger profile.
