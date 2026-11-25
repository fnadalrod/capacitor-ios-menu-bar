import Foundation

/// An item wired to a standard system action instead of a callback.
public struct MenuBarRoleItem: Decodable {
    public var role: MenuBarRole
    /// UIKit does not supply a localized title when the item is built by hand.
    public var title: String
    public var shortcut: MenuBarShortcut?
    public var enabled: Bool

    private enum CodingKeys: String, CodingKey {
        case role
        case title
        case shortcut
        case enabled
    }

    public init(role: MenuBarRole, title: String, shortcut: MenuBarShortcut? = nil, enabled: Bool = true) {
        self.role = role
        self.title = title
        self.shortcut = shortcut
        self.enabled = enabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        role = try container.decode(MenuBarRole.self, forKey: .role)
        title = try container.decode(String.self, forKey: .title)
        shortcut = try container.decodeShortcut(forKey: .shortcut)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
    }
}

/// A standard action UIKit already knows how to route through the responder chain.
///
/// An unknown role fails to decode, and only that item is dropped.
public enum MenuBarRole: String, Decodable, CaseIterable {
    case undo
    case redo
    case cut
    case copy
    case paste
    case delete
    case select
    case selectAll
}
