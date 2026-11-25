import UIKit

/// The part of `UIMenuBuilder` this package uses.
///
/// `UIMenuBuilder` gains requirements with every SDK (iOS 26 alone added a dozen), so a test
/// double conforming to it would break on each Xcode release. Placement talks to this narrow
/// port instead, and `UIMenuBuilderAdapter` forwards it to the real builder.
protocol MenuBarBuilding {
    /// False for context menus and other builds that are not the application menu.
    var buildsMainMenu: Bool { get }
    /// The whole menu as built so far, for finding the commands a new menu must not repeat.
    var rootMenu: UIMenu? { get }

    func contains(menu identifier: UIMenu.Identifier) -> Bool
    func replace(menu identifier: UIMenu.Identifier, with menu: UIMenu)
    func remove(menu identifier: UIMenu.Identifier)
    func insert(_ menu: UIMenu, before identifier: UIMenu.Identifier)
    func appendToRoot(_ menu: UIMenu)
}

struct UIMenuBuilderAdapter: MenuBarBuilding {
    let builder: UIMenuBuilder

    var buildsMainMenu: Bool {
        builder.system == .main
    }

    var rootMenu: UIMenu? {
        builder.menu(for: .root)
    }

    func contains(menu identifier: UIMenu.Identifier) -> Bool {
        builder.menu(for: identifier) != nil
    }

    func replace(menu identifier: UIMenu.Identifier, with menu: UIMenu) {
        builder.replace(menu: identifier, with: menu)
    }

    func remove(menu identifier: UIMenu.Identifier) {
        builder.remove(menu: identifier)
    }

    func insert(_ menu: UIMenu, before identifier: UIMenu.Identifier) {
        builder.insertSibling(menu, beforeMenu: identifier)
    }

    func appendToRoot(_ menu: UIMenu) {
        builder.insertChild(menu, atEndOfMenu: .root)
    }
}
