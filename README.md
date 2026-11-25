# capacitor-ios-menu-bar

Control the native **iPadOS 26 menu bar** (and the Mac Catalyst one) from JavaScript in a
Capacitor app. Describe the menu as data and get back the id of the item the user picked.

```ts
import { MenuBar } from 'capacitor-ios-menu-bar';

await MenuBar.setMenu({
  menus: [
    {
      type: 'submenu',
      id: 'file',
      title: 'File',
      replaces: 'file',
      items: [
        { type: 'action', id: 'file.new', title: 'New Project', shortcut: 'CmdOrCtrl+N' },
        { type: 'action', id: 'file.open', title: 'Open…', shortcut: 'CmdOrCtrl+O' },
        { type: 'separator' },
        { type: 'action', id: 'file.save', title: 'Save', shortcut: 'CmdOrCtrl+S' },
      ],
    },
  ],
});

await MenuBar.addListener('menuItemSelected', ({ id }) => run(id));
```

## Install

```bash
npm install capacitor-ios-menu-bar
npx cap sync ios
```

No changes are needed inside `ios/`. Most Capacitor projects regenerate that folder and keep it
out of version control, so anything edited by hand there is lost on the next `cap add ios`. See
[How it attaches](#how-it-attaches) for how the plugin hooks in, and how to turn that off.

There is nothing to register and no framework is assumed. Import it where you build your menu:

```ts
import { MenuBar, type MenuBarSubmenu } from 'capacitor-ios-menu-bar';
```

**iOS only.** Android has no application menu bar, so there is nothing to map this onto. The
package ships no Android implementation (`cap sync android` skips it), and on Android and the
web every call resolves without doing anything. Shared startup code can call `setMenu` on every
platform; use [`isSupported()`](#platforms) when you need to branch.

## Platforms

| | Menu bar on screen | ⌘-held shortcut overlay | `isSupported()` |
|---|---|---|---|
| iPad, iPadOS 26+ | yes | no, the bar replaces it | `true` |
| iPad, iPadOS 15 to 18 | no | yes | `true` |
| Mac Catalyst | yes | no | `true` |
| iPhone | no | with a hardware keyboard | `false` |
| Android, web | no | no | `false` |

`isSupported()` tells you whether the menu will normally be reachable on this device. iPhone
returns `false` because the overlay needs a hardware keyboard. Keep your in-app menu in every
case: this covers the system chrome, not your own UI.

## Menu items

A menu is a list of top-level submenus containing four kinds of item.

### `action`

Calls back into JavaScript.

```ts
{ type: 'action', id: 'view.zen', title: 'Zen Mode', shortcut: 'CmdOrCtrl+Alt+Z',
  checked: true, enabled: true, destructive: false, systemImage: 'moon.fill' }
```

`id` is sent back in `menuItemSelected` and must be unique across the whole menu.

### `role`

Hands the command to the system.

```ts
{ type: 'role', role: 'copy', title: 'Copy', shortcut: 'CmdOrCtrl+C' }
```

Roles go through the responder chain, so the web view handles them and they are disabled
automatically when nothing can respond. Available roles: `undo`, `redo`, `cut`, `copy`,
`paste`, `delete`, `select`, `selectAll`.

A role can live next to the system Edit menu even though both use the same action. Each role
command gets its own property list, which is how UIKit tells them apart. Its shortcut still has
to be free (see [Shortcuts](#shortcuts)).

For undo/redo and the standard editing commands, keeping the system Edit menu is usually the
better choice: it is already translated into every language iPadOS supports.

### `separator`

```ts
{ type: 'separator' }
```

UIKit has no separator element. It draws dividers between inline groups, so the plugin turns
the items between separators into those groups. A flat list like the ones Electron and Tauri
use works as is. Leading, trailing and repeated separators are ignored.

### `submenu`

Can be nested. At the top level it accepts one extra key:

```ts
{ type: 'submenu', id: 'file', title: 'File', replaces: 'file', items: [...] }
```

`replaces` names a system menu to replace: `'file'`, `'edit'`, `'view'`, `'window'`, `'help'`
and the rest of `MenuBarSystemMenu`. A raw `UIMenu.Identifier` string such as
`'com.apple.menu.something-new'` also works, for menus added in newer iPadOS versions. Without
`replaces`, the submenu is added before Help.

If the menu named in `replaces` does not exist in the current build, the submenu is added
instead. (UIKit's own `replace` does nothing in that case.)

To drop system menus altogether, pass their names in `removeSystemMenus`:

```ts
await MenuBar.setMenu({ menus, removeSystemMenus: ['format'] });
```

### Shortcuts

Shortcuts use the Electron/Tauri accelerator syntax, e.g. `'CmdOrCtrl+Shift+P'`.

- Modifiers: `Cmd` / `Command`, `CmdOrCtrl` / `CommandOrControl`, `Ctrl` / `Control`,
  `Alt` / `Option`, `Shift`.
- Keys: any single character, or `Space`, `Tab`, `Enter` / `Return`, `Backspace`, `Delete`,
  `Escape`, `Up` / `Down` / `Left` / `Right`, `Home`, `End`, `PageUp`, `PageDown`, `F1` to `F12`,
  `Plus`, `Minus`, `Comma`.

If an accelerator can't be parsed, the item is kept without a shortcut.

Once a key combination is in the menu, the system handles it before the web view does, so a
`keydown` listener for the same combination stops firing. macOS behaves the same way.

**Each shortcut can be used by one item only.** If any shortcut in a menu is already on the
bar, UIKit drops that entire menu and only writes a line to the log. The system menus you keep
already use some common ones: ⇧⌘Z (Redo), ⌥⌘F (Find & Replace), ⌘A (Select All). The plugin
checks for this before handing the menu over: the item keeps its place, loses the shortcut, and
the log says which item owns it. The first one wins, including between your own menus. To use
one of those shortcuts, take the system menu off the bar with `replaces: 'edit'` or
`removeSystemMenus: ['edit']`. A repeated `id` is handled the same way: the second item is
dropped and the rest of the menu stays.

## Updating the menu

UIKit builds the main menu once and only rebuilds it when asked. Items don't track your app's
state, so a checkmark, an enabled flag or a title won't change on its own. Call `setMenu` again
whenever they should:

```ts
effect(() => MenuBar.setMenu({ menus: buildMenus(state()) }));
```

The call is cheap. Titles are plain strings, so rebuild the menu when the user switches language.

## How it attaches

UIKit builds the menu bar by calling `buildMenu(with:)` on the app delegate. It is a
`UIResponder` method, and a Capacitor plugin is not in the responder chain, so the override has
to be added to the delegate's class.

By default the plugin adds it at runtime when it loads, then asks UIKit to rebuild. If your
delegate already implements `buildMenu(with:)`, that implementation is wrapped and still runs
first.

To do it by hand instead, turn the automatic install off:

```ts
// capacitor.config.ts
plugins: {
  MenuBar: { autoInstall: false },
}
```

and call the controller from your delegate:

```swift
// AppDelegate.swift
import CapacitorIosMenuBar

override func buildMenu(with builder: UIMenuBuilder) {
    super.buildMenu(with: builder)
    MenuBarController.shared.build(with: builder)
}
```

This only works as written with CocoaPods. With Swift Package Manager (the default since
Capacitor 7) the `App` target links just the generated `CapApp-SPM` package, so the import fails
with *unable to resolve module dependency* unless you add the plugin package to the `App` target
yourself. On SPM projects, use the automatic install.

## Using it without Capacitor

Only `MenuBarPlugin` (the bridge) imports Capacitor. A UIKit app can build the menu in Swift and
use the controller directly:

```swift
let descriptor = MenuBarDescriptor(menus: [
    MenuBarSubmenu(id: "file", title: "File", items: [
        .action(MenuBarAction(id: "file.new", title: "New", shortcut: MenuBarShortcut(accelerator: "CmdOrCtrl+N"))),
        .separator,
        .role(MenuBarRoleItem(role: .copy, title: "Copy")),
    ], replaces: "file"),
])

MenuBarController.shared.onSelect = { id in print(id) }
MenuBarController.shared.setMenu(descriptor)
```

The module is `MenuBarPlugin` with Swift Package Manager and `CapacitorIosMenuBar` with
CocoaPods. The package still depends on Capacitor's binary.

## Troubleshooting

When something goes wrong the plugin logs it to the unified log:

```bash
log stream --predicate 'subsystem == "capacitor-ios-menu-bar"' --level debug
# on a simulator:
xcrun simctl spawn booted log stream --predicate 'subsystem == "capacitor-ios-menu-bar"'
```

At launch you should see an `Installed` line, and a `Contributed N menu(s)` line each time UIKit
rebuilds the menu. No `Installed` line means the app delegate could not be reached. `Installed`
without `Contributed` means `setMenu` was never called or the menu was empty.

Items that fail to decode (unknown `type`, unknown `role`, missing `id`) are dropped one by one
and the rest of the menu still shows. Shortcuts that are already taken are logged with the name
of the item that owns them.

UIKit reports its own menu errors under the `MenuBuilder` category. If one shows up, please open
an issue with the log line:

```bash
xcrun simctl spawn booted log stream --predicate 'category == "MenuBuilder"'
```

## API

See [`src/definitions.ts`](src/definitions.ts): `isSupported()`, `setMenu()`, `clearMenu()` and
`addListener('menuItemSelected', …)`.

## Requirements

- Capacitor 8+, iOS 15+
- Xcode 26+ to build
- The menu bar itself needs iPadOS 26 or Mac Catalyst. Earlier iPadOS versions show the menu in
  the ⌘-held overlay.

## Development

```bash
git clone https://github.com/fnadalrod/capacitor-ios-menu-bar.git
cd capacitor-ios-menu-bar
npm install
npm run test:web         # TypeScript build and JavaScript tests
npm run test:ios         # Swift tests on a simulator (an iPad if one is installed)
npm run verify           # both, as in CI
```

The Swift code builds and tests without a host app. Layout of `ios/Sources/MenuBarPlugin/`:

| Folder | Contents |
|---|---|
| `Bridge/` | The Capacitor plugin: reads the call, passes it on, emits `menuItemSelected`. The only file that imports Capacitor. |
| `Descriptor/` | The menu model, decoded from JSON, and accelerator parsing. |
| `Rendering/` | Turns items into `UIMenuElement`s (commands, key commands, separator groups) and tracks which shortcuts and commands are already taken. |
| `Placement/` | Decides where each top-level menu goes: replacing a system menu or before Help. |
| `Installation/` | Adds `buildMenu(with:)` to the app delegate at runtime. |
| `MenuBarController.swift` | Holds the current menu and forwards selections. |

Placement uses `MenuBarBuilding`, a small protocol over `UIMenuBuilder`. `UIMenuBuilder` gains
new requirements with each SDK, so a test double of it would break with every Xcode release.

`test/parity.test.cjs` checks that the system menu names and roles in `src/definitions.ts` match
the Swift tables, and that the native package names match what `cap sync` expects.

### Testing in an app

Install the plugin from your local checkout. `cap sync` follows the symlink and adds the package
to `CapApp-SPM/Package.swift`; after editing the plugin, sync again:

```bash
cd ../your-app
npm install ../capacitor-ios-menu-bar
npm run build && npx cap sync ios
```

Debug-level logs are not kept unless you enable them:

```bash
xcrun simctl spawn booted log config --subsystem capacitor-ios-menu-bar --mode "level:debug,persist:debug"
xcrun simctl spawn booted log stream --predicate 'subsystem == "capacitor-ios-menu-bar"'
```

A normal run logs `Installed: added buildMenu(with:) to AppDelegate`, then
`Received N menu(s) from JavaScript`, then `Contributed N menu(s) to the main menu`.

The last line can take a while. After `setMenu`, UIKit rebuilds the menu the next time the bar is
shown, not straight away. On the simulator, drag down from the top edge to show it.

### Test status

Tested on the iPad simulator (iPadOS 26.5) in a Capacitor 8 app: custom, replaced and removed
menus, SF Symbols, shortcuts, checkmarks, disabled and destructive items, selection and keyboard
shortcuts reaching JavaScript, and updating titles with a second `setMenu`.

Not tested yet: physical devices, Mac Catalyst, iPhone, iPadOS before 26, CocoaPods projects,
and choosing a `role` item. Issues and reports are welcome.

## License

MIT
