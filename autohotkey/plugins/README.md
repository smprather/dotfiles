# AutoHotkey Plugins

This directory is an extension point for `autohotkey/hotkeys.ahk`.

How it works:
- On startup/reload, `hotkeys.ahk` scans this directory for `*.ahk`.
- It auto-generates an include file and reloads if the plugin set changed.
- Plugins are loaded in lexical order (`10-...`, `20-...`, `99-...`).

Enable/disable:
- Enabled: filename ends with `.ahk`.
- Disabled: filename does **not** end with `.ahk` (for example: `.ahk.disabled`, `.ahk.off`).

Examples:
- `20-vpn-helper.ahk` -> enabled
- `20-vpn-helper.ahk.disabled` -> disabled

Notes:
- Keep hotkeys scoped with `#HotIf` when possible to avoid conflicts.
- Prefer numeric prefixes so load order is explicit.
- `99-personal-hotkeys.ahk.disabled` is a starter personal plugin file.
