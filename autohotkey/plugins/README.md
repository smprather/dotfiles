# AutoHotkey Plugins

This directory is an extension point for `autohotkey/hotkeys.ahk`.

How it works:
- On startup/reload, `hotkeys.ahk` scans `plugins/` and `custom_plugins/` for `*.ahk`.
- It auto-generates an include file and reloads if the plugin set changed.
- Plugins are loaded in lexical order (`10-...`, `20-...`, `99-...`).

Enable/disable:
- In the repo, plugins are stored as `.ahk.disabled`.
- On Windows install, `install.ps1` reads `%USERPROFILE%\dotkeys_config.toml` and
  enables configured plugins by installing them as `.ahk` in `%USERPROFILE%\autohotkey\plugins`.
- Any plugin not in the enabled list is installed as `.ahk.disabled`.
- `%USERPROFILE%\autohotkey\plugins` is installer-managed and mirrors repo plugins.
- Put personal plugins in `%USERPROFILE%\autohotkey\custom_plugins`.

Repo plugin IDs:
- `10-corp-logins` - corp credential entry helpers
- `20-mouse-wiggle` - idle mouse nudge
- `30-cisco-secure-client-vpn` - Cisco Secure Client VPN automation
- `40-password-manager` - `Ctrl+Alt+B` password manager helper
- `50-tmux-hotkeys` - tmux hotkeys
- `60-f1f2f3-as-mouse-bottons` - F1/F2/F3 mouse remaps

Notes:
- Keep hotkeys scoped with `#HotIf` when possible to avoid conflicts.
- Prefer numeric prefixes so load order is explicit.
- Plugin initialization code must run before the auto-execute `Return`; `hotkeys.ahk`
  includes the generated plugin file before `Return` so reloads fully reinitialize
  enabled plugins.
- Some fragile hotkey registrations may still live in `hotkeys.ahk` and be gated by
  plugin presence or shared globals when AHK proves unreliable for those bindings in
  included plugin files.
