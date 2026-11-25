import UIKit

/// Translates descriptor items into the `UIMenuElement`s UIKit draws.
///
/// Unaware of `UIMenuBuilder`, so every rule about how an item looks can be checked by
/// inspecting the elements it returns. What the build already holds reaches it through the
/// registry, which decides whether a command or a shortcut is still free.
struct MenuBarElementFactory {
    /// The single selector every action item dispatches. See `UIResponder+MenuBar`.
    static let actionSelector = #selector(UIResponder.capacitorMenuBarItemSelected(_:))

    let registry: MenuBarCommandRegistry

    init(registry: MenuBarCommandRegistry = MenuBarCommandRegistry()) {
        self.registry = registry
    }

    /// The identifier a custom submenu is registered under, namespaced so it cannot collide with
    /// a system menu.
    static func identifier(for submenu: MenuBarSubmenu) -> UIMenu.Identifier {
        UIMenu.Identifier("capacitor.menubar.\(submenu.id)")
    }

    /// The property list a role command carries.
    ///
    /// A role shares its action with the system's own command (`selectAll:` is also Edit > Select
    /// All), and UIKit rejects the whole menu over a repeated action and property list. A
    /// property list of its own is what UIKit asks for to tell the two apart; dispatch through
    /// the responder chain ignores it.
    static func propertyList(for role: MenuBarRole) -> String {
        "capacitor.menubar.role.\(role.rawValue)"
    }

    func menu(for submenu: MenuBarSubmenu, identifier: UIMenu.Identifier) -> UIMenu {
        UIMenu(title: submenu.title, identifier: identifier, children: elements(of: submenu.items))
    }

    /// Builds a flat item list into UIKit's grouped shape.
    ///
    /// UIKit has no separator element; it draws dividers between inline submenus. Each run of
    /// items between separators becomes a `.displayInline` menu. Empty runs are dropped, so
    /// leading, trailing or repeated separators add nothing. A single run is returned flat.
    func elements(of items: [MenuBarItem]) -> [UIMenuElement] {
        let groups = items
            .split(omittingEmptySubsequences: false, whereSeparator: \.isSeparator)
            .map { run in run.compactMap(element(for:)) }
            .filter { group in !group.isEmpty }

        guard groups.count > 1 else {
            return groups.first ?? []
        }

        return groups.map { group in UIMenu(title: "", options: .displayInline, children: group) }
    }

    private func element(for item: MenuBarItem) -> UIMenuElement? {
        switch item {
        case .separator:
            return nil
        case .action(let action):
            return command(for: action)
        case .role(let role):
            return command(for: role)
        case .submenu(let submenu):
            return menu(for: submenu, identifier: Self.identifier(for: submenu))
        }
    }

    private func command(for action: MenuBarAction) -> UICommand? {
        guard registry.claimCommand(action: Self.actionSelector, propertyList: action.id, title: action.title) else {
            return nil
        }

        let image = action.systemImage.flatMap { name in UIImage(systemName: name) }
        let attributes = Self.attributes(enabled: action.enabled, destructive: action.destructive)
        let state: UIMenuElement.State = action.checked ? .on : .off

        guard let shortcut = registry.claimShortcut(action.shortcut, title: action.title) else {
            return UICommand(
                title: action.title,
                image: image,
                action: Self.actionSelector,
                propertyList: action.id,
                attributes: attributes,
                state: state)
        }

        return UIKeyCommand(
            title: action.title,
            image: image,
            action: Self.actionSelector,
            input: shortcut.input,
            modifierFlags: shortcut.modifiers,
            propertyList: action.id,
            attributes: attributes,
            state: state)
    }

    private func command(for item: MenuBarRoleItem) -> UICommand? {
        let propertyList = Self.propertyList(for: item.role)

        guard registry.claimCommand(action: item.role.selector, propertyList: propertyList, title: item.title) else {
            return nil
        }

        let attributes = Self.attributes(enabled: item.enabled, destructive: false)

        guard let shortcut = registry.claimShortcut(item.shortcut, title: item.title) else {
            return UICommand(
                title: item.title,
                image: nil,
                action: item.role.selector,
                propertyList: propertyList,
                attributes: attributes)
        }

        return UIKeyCommand(
            title: item.title,
            action: item.role.selector,
            input: shortcut.input,
            modifierFlags: shortcut.modifiers,
            propertyList: propertyList,
            attributes: attributes)
    }

    private static func attributes(enabled: Bool, destructive: Bool) -> UIMenuElement.Attributes {
        var attributes: UIMenuElement.Attributes = []

        if !enabled {
            attributes.insert(.disabled)
        }

        if destructive {
            attributes.insert(.destructive)
        }

        return attributes
    }
}
