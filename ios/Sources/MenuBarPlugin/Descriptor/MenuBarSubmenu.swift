import Foundation

/// A titled list of items. At the top level, one entry of the menu bar.
public struct MenuBarSubmenu: Decodable {
    public var id: String
    public var title: String
    public var items: [MenuBarItem]
    /// Name of a system menu to take the place of. Nil appends the submenu instead.
    public var replaces: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case items
        case replaces
    }

    public init(id: String, title: String, items: [MenuBarItem], replaces: String? = nil) {
        self.id = id
        self.title = title
        self.items = items
        self.replaces = replaces
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        replaces = try container.decodeIfPresent(String.self, forKey: .replaces)
        items = try container.decodeTolerantArray(MenuBarItem.self, forKey: .items)
    }
}
