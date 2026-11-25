import UIKit

/// The commands and keyboard shortcuts a menu build already holds, which UIKit refuses to see twice.
///
/// UIKit rejects an entire inserted or replacement menu when one of its commands repeats an
/// existing action and property list, or an existing key combination, and only logs it. The
/// factory claims each command here first, so a clash costs a shortcut (or a repeated item)
/// instead of the whole menu.
final class MenuBarCommandRegistry {
    private struct ShortcutKey: Hashable {
        let input: String
        let modifiers: Int

        init(input: String, modifiers: UIKeyModifierFlags) {
            self.input = input.lowercased()
            self.modifiers = modifiers.rawValue
        }
    }

    private struct CommandKey: Hashable {
        let action: Selector
        let propertyList: String?
    }

    private var shortcutOwners: [ShortcutKey: String] = [:]
    private var commandOwners: [CommandKey: String] = [:]
    private let excluded: UIMenu.Identifier?

    /// Registers every command under `root` except those inside `excluded`: the menu about to be
    /// replaced, whose commands leave the build along with it.
    init(registering root: UIMenu? = nil, excluding excluded: UIMenu.Identifier? = nil) {
        self.excluded = excluded
        root.map(register(_:))
    }

    /// Takes the command's identity for `title`. False when the build already has it, in which
    /// case the caller drops the item.
    func claimCommand(action: Selector, propertyList: String, title: String) -> Bool {
        let key = CommandKey(action: action, propertyList: propertyList)

        guard let owner = commandOwners[key] else {
            commandOwners[key] = title

            return true
        }

        MenuBarLog.error("\"\(title)\" repeats the command of \"\(owner)\"; dropping it so UIKit keeps the rest of the menu.")

        return false
    }

    /// Takes the key combination for `title`. Nil when it is already taken, in which case the
    /// item stays and only loses its shortcut.
    func claimShortcut(_ shortcut: MenuBarShortcut?, title: String) -> MenuBarShortcut? {
        guard let shortcut else {
            return nil
        }

        let key = ShortcutKey(input: shortcut.input, modifiers: shortcut.modifiers)

        guard let owner = shortcutOwners[key] else {
            shortcutOwners[key] = title

            return shortcut
        }

        MenuBarLog.error("The shortcut of \"\(title)\" already belongs to \"\(owner)\"; \"\(title)\" keeps no shortcut.")

        return nil
    }

    private func register(_ element: UIMenuElement) {
        if let menu = element as? UIMenu {
            register(menu: menu)

            return
        }

        guard let command = element as? UICommand else {
            return
        }

        register(command: command)
    }

    private func register(menu: UIMenu) {
        guard menu.identifier != excluded else {
            return
        }

        menu.children.forEach { child in register(child) }
    }

    private func register(command: UICommand) {
        let propertyList = command.propertyList.map { value in String(describing: value) }

        commandOwners[CommandKey(action: command.action, propertyList: propertyList)] = command.title

        guard let keyCommand = command as? UIKeyCommand, let input = keyCommand.input else {
            return
        }

        shortcutOwners[ShortcutKey(input: input, modifiers: keyCommand.modifierFlags)] = command.title
    }
}
