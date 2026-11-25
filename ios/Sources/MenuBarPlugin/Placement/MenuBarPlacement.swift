import UIKit

/// Decides where each top-level menu of a descriptor lands in a menu build.
struct MenuBarPlacement {
    /// Removes the requested system menus first, so a menu that replaces or sits next to one of
    /// them never targets something about to disappear, and so their shortcuts are free again;
    /// then places each menu in declared order.
    func place(_ descriptor: MenuBarDescriptor, into builder: MenuBarBuilding) {
        descriptor.removeSystemMenus
            .map(MenuBarSystemMenus.identifier(named:))
            .forEach { identifier in builder.remove(menu: identifier) }

        descriptor.menus.forEach { submenu in place(submenu, into: builder) }
    }

    private func place(_ submenu: MenuBarSubmenu, into builder: MenuBarBuilding) {
        guard let target = replaceableSystemMenu(for: submenu, in: builder) else {
            append(submenu, to: builder)

            return
        }

        builder.replace(menu: target, with: factory(for: builder, excluding: target).menu(for: submenu, identifier: target))
        MenuBarLog.debug("Replaced system menu \"\(target.rawValue)\" with \"\(submenu.id)\".")
    }

    /// The system menu named in `replaces`, when the build has it; nil means append instead.
    ///
    /// `UIMenuBuilder.replace` is silent when the target does not exist, which would lose the
    /// menu with no diagnostic. So the target is checked first.
    private func replaceableSystemMenu(for submenu: MenuBarSubmenu, in builder: MenuBarBuilding) -> UIMenu.Identifier? {
        guard let replaces = submenu.replaces else {
            return nil
        }

        let identifier = MenuBarSystemMenus.identifier(named: replaces)

        guard builder.contains(menu: identifier) else {
            MenuBarLog.info("No system menu \"\(replaces)\" to replace; appending \"\(submenu.id)\" instead.")

            return nil
        }

        return identifier
    }

    /// Appends before Help, so Help stays last the way every desktop menu bar is arranged.
    /// Repeated inserts before Help keep the declared order.
    private func append(_ submenu: MenuBarSubmenu, to builder: MenuBarBuilding) {
        let identifier = MenuBarElementFactory.identifier(for: submenu)
        let menu = factory(for: builder, excluding: nil).menu(for: submenu, identifier: identifier)

        MenuBarLog.debug("Appending \"\(submenu.id)\" (\(menu.children.count) items).")

        guard builder.contains(menu: .help) else {
            builder.appendToRoot(menu)

            return
        }

        builder.insert(menu, before: .help)
    }

    /// A factory that knows every command already in the build, minus the menu being replaced.
    private func factory(for builder: MenuBarBuilding, excluding replaced: UIMenu.Identifier?) -> MenuBarElementFactory {
        MenuBarElementFactory(registry: MenuBarCommandRegistry(registering: builder.rootMenu, excluding: replaced))
    }
}
