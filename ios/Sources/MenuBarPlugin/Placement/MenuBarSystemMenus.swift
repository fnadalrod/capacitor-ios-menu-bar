import UIKit

/// Friendly names for UIKit's system menus: what `replaces` and `removeSystemMenus` accept.
///
/// Mirrors `MenuBarSystemMenu` in `src/definitions.ts`; `test/parity.test.cjs` fails when the
/// two drift apart.
enum MenuBarSystemMenus {
    /// Resolves a friendly name, falling through to a raw identifier.
    ///
    /// Unknown names are used as raw identifiers, so menus added in newer iPadOS versions
    /// (`"com.apple.menu.something-new"`) can be targeted without updating this table.
    static func identifier(named name: String) -> UIMenu.Identifier {
        identifiers[name] ?? UIMenu.Identifier(rawValue: name)
    }

    static let identifiers: [String: UIMenu.Identifier] = [
        "application": .application,
        "file": .file,
        "edit": .edit,
        "view": .view,
        "window": .window,
        "help": .help,
        "format": .format,
        "about": .about,
        "preferences": .preferences,
        "services": .services,
        "hide": .hide,
        "quit": .quit,
        "newScene": .newScene,
        "openRecent": .openRecent,
        "close": .close,
        "print": .print,
        "undoRedo": .undoRedo,
        "standardEdit": .standardEdit,
        "find": .find,
        "replace": .replace,
        "share": .share,
        "textStyle": .textStyle,
        "spelling": .spelling,
        "substitutions": .substitutions,
        "transformations": .transformations,
        "speech": .speech,
        "lookup": .lookup,
        "learn": .learn,
        "toolbar": .toolbar,
        "sidebar": .sidebar,
        "fullscreen": .fullscreen,
        "minimizeAndZoom": .minimizeAndZoom,
        "bringAllToFront": .bringAllToFront
    ]
}
