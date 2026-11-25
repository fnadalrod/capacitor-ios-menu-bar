import Foundation

/// An item that reports its `id` back to the app when chosen.
public struct MenuBarAction: Decodable {
    public var id: String
    public var title: String
    /// Nil when absent or unparseable. The item is still shown, without a shortcut.
    public var shortcut: MenuBarShortcut?
    public var enabled: Bool
    public var checked: Bool
    public var destructive: Bool
    /// SF Symbol name. A name the system does not know draws no image.
    public var systemImage: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case shortcut
        case enabled
        case checked
        case destructive
        case systemImage
    }

    public init(
        id: String,
        title: String,
        shortcut: MenuBarShortcut? = nil,
        enabled: Bool = true,
        checked: Bool = false,
        destructive: Bool = false,
        systemImage: String? = nil
    ) {
        self.id = id
        self.title = title
        self.shortcut = shortcut
        self.enabled = enabled
        self.checked = checked
        self.destructive = destructive
        self.systemImage = systemImage
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        shortcut = try container.decodeShortcut(forKey: .shortcut)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        checked = try container.decodeIfPresent(Bool.self, forKey: .checked) ?? false
        destructive = try container.decodeIfPresent(Bool.self, forKey: .destructive) ?? false
        systemImage = try container.decodeIfPresent(String.self, forKey: .systemImage)
    }
}
