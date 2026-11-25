import type { PluginListenerHandle } from '@capacitor/core';

/**
 * A system menu, addressed by a friendly name.
 *
 * These map onto UIKit's `UIMenu.Identifier` constants. Any raw identifier string
 * (`'com.apple.menu.file'`) is also accepted, so a menu that UIKit adds in a future
 * OS release can be targeted before this package knows a name for it.
 */
export type MenuBarSystemMenu =
  | 'application'
  | 'file'
  | 'edit'
  | 'view'
  | 'window'
  | 'help'
  | 'format'
  | 'about'
  | 'preferences'
  | 'services'
  | 'hide'
  | 'quit'
  | 'newScene'
  | 'openRecent'
  | 'close'
  | 'print'
  | 'undoRedo'
  | 'standardEdit'
  | 'find'
  | 'replace'
  | 'share'
  | 'textStyle'
  | 'spelling'
  | 'substitutions'
  | 'transformations'
  | 'speech'
  | 'lookup'
  | 'learn'
  | 'toolbar'
  | 'sidebar'
  | 'fullscreen'
  | 'minimizeAndZoom'
  | 'bringAllToFront';

/**
 * An action the system already knows how to perform and route.
 *
 * Prefer these over a plain `action` item for editing commands: they dispatch through
 * the responder chain, so the web view (or whatever is focused) handles them natively
 * and they grey out on their own when nothing can respond.
 */
export type MenuBarRole =
  | 'undo'
  | 'redo'
  | 'cut'
  | 'copy'
  | 'paste'
  | 'delete'
  | 'select'
  | 'selectAll';

/** An item that calls back into JavaScript when chosen. */
export interface MenuBarActionItem {
  type: 'action';
  /** Echoed back in the `menuItemSelected` event. Must be unique across the whole menu. */
  id: string;
  title: string;
  /**
   * Keyboard shortcut in Electron/Tauri accelerator syntax, e.g. `'CmdOrCtrl+Shift+P'`.
   *
   * Modifiers: `Cmd`/`Command`, `CmdOrCtrl`/`CommandOrControl`, `Ctrl`/`Control`,
   * `Alt`/`Option`, `Shift`. Keys: any single character, or one of `Space`, `Tab`,
   * `Enter`/`Return`, `Backspace`, `Delete`, `Escape`, `Up`/`Down`/`Left`/`Right`,
   * `Home`, `End`, `PageUp`, `PageDown`, `F1` to `F12`, `Plus`, `Minus`, `Comma`.
   *
   * An unparseable accelerator drops the shortcut; the item itself still appears.
   */
  shortcut?: string;
  /** Defaults to `true`. A disabled item is shown greyed out, not hidden. */
  enabled?: boolean;
  /** Draws a checkmark. */
  checked?: boolean;
  /** Draws the title in red (destructive styling). */
  destructive?: boolean;
  /** SF Symbol name, e.g. `'doc.badge.plus'`. Ignored if the symbol does not exist. */
  systemImage?: string;
}

/** An item wired to a standard system action instead of a JavaScript callback. */
export interface MenuBarRoleItem {
  type: 'role';
  role: MenuBarRole;
  /** UIKit does not supply a localized title when you build the item yourself. */
  title: string;
  shortcut?: string;
  enabled?: boolean;
}

/**
 * A divider.
 *
 * UIKit has no separator element; it draws dividers between inline groups. The plugin
 * turns the items between separators into those groups, so flat Electron/Tauri-style
 * lists work as is.
 */
export interface MenuBarSeparator {
  type: 'separator';
}

export interface MenuBarSubmenu {
  type: 'submenu';
  id: string;
  title: string;
  items: MenuBarItem[];
  /**
   * Top level only: take the place of this system menu instead of being appended.
   *
   * Use it to own File/Edit/View rather than sitting next to UIKit's versions. A submenu
   * without `replaces` is appended after the system menus.
   */
  replaces?: MenuBarSystemMenu | string;
}

export type MenuBarItem =
  | MenuBarActionItem
  | MenuBarRoleItem
  | MenuBarSeparator
  | MenuBarSubmenu;

export interface SetMenuOptions {
  /** Top-level menus, in the order they should appear. */
  menus: MenuBarSubmenu[];
  /** System menus to drop entirely, e.g. `['format']`. */
  removeSystemMenus?: (MenuBarSystemMenu | string)[];
}

export interface MenuItemSelectedEvent {
  /** The `id` of the chosen `action` item. */
  id: string;
}

export interface MenuBarPlugin {
  /**
   * Whether this device can show an application menu bar.
   *
   * False on web, Android and iPhone (iPhone only shows the menu in the ⌘-held overlay,
   * with a hardware keyboard). Keep an in-app menu as the fallback.
   */
  isSupported(): Promise<{ supported: boolean }>;

  /**
   * Replace the whole menu.
   *
   * Cheap to call often. Call it again whenever a title, checkmark or enabled flag
   * changes; native items don't track your app's state.
   */
  setMenu(options: SetMenuOptions): Promise<void>;

  /** Drop the custom menu and leave UIKit's default bar in place. */
  clearMenu(): Promise<void>;

  addListener(
    eventName: 'menuItemSelected',
    listenerFunc: (event: MenuItemSelectedEvent) => void,
  ): Promise<PluginListenerHandle>;

  removeAllListeners(): Promise<void>;
}
