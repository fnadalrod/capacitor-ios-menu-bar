import os.log

/// Logging for the plugin.
///
/// UIKit gives no feedback when a menu can't be placed, an item is dropped on purpose or the
/// install never ran, so the plugin logs each of those cases.
///
/// Read it with:
/// `log stream --predicate 'subsystem == "capacitor-ios-menu-bar"' --level debug`
enum MenuBarLog {
    private static let logger = Logger(subsystem: "capacitor-ios-menu-bar", category: "menu")

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    /// Shows whether UIKit is calling `buildMenu(with:)` at all.
    ///
    /// Off unless you pass `--level debug`, because context menus make this fire constantly.
    static func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }
}
