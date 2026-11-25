# Changelog

## 0.1.0 (2026-11-25)

Initial release.

- Set the application menu from JavaScript as plain data and receive the `id` of the chosen item.
- Hooks into the app delegate at runtime, so no changes are needed inside `ios/`.
- Accepts Electron/Tauri accelerator strings (`'CmdOrCtrl+Shift+P'`) and flat item lists with
  `separator` entries.
- Replaces system menus by name (`replaces: 'file'`) or adds menus before Help. If the named
  system menu doesn't exist, the menu is added instead of being lost.
- Items that fail to decode are dropped individually; the rest of the menu still shows.
- Shortcuts already used on the bar are removed from the new item and logged, because UIKit
  would otherwise reject the whole menu. Role items get their own property list so they can
  coexist with the system Edit menu.
- Menus can also be built in Swift: every item type has a public initializer.
- Calls do nothing on Android and the web, so shared code can call them on every platform.

Tested on the iPad simulator (iPadOS 26.5) in a Capacitor 8 app. See *Test status* in the
README for what is not covered yet.
