import UIKit

@testable import MenuBarPlugin

/// A menu build that starts with a chosen set of system menus and records what was done to it.
///
/// Its Edit menu carries the two commands that real apps collide with: Redo on ⇧⌘Z and
/// Select All on ⌘A.
final class RecordingMenuBuilder: MenuBarBuilding {
    enum Operation: Equatable {
        case replace(UIMenu.Identifier, title: String)
        case remove(UIMenu.Identifier)
        case insertBefore(UIMenu.Identifier, title: String)
        case appendToRoot(title: String)
    }

    let buildsMainMenu: Bool
    private(set) var operations: [Operation] = []
    /// The menus this package handed over, in order.
    private(set) var placed: [UIMenu] = []
    private var topLevel: [UIMenu]

    init(systemMenus: [UIMenu.Identifier] = [.file, .edit, .help], buildsMainMenu: Bool = true) {
        self.topLevel = systemMenus.map(Self.systemMenu(_:))
        self.buildsMainMenu = buildsMainMenu
    }

    var rootMenu: UIMenu? {
        UIMenu(title: "", children: topLevel)
    }

    func contains(menu identifier: UIMenu.Identifier) -> Bool {
        topLevel.contains { menu in menu.identifier == identifier }
    }

    func replace(menu identifier: UIMenu.Identifier, with menu: UIMenu) {
        operations.append(.replace(identifier, title: menu.title))
        placed.append(menu)
        topLevel = topLevel.map { existing in existing.identifier == identifier ? menu : existing }
    }

    func remove(menu identifier: UIMenu.Identifier) {
        operations.append(.remove(identifier))
        topLevel.removeAll { menu in menu.identifier == identifier }
    }

    func insert(_ menu: UIMenu, before identifier: UIMenu.Identifier) {
        operations.append(.insertBefore(identifier, title: menu.title))
        placed.append(menu)
        topLevel.insert(menu, at: topLevel.firstIndex { existing in existing.identifier == identifier } ?? topLevel.endIndex)
    }

    func appendToRoot(_ menu: UIMenu) {
        operations.append(.appendToRoot(title: menu.title))
        placed.append(menu)
        topLevel.append(menu)
    }

    private static func systemMenu(_ identifier: UIMenu.Identifier) -> UIMenu {
        guard identifier == .edit else {
            return UIMenu(title: identifier.rawValue, identifier: identifier, children: [])
        }

        return UIMenu(title: "Edit", identifier: .edit, children: [
            UIKeyCommand(title: "Redo", action: NSSelectorFromString("redo:"), input: "z", modifierFlags: [.command, .shift]),
            UIKeyCommand(title: "Select All", action: #selector(UIResponderStandardEditActions.selectAll(_:)), input: "a", modifierFlags: .command)
        ])
    }
}
